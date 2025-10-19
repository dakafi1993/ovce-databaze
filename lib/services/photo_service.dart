import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';

/// Servis pro správu fotek ovcí s hybrid funkcionalitou (lokální + server)
class PhotoService {
  static final PhotoService _instance = PhotoService._internal();
  factory PhotoService() => _instance;
  PhotoService._internal();

  final ApiService _apiService = ApiService();
  late Directory _photosDirectory;
  late Directory _thumbnailsDirectory;
  
  /// Inicializace servisu
  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _photosDirectory = Directory('${appDir.path}/ovce_photos');
    _thumbnailsDirectory = Directory('${appDir.path}/ovce_thumbnails');
    
    if (!await _photosDirectory.exists()) {
      await _photosDirectory.create(recursive: true);
    }
    
    if (!await _thumbnailsDirectory.exists()) {
      await _thumbnailsDirectory.create(recursive: true);
    }
    
    print('📸 PhotoService inicializován');
    print('📁 Složka fotek: ${_photosDirectory.path}');
    print('🖼️ Složka thumbnailů: ${_thumbnailsDirectory.path}');
  }

  /// Optimalizuje a uloží fotku lokálně
  Future<String> savePhotoLocally(String originalPath, String usiCislo) async {
    try {
      final originalFile = File(originalPath);
      final bytes = await originalFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Nepodařilo se dekódovat obrázek');
      }

      // Optimalizace velikosti (max 1920x1920, kvalita 85%)
      final resized = img.copyResize(
        image,
        width: image.width > 1920 ? 1920 : null,
        height: image.height > 1920 ? 1920 : null,
      );

      // Uložení optimalizované fotky
      final fileName = '${usiCislo}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final optimizedFile = File('${_photosDirectory.path}/$fileName');
      await optimizedFile.writeAsBytes(img.encodeJpg(resized, quality: 85));

      // Vytvoření thumbnáilu (300x300)
      final thumbnail = img.copyResize(resized, width: 300, height: 300);
      final thumbnailFile = File('${_thumbnailsDirectory.path}/thumb_$fileName');
      await thumbnailFile.writeAsBytes(img.encodeJpg(thumbnail, quality: 70));

      print('📸 Fotka optimalizována a uložena: $fileName');
      return optimizedFile.path;
    } catch (e) {
      print('❌ Chyba při optimalizaci fotky: $e');
      rethrow;
    }
  }

  /// Nahraje fotku na server s fallback na lokální uložení
  Future<String> uploadPhoto(String photoPath, String usiCislo, {bool isOnline = true}) async {
    // Nejdříve optimalizujeme a uložíme lokálně
    final localPath = await savePhotoLocally(photoPath, usiCislo);
    
    if (isOnline) {
      try {
        // Pokusíme se nahrát na server
        final serverUrl = await _apiService.uploadPhoto(localPath, usiCislo);
        
        // Zaznamenáme mapování mezi lokální cestou a server URL
        await _savePhotoMapping(localPath, serverUrl);
        
        print('✅ Fotka nahrána na server: $serverUrl');
        return serverUrl;
      } catch (e) {
        print('❌ Chyba při nahrávání na server, zůstává lokálně: $e');
        
        // Označíme pro pozdější upload
        await _markForUpload(localPath, usiCislo);
        return localPath;
      }
    } else {
      // Offline režim - označíme pro pozdější upload
      await _markForUpload(localPath, usiCislo);
      print('📱 Offline - fotka bude nahrána později');
      return localPath;
    }
  }

  /// Označí fotku pro pozdější upload
  Future<void> _markForUpload(String localPath, String usiCislo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingUploads = prefs.getStringList('pending_photo_uploads') ?? [];
      
      final uploadData = json.encode({
        'local_path': localPath,
        'usi_cislo': usiCislo,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      if (!pendingUploads.contains(uploadData)) {
        pendingUploads.add(uploadData);
        await prefs.setStringList('pending_photo_uploads', pendingUploads);
      }
      
      print('⏳ Fotka označena pro upload: $localPath');
    } catch (e) {
      print('❌ Chyba při označení fotky pro upload: $e');
    }
  }

  /// Uloží mapování mezi lokální cestou a server URL
  Future<void> _savePhotoMapping(String localPath, String serverUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mappings = prefs.getStringList('photo_mappings') ?? [];
      
      final mapping = json.encode({
        'local_path': localPath,
        'server_url': serverUrl,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      mappings.add(mapping);
      await prefs.setStringList('photo_mappings', mappings);
    } catch (e) {
      print('❌ Chyba při ukládání photo mappingu: $e');
    }
  }

  /// Provede odložené uploady fotek
  Future<void> performPendingUploads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingUploads = prefs.getStringList('pending_photo_uploads') ?? [];
      
      if (pendingUploads.isEmpty) return;
      
      print('📤 Nahrávám ${pendingUploads.length} odložených fotek...');
      
      final completedUploads = <String>[];
      
      for (final uploadJson in pendingUploads) {
        try {
          final upload = json.decode(uploadJson);
          final localPath = upload['local_path'];
          final usiCislo = upload['usi_cislo'];
          
          if (await File(localPath).exists()) {
            final serverUrl = await _apiService.uploadPhoto(localPath, usiCislo);
            await _savePhotoMapping(localPath, serverUrl);
            completedUploads.add(uploadJson);
            print('✅ Fotka nahrána: $localPath -> $serverUrl');
          } else {
            print('⚠️ Lokální fotka už neexistuje: $localPath');
            completedUploads.add(uploadJson); // Odstraníme z fronty
          }
        } catch (e) {
          print('❌ Chyba při nahrávání fotky: $e');
          // Necháváme v frontě pro další pokus
        }
      }
      
      // Odebereme dokončené uploady
      pendingUploads.removeWhere((upload) => completedUploads.contains(upload));
      await prefs.setStringList('pending_photo_uploads', pendingUploads);
      
      print('✅ Dokončeno nahrávání ${completedUploads.length} fotek');
    } catch (e) {
      print('❌ Chyba při odložených uploadech: $e');
    }
  }

  /// Získá thumbnail cestu pro fotku
  String getThumbnailPath(String photoPath) {
    final fileName = photoPath.split('/').last;
    return '${_thumbnailsDirectory.path}/thumb_$fileName';
  }

  /// Kontroluje jestli thumbnail existuje
  Future<bool> thumbnailExists(String photoPath) async {
    final thumbnailPath = getThumbnailPath(photoPath);
    return await File(thumbnailPath).exists();
  }

  /// Vytvoří thumbnail pokud neexistuje
  Future<String> ensureThumbnail(String photoPath) async {
    final thumbnailPath = getThumbnailPath(photoPath);
    
    if (await File(thumbnailPath).exists()) {
      return thumbnailPath;
    }
    
    try {
      final file = File(photoPath);
      if (!await file.exists()) {
        throw Exception('Původní fotka neexistuje');
      }
      
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Nepodařilo se dekódovat obrázek');
      }
      
      final thumbnail = img.copyResize(image, width: 300, height: 300);
      await File(thumbnailPath).writeAsBytes(img.encodeJpg(thumbnail, quality: 70));
      
      return thumbnailPath;
    } catch (e) {
      print('❌ Chyba při vytváření thumbnáilu: $e');
      return photoPath; // Fallback na původní fotku
    }
  }

  /// Smaže lokální fotku
  Future<void> deleteLocalPhoto(String photoPath) async {
    try {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
      }
      
      final thumbnailPath = getThumbnailPath(photoPath);
      final thumbnailFile = File(thumbnailPath);
      if (await thumbnailFile.exists()) {
        await thumbnailFile.delete();
      }
      
      print('🗑️ Lokální fotka smazána: $photoPath');
    } catch (e) {
      print('❌ Chyba při mazání lokální fotky: $e');
    }
  }

  /// Vyčistí staré cache fotky (starší než 30 dní)
  Future<void> cleanOldCache() async {
    try {
      final now = DateTime.now();
      final photos = await _photosDirectory.list().toList();
      final thumbnails = await _thumbnailsDirectory.list().toList();
      
      int deletedCount = 0;
      
      for (final entity in [...photos, ...thumbnails]) {
        if (entity is File) {
          final stat = await entity.stat();
          final age = now.difference(stat.modified).inDays;
          
          if (age > 30) {
            await entity.delete();
            deletedCount++;
          }
        }
      }
      
      if (deletedCount > 0) {
        print('🧹 Vyčištěno $deletedCount starých fotek z cache');
      }
    } catch (e) {
      print('❌ Chyba při čištění cache: $e');
    }
  }

  /// Získá celkovou velikost cache
  Future<int> getCacheSize() async {
    int totalSize = 0;
    
    try {
      final photos = await _photosDirectory.list(recursive: true).toList();
      for (final entity in photos) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
    } catch (e) {
      print('❌ Chyba při výpočtu velikosti cache: $e');
    }
    
    return totalSize;
  }

  /// Formátuje velikost v human-readable formátu
  String formatCacheSize(int bytes) {
    if (bytes < 1024) return '${bytes} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}