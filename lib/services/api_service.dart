import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import '../models/ovce.dart';

/// Konfigurace API endpoints
class ApiConfig {
  // Při vývoji používáme localhost, později změníme na Railway URL
  static const String baseUrl = 'http://localhost:3000/api';
  
  // Railway produkční URL 
  static const String railwayUrl = 'https://ovce-databaze-production.up.railway.app/api';
  
  // Rozhodne jestli používáme lokální nebo produkční API
  static bool get useProduction => true; // Nyní používáme Railway!
  
  static String get apiUrl => useProduction ? railwayUrl : baseUrl;
}

/// Servis pro komunikaci s REST API
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  
  /// Inicializace API service
  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.apiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Přidáme interceptor pro logování
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('🌐 API: $obj'),
    ));
    
    print('✅ ApiService inicializován: ${ApiConfig.apiUrl}');
  }

  /// Získá všechny ovce ze serveru
  Future<List<Ovce>> getAllOvce() async {
    try {
      print('📡 Získávám všechny ovce ze serveru...');
      final response = await _dio.get('/ovce');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        final ovce = data.map((json) => Ovce.fromApiJson(json)).toList();
        print('✅ Načteno ${ovce.length} ovcí ze serveru');
        return ovce;
      } else {
        throw Exception('Chyba při načítání ovcí: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Chyba při načítání ovcí: $e');
      rethrow;
    }
  }

  /// Přidá novou ovci na server
  Future<Ovce> createOvce(Ovce ovce) async {
    try {
      print('📡 Přidávám ovci na server: ${ovce.usiCislo}');
      
      final data = ovce.toApiJson();
      final response = await _dio.post('/ovce', data: data);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final createdOvce = Ovce.fromApiJson(response.data['data'] ?? response.data);
        print('✅ Ovce úspěšně přidána na server');
        return createdOvce;
      } else {
        throw Exception('Chyba při vytváření ovce: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Chyba při vytváření ovce: $e');
      rethrow;
    }
  }

  /// Aktualizuje ovci na serveru
  Future<Ovce> updateOvce(Ovce ovce) async {
    try {
      print('📡 Aktualizuji ovci na serveru: ${ovce.usiCislo}');
      
      final data = ovce.toApiJson();
      final response = await _dio.put('/ovce/${ovce.id}', data: data);
      
      if (response.statusCode == 200) {
        final updatedOvce = Ovce.fromApiJson(response.data['data'] ?? response.data);
        print('✅ Ovce úspěšně aktualizována na serveru');
        return updatedOvce;
      } else {
        throw Exception('Chyba při aktualizaci ovce: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Chyba při aktualizaci ovce: $e');
      rethrow;
    }
  }

  /// Smaže ovci ze serveru
  Future<void> deleteOvce(String ovceId) async {
    try {
      print('📡 Mažu ovci ze serveru: $ovceId');
      
      final response = await _dio.delete('/ovce/$ovceId');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Ovce úspěšně smazána ze serveru');
      } else {
        throw Exception('Chyba při mazání ovce: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Chyba při mazání ovce: $e');
      rethrow;
    }
  }

  /// Nahraje fotku ovce na server
  Future<String> uploadPhoto(String photoPath, String usiCislo) async {
    try {
      print('📡 Nahrávám fotku pro ovci: $usiCislo');
      
      final fileName = '${usiCislo}_${DateTime.now().millisecondsSinceEpoch}${path.extension(photoPath)}';
      
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          photoPath,
          filename: fileName,
        ),
        'usi_cislo': usiCislo,
      });
      
      final response = await _dio.post('/upload-photo', data: formData);
      
      if (response.statusCode == 200) {
        final photoUrl = response.data['photo_url'] ?? response.data['url'];
        print('✅ Fotka úspěšně nahrána: $photoUrl');
        return photoUrl;
      } else {
        throw Exception('Chyba při nahrávání fotky: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Chyba při nahrávání fotky: $e');
      rethrow;
    }
  }

  /// Nahraje více fotek najednou
  Future<List<String>> uploadMultiplePhotos(List<String> photoPaths, String usiCislo) async {
    final uploadedUrls = <String>[];
    
    for (final photoPath in photoPaths) {
      try {
        final url = await uploadPhoto(photoPath, usiCislo);
        uploadedUrls.add(url);
      } catch (e) {
        print('❌ Chyba při nahrávání fotky $photoPath: $e');
        // Pokračujeme s dalšími fotkami
      }
    }
    
    return uploadedUrls;
  }

  /// Smaže fotku ze serveru
  Future<void> deletePhoto(String photoUrl) async {
    try {
      print('📡 Mažu fotku ze serveru: $photoUrl');
      
      final response = await _dio.delete('/delete-photo', data: {
        'photo_url': photoUrl,
      });
      
      if (response.statusCode == 200) {
        print('✅ Fotka úspěšně smazána ze serveru');
      } else {
        throw Exception('Chyba při mazání fotky: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Chyba při mazání fotky: $e');
      rethrow;
    }
  }

  /// Získá informace o stavu serveru
  Future<Map<String, dynamic>> getServerStatus() async {
    try {
      final response = await _dio.get('/status');
      return response.data;
    } catch (e) {
      print('❌ Server není dostupný: $e');
      return {'status': 'offline', 'error': e.toString()};
    }
  }

  /// Synchronizuje lokální data se serverem
  Future<void> syncWithServer(List<Ovce> localOvce) async {
    try {
      print('🔄 Synchronizuji data se serverem...');
      
      // Získáme aktuální data ze serveru
      final serverOvce = await getAllOvce();
      final serverUsiCisla = serverOvce.map((o) => o.usiCislo).toSet();
      
      // Nahrajeme lokální ovce, které nejsou na serveru
      for (final localOvce in localOvce) {
        if (!serverUsiCisla.contains(localOvce.usiCislo)) {
          await createOvce(localOvce);
        }
      }
      
      print('✅ Synchronizace dokončena');
    } catch (e) {
      print('❌ Chyba při synchronizaci: $e');
      rethrow;
    }
  }

  /// Kontrola internetového připojení
  Future<bool> hasInternetConnection() async {
    try {
      print('🔍 Testuji připojení k: ${ApiConfig.apiUrl}/status');
      final response = await _dio.get('/status');
      print('✅ API odpovědělo: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Chyba připojení k API: $e');
      return false;
    }
  }
}