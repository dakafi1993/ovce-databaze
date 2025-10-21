import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ovce.dart';
import 'api_service.dart';
import 'photo_service.dart';

/// Hybridní servis pro práci s ovcemi - využívá API když je dostupné, jinak lokální úložiště
class OvceService {
  static final OvceService _instance = OvceService._internal();
  factory OvceService() => _instance;
  OvceService._internal();

  final ApiService _apiService = ApiService();
  final PhotoService _photoService = PhotoService();
  bool _isOnline = false;
  List<Ovce> _cachedOvce = [];
  
  /// Inicializace servisu
  Future<void> initialize() async {
    _apiService.initialize();
    await _photoService.initialize();
    await _checkConnection();
    await _loadCachedData();
    
    if (_isOnline) {
      await _syncWithServer();
      await _photoService.performPendingUploads();
    }
  }

  /// Kontrola internetového připojení
  Future<void> _checkConnection() async {
    try {
      _isOnline = await _apiService.hasInternetConnection();
      print(_isOnline ? '🌐 Online režim - používáme server' : '📱 Offline režim - používáme lokální data');
    } catch (e) {
      _isOnline = false;
      print('📱 Offline režim - server nedostupný');
    }
  }

  /// Načte cachovaná data z lokálního úložiště
  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ovceDatJson = prefs.getString('ovce_data_cache');
      
      if (ovceDatJson != null) {
        final List<dynamic> decoded = json.decode(ovceDatJson);
        _cachedOvce = decoded.map((item) => Ovce.fromApiJson(item)).toList();
        print('📦 Načteno ${_cachedOvce.length} cachovaných ovcí');
      }
    } catch (e) {
      print('❌ Chyba při načítání cache: $e');
      _cachedOvce = [];
    }
  }

  /// Uloží data do lokální cache
  Future<void> _saveCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = json.encode(_cachedOvce.map((ovce) => ovce.toApiJson()).toList());
      await prefs.setString('ovce_data_cache', jsonData);
      print('💾 Cache uložena (${_cachedOvce.length} ovcí)');
    } catch (e) {
      print('❌ Chyba při ukládání cache: $e');
    }
  }

  /// Synchronizace s serverem
  Future<void> _syncWithServer() async {
    if (!_isOnline) return;
    
    try {
      print('🔄 Synchronizuji data se serverem...');
      
      // Získáme aktuální data ze serveru
      final serverOvce = await _apiService.getAllOvce();
      
      // Aktualizujeme cache
      _cachedOvce = serverOvce;
      await _saveCachedData();
      
      print('✅ Synchronizace dokončena');
    } catch (e) {
      print('❌ Chyba při synchronizaci: $e');
      // Zůstáváme s cached daty
    }
  }

  /// Získá všechny ovce
  Future<List<Ovce>> getAllOvce() async {
    print('🐑 OVCE SERVICE - getAllOvce() started');
    await _checkConnection();
    
    print('🌐 Connection status: ${_isOnline ? "ONLINE" : "OFFLINE"}');
    print('📦 Current cache size: ${_cachedOvce.length}');
    
    if (_isOnline) {
      try {
        print('📡 Fetching from server...');
        final serverOvce = await _apiService.getAllOvce();
        print('✅ Server returned ${serverOvce.length} sheep');
        
        _cachedOvce = serverOvce;
        await _saveCachedData();
        
        print('💾 Data cached successfully');
        return serverOvce;
      } catch (e) {
        print('❌ Chyba při načítání ze serveru, používám cache: $e');
        print('📦 Returning ${_cachedOvce.length} cached sheep');
        return _cachedOvce;
      }
    } else {
      print('📱 Offline mode - returning ${_cachedOvce.length} cached sheep');
      return _cachedOvce;
    }
  }

  /// Přidá novou ovci
  Future<void> addOvce(Ovce ovce) async {
    await _checkConnection();
    
    if (_isOnline) {
      try {
        final createdOvce = await _apiService.createOvce(ovce);
        _cachedOvce.add(createdOvce);
        await _saveCachedData();
        print('✅ Ovce přidána na server a do cache');
        return;
      } catch (e) {
        print('❌ Chyba při přidávání na server, ukládám lokálně: $e');
        // Pokračujeme s lokálním uložením
      }
    }
    
    // Lokální uložení (offline nebo při chybě serveru)
    final localOvce = Ovce(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Dočasné ID
      usiCislo: ovce.usiCislo,
      datumNarozeni: ovce.datumNarozeni,
      matka: ovce.matka,
      otec: ovce.otec,
      plemeno: ovce.plemeno,
      kategorie: ovce.kategorie,
      cisloMatky: ovce.cisloMatky,
      pohlavi: ovce.pohlavi,
      poznamka: ovce.poznamka,
      fotky: ovce.fotky,
      datumRegistrace: ovce.datumRegistrace,
      biometrics: ovce.biometrics,
      referencePhotos: ovce.referencePhotos,
      recognitionHistory: ovce.recognitionHistory,
      recognitionAccuracy: ovce.recognitionAccuracy,
      isTrainedForRecognition: ovce.isTrainedForRecognition,
    );
    
    _cachedOvce.add(localOvce);
    await _saveCachedData();
    await _markForSync(localOvce, 'create');
    print('📱 Ovce uložena lokálně, bude synchronizována při příštím připojení');
  }

  /// Aktualizuje ovci
  Future<void> updateOvce(Ovce ovce) async {
    await _checkConnection();
    
    if (_isOnline && ovce.id != null) {
      try {
        final updatedOvce = await _apiService.updateOvce(ovce);
        final index = _cachedOvce.indexWhere((o) => o.id == ovce.id);
        if (index != -1) {
          _cachedOvce[index] = updatedOvce;
          await _saveCachedData();
          print('✅ Ovce aktualizována na serveru a v cache');
          return;
        }
      } catch (e) {
        print('❌ Chyba při aktualizaci na serveru, ukládám lokálně: $e');
      }
    }
    
    // Lokální aktualizace
    final index = _cachedOvce.indexWhere((o) => o.usiCislo == ovce.usiCislo);
    if (index != -1) {
      _cachedOvce[index] = ovce;
      await _saveCachedData();
      await _markForSync(ovce, 'update');
      print('📱 Ovce aktualizována lokálně, bude synchronizována při příštím připojení');
    }
  }

  /// Smaže ovci
  Future<void> deleteOvce(String usiCislo) async {
    await _checkConnection();
    
    final ovce = _cachedOvce.firstWhere((o) => o.usiCislo == usiCislo);
    
    if (_isOnline && ovce.id != null) {
      try {
        await _apiService.deleteOvce(ovce.id!);
        _cachedOvce.removeWhere((o) => o.usiCislo == usiCislo);
        await _saveCachedData();
        print('✅ Ovce smazána ze serveru a z cache');
        return;
      } catch (e) {
        print('❌ Chyba při mazání na serveru: $e');
      }
    }
    
    // Lokální smazání
    _cachedOvce.removeWhere((o) => o.usiCislo == usiCislo);
    await _saveCachedData();
    await _markForSync(ovce, 'delete');
    print('📱 Ovce smazána lokálně, bude synchronizována při příštím připojení');
  }

  /// Označí operaci pro pozdější synchronizaci
  Future<void> _markForSync(Ovce ovce, String operation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingOperations = prefs.getStringList('pending_sync_operations') ?? [];
      
      final operationData = json.encode({
        'operation': operation,
        'ovce': ovce.toApiJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      pendingOperations.add(operationData);
      await prefs.setStringList('pending_sync_operations', pendingOperations);
      print('⏳ Operace $operation označena pro synchronizaci');
    } catch (e) {
      print('❌ Chyba při označení pro synchronizaci: $e');
    }
  }

  /// Provede odloženou synchronizaci
  Future<void> performPendingSync() async {
    if (!_isOnline) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingOperations = prefs.getStringList('pending_sync_operations') ?? [];
      
      if (pendingOperations.isEmpty) return;
      
      print('🔄 Provádím odloženou synchronizaci (${pendingOperations.length} operací)...');
      
      for (final operationJson in pendingOperations) {
        try {
          final operation = json.decode(operationJson);
          final ovce = Ovce.fromApiJson(operation['ovce']);
          
          switch (operation['operation']) {
            case 'create':
              await _apiService.createOvce(ovce);
              break;
            case 'update':
              if (ovce.id != null) {
                await _apiService.updateOvce(ovce);
              }
              break;
            case 'delete':
              if (ovce.id != null) {
                await _apiService.deleteOvce(ovce.id!);
              }
              break;
          }
        } catch (e) {
          print('❌ Chyba při synchronizaci operace: $e');
        }
      }
      
      // Vyčistíme odložené operace
      await prefs.remove('pending_sync_operations');
      
      // Znovu načteme data ze serveru
      await _syncWithServer();
      
      print('✅ Odložená synchronizace dokončena');
    } catch (e) {
      print('❌ Chyba při odložené synchronizaci: $e');
    }
  }

  /// Nahraje fotku ovce
  Future<String?> uploadPhoto(String photoPath, String usiCislo) async {
    await _checkConnection();
    
    try {
      final photoUrl = await _photoService.uploadPhoto(photoPath, usiCislo, isOnline: _isOnline);
      print('✅ Fotka zpracována: $photoUrl');
      return photoUrl;
    } catch (e) {
      print('❌ Chyba při zpracování fotky: $e');
      return null;
    }
  }

  /// Nahraje více fotek najednou
  Future<List<String>> uploadMultiplePhotos(List<String> photoPaths, String usiCislo) async {
    final uploadedUrls = <String>[];
    
    for (final photoPath in photoPaths) {
      final url = await uploadPhoto(photoPath, usiCislo);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }
    
    return uploadedUrls;
  }

  /// Získá optimalizovanou cestu k fotce (thumbnail pokud existuje)
  Future<String> getOptimizedPhotoPath(String originalPath) async {
    if (await _photoService.thumbnailExists(originalPath)) {
      return _photoService.getThumbnailPath(originalPath);
    }
    return originalPath;
  }

  /// Vyčistí staré cache fotky
  Future<void> cleanPhotoCache() async {
    await _photoService.cleanOldCache();
  }

  /// Získá informace o cache fotek
  Future<Map<String, String>> getPhotoCacheInfo() async {
    final cacheSize = await _photoService.getCacheSize();
    return {
      'size': _photoService.formatCacheSize(cacheSize),
      'size_bytes': cacheSize.toString(),
    };
  }

  /// Získá stav připojení
  bool get isOnline => _isOnline;
  
  /// Získá počet cachovaných ovcí
  int get cachedCount => _cachedOvce.length;
}