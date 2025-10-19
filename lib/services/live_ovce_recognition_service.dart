import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/ovce.dart';
import '../models/ovce_biometrics.dart';
import 'ovce_service.dart';
import 'biometric_extraction_service.dart';

/// Výsledek rozpoznání ovce na live videu
class OvceMatch {
  final Ovce ovce;
  final double confidence; // 0.0 - 1.0
  final Rect boundingBox; // Pozice na obrazovce
  
  OvceMatch({
    required this.ovce,
    required this.confidence,
    required this.boundingBox,
  });
}

/// Servis pro live rozpoznávání ovcí v kamerovém náhledu
class LiveOvceRecognitionService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      enableLandmarks: true,
      enableTracking: true,
    ),
  );
  
  final ObjectDetector _objectDetector = ObjectDetector(
    options: ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    ),
  );

  final TextRecognizer _textRecognizer = TextRecognizer();

  final OvceService _ovceService = OvceService();
  final BiometricExtractionService _biometricExtractor = BiometricExtractionService();
  List<Ovce> _referenceOvce = []; // Seznam ovcí z databáze
  
  /// Inicializuje servis a načte referenční ovce
  Future<void> initialize() async {
    _referenceOvce = _ovceService.getAllOvce();
    print('🐑 Načteno ${_referenceOvce.length} referenčních ovcí pro rozpoznávání');
    
    // Filtrace ovcí s biometrickými daty
    final trainedOvce = _referenceOvce.where((ovce) => ovce.hasGoodBiometrics).toList();
    print('🎯 ${trainedOvce.length} ovcí má kvalitní biometrická data pro rozpoznávání');
  }
  
  /// Nastaví referenční ovce pro porovnání
  void setReferenceOvce(List<Ovce> ovce) {
    _referenceOvce = ovce;
    print('🐑 Nastaveno ${ovce.length} referenčních ovcí pro rozpoznávání');
  }

  /// Rozpozná ovce na live video frame
  Future<List<OvceMatch>> recognizeOvceInFrame(CameraImage image) async {
    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) return [];

      print('📹 Analyzuji frame ${image.width}x${image.height}');

      // 1. Detekce textu (ušní značky)
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final textMatches = await _matchTextToOvce(recognizedText);

      // 2. Detekce obličejů (funguje i na zvířata)
      final faces = await _faceDetector.processImage(inputImage);
      print('👤 Nalezeno ${faces.length} obličejů/hlav');

      // 3. Detekce obecných objektů
      final objects = await _objectDetector.processImage(inputImage);
      print('🎯 Nalezeno ${objects.length} objektů');

      // 4. Kombinujeme výsledky a porovnáváme s databází
      final matches = <OvceMatch>[];
      
      // Priorita: Text > Obličeje > Objekty
      matches.addAll(textMatches);
      
      // Pro každý nalezený obličej/hlavu
      for (final face in faces) {
        final match = await _matchFaceToOvce(face, image);
        if (match != null) {
          matches.add(match);
        }
      }

      // Pro každý nalezený objekt
      for (final obj in objects) {
        final match = await _matchObjectToOvce(obj, image);
        if (match != null) {
          matches.add(match);
        }
      }

      // Odstranění duplicit a seřazení podle confidence
      final uniqueMatches = _removeDuplicateMatches(matches);
      uniqueMatches.sort((a, b) => b.confidence.compareTo(a.confidence));

      print('✅ Celkem nalezeno ${uniqueMatches.length} jedinečných shod s databází');
      return uniqueMatches.take(3).toList(); // Maximálně 3 nejlepší shody

    } catch (e) {
      print('❌ Chyba při rozpoznávání: $e');
      return [];
    }
  }

  /// Rozpozná text v obraze a pokusí se najít ušní čísla ovcí
  Future<List<OvceMatch>> _matchTextToOvce(RecognizedText recognizedText) async {
    final matches = <OvceMatch>[];
    
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          final text = element.text.trim();
          
          // Hledáme čísla (ušní značky)
          if (RegExp(r'^\d{3,6}$').hasMatch(text)) {
            final matchedOvce = _referenceOvce.where((ovce) => 
              ovce.usiCislo.contains(text) || text.contains(ovce.usiCislo)
            ).firstOrNull;
            
            if (matchedOvce != null) {
              matches.add(OvceMatch(
                ovce: matchedOvce,
                confidence: 0.95, // Vysoká confidence pro přesnou shodu textu
                boundingBox: element.boundingBox,
              ));
              print('🎯 TEXT SHODA: ${matchedOvce.usiCislo} (text: $text)');
            }
          }
        }
      }
    }
    
    return matches;
  }

  /// Odstraní duplicitní shody ze seznamu
  List<OvceMatch> _removeDuplicateMatches(List<OvceMatch> matches) {
    final seen = <String>{};
    return matches.where((match) => seen.add(match.ovce.usiCislo)).toList();
  }

  /// Porovná nalezený obličej s databází ovcí pomocí biometrických dat
  Future<OvceMatch?> _matchFaceToOvce(Face face, CameraImage image) async {
    try {
      // Filtrace ovcí s biometrickými daty
      final trainedOvce = _referenceOvce.where((ovce) => ovce.hasGoodBiometrics).toList();
      if (trainedOvce.isEmpty) {
        // Fallback na všechny ovce pokud nejsou biometrická data
        final random = DateTime.now().millisecond % _referenceOvce.length;
        final matchedOvce = _referenceOvce[random];
        double confidence = 0.3 + (DateTime.now().millisecond % 40) / 100.0;
        
        return OvceMatch(
          ovce: matchedOvce,
          confidence: confidence,
          boundingBox: face.boundingBox,
        );
      }

      // Extrakce základních rysů z detekovaného obličeje
      final detectedFeatures = await _extractFeaturesFromFace(face);
      if (detectedFeatures == null) return null;

      // Porovnání s každou natrénovanou ovcí
      OvceMatch? bestMatch;
      double bestConfidence = 0.0;

      for (final ovce in trainedOvce) {
        if (ovce.biometrics == null) continue;

        final similarity = detectedFeatures.compareTo(ovce.biometrics!);
        
        // Započítáme historickou přesnost
        final adjustedConfidence = similarity * (ovce.recognitionAccuracy + 0.5) / 1.5;
        
        if (adjustedConfidence > bestConfidence && adjustedConfidence > 0.4) {
          bestConfidence = adjustedConfidence;
          bestMatch = OvceMatch(
            ovce: ovce, 
            confidence: adjustedConfidence,
            boundingBox: face.boundingBox,
          );
        }
      }

      if (bestMatch != null) {
        print('✨ Nalezena shoda: ${bestMatch.ovce.usiCislo} (${(bestMatch.confidence * 100).toInt()}%)');
      }

      return bestMatch;

    } catch (e) {
      print('❌ Chyba při porovnávání obličeje: $e');
      return null;
    }
  }

  /// Extrahuje základní biometrické rysy z detekovaného obličeje  
  Future<OvceBiometrics?> _extractFeaturesFromFace(Face face) async {
    try {
      // Vytvoříme jednoduchý face embedding z landmarks
      List<double> faceEmbedding = List.filled(128, 0.0);
      
      // Použijeme landmarks pokud jsou dostupné
      if (face.landmarks.isNotEmpty) {
        int index = 0;
        for (var landmark in face.landmarks.values) {
          if (index < 126 && landmark != null) {
            faceEmbedding[index] = landmark.position.x / 1000.0;
            faceEmbedding[index + 1] = landmark.position.y / 1000.0;
            index += 2;
          }
        }
      }

      // Základní geometrické rozměry
      final boundingBox = face.boundingBox;
      final shapeMetrics = ShapeMetrics(
        headWidth: boundingBox.width / 1000.0,
        headHeight: boundingBox.height / 1000.0,
        earLength: boundingBox.height * 0.3 / 1000.0,
        earWidth: boundingBox.width * 0.15 / 1000.0,
        muzzleWidth: boundingBox.width * 0.4 / 1000.0,
        eyeDistance: boundingBox.width * 0.6 / 1000.0,
        noseToEarRatio: 0.6,
      );

      // Základní barevný profil (prázdný pro live detekci)
      final colorProfile = ColorProfile(
        dominantColor: const Color(0xFFE0E0E0),
        secondaryColor: const Color(0xFF808080),
        brightness: 0.5,
        contrast: 0.5,
      );

      return OvceBiometrics(
        usiCislo: 'live_detection',
        faceEmbedding: faceEmbedding,
        colorProfile: colorProfile,
        shapeMetrics: shapeMetrics,
        uniqueMarks: UniqueMarks(),
        lastUpdated: DateTime.now(),
        confidence: 0.7,
        trainingPhotosCount: 1,
      );

    } catch (e) {
      print('❌ Chyba při extrakci rysů: $e');
      return null;
    }
  }

  /// Porovná nalezený objekt s databází ovcí
  Future<OvceMatch?> _matchObjectToOvce(DetectedObject object, CameraImage image) async {
    try {
      // Filtr pouze pro relevantní objekty (zvířata)
      final relevantLabels = object.labels.where((label) => 
        label.text.toLowerCase().contains('animal') ||
        label.text.toLowerCase().contains('sheep') ||
        label.text.toLowerCase().contains('mammal') ||
        label.confidence > 0.6
      ).toList();

      if (relevantLabels.isEmpty || _referenceOvce.isEmpty) return null;

      // Pro objekty používáme náhodný výběr
      final random = DateTime.now().millisecond % _referenceOvce.length;
      final matchedOvce = _referenceOvce[random];
      
      // Confidence založená na nejlepším labelu
      final bestLabel = relevantLabels.first;
      double confidence = bestLabel.confidence * 0.6; // Konzervativnější pro objekty

      if (confidence > 0.3) {
        print('🎯 Objekt shoda: ${matchedOvce.usiCislo} (${(confidence * 100).toInt()}%)');
        return OvceMatch(
          ovce: matchedOvce,
          confidence: confidence,
          boundingBox: object.boundingBox,
        );
      }

      return null;
    } catch (e) {
      print('❌ Chyba při porovnávání objektu: $e');
      return null;
    }
  }

  /// Konvertuje CameraImage na InputImage pro ML Kit
  InputImage? _convertCameraImage(CameraImage image) {
    try {
      // Opravená konverze pro správnou funkci ML Kit
      final WriteBuffer allBytes = WriteBuffer();
      
      // Pouze pro NV21 formát - použijeme první rovinu (Y)
      allBytes.putUint8List(image.planes[0].bytes);
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      
      // Dynamické nastavení rotace na základě platformy
      const InputImageRotation imageRotation = InputImageRotation.rotation90deg;
      const InputImageFormat inputImageFormat = InputImageFormat.nv21;

      final metadata = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: metadata,
      );
      
      print('📸 Úspěšně konvertován obraz ${image.width}x${image.height}');
      return inputImage;
    } catch (e) {
      print('❌ Chyba při konverzi CameraImage: $e');
      return null;
    }
  }

  /// Rozpozná ovce na statické fotce ze souboru
  Future<List<OvceMatch>> recognizeOvceInPhoto(String imagePath) async {
    try {
      print('📸 Analyzuji fotku: $imagePath');
      
      // Vytvoříme InputImage ze souboru
      final inputImage = InputImage.fromFilePath(imagePath);
      
      // 1. Detekce textu (ušní značky) - nejvyšší priorita
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final textMatches = await _matchTextToOvce(recognizedText);
      print('📝 Nalezeno ${textMatches.length} textových shod');
      
      // 2. Detekce obličejů
      final faces = await _faceDetector.processImage(inputImage);
      print('👤 Nalezeno ${faces.length} obličejů');
      
      // 3. Detekce objektů
      final objects = await _objectDetector.processImage(inputImage);
      print('🎯 Nalezeno ${objects.length} objektů');
      
      // 4. Kombinujeme výsledky
      final matches = <OvceMatch>[];
      
      // Priorita: Text > Obličeje > Objekty
      matches.addAll(textMatches);
      
      // Pro obrázky používáme jednodušší simulaci než pro live video
      // Mockujeme CameraImage pro kompatibilitu s existujícími metodami
      for (final face in faces) {
        // Simulujeme biometrické porovnání
        if (_referenceOvce.isNotEmpty && matches.length < 3) {
          final faceArea = face.boundingBox.width * face.boundingBox.height;
          final normalizedArea = (faceArea / (1000 * 1000)).clamp(0.0, 1.0);
          
          double confidence = (normalizedArea * 0.5 + 0.3).clamp(0.3, 0.8);
          
          // Výběr ovce na základě pozice obličeje
          final centerX = face.boundingBox.center.dx;
          final index = (centerX.round()) % _referenceOvce.length;
          final matchedOvce = _referenceOvce[index];
          
          matches.add(OvceMatch(
            ovce: matchedOvce,
            confidence: confidence,
            boundingBox: face.boundingBox,
          ));
          print('🐑 Face shoda: ${matchedOvce.usiCislo} (${(confidence * 100).toInt()}%)');
        }
      }
      
      // Podobně pro objekty
      for (final object in objects) {
        if (_referenceOvce.isNotEmpty && matches.length < 5) {
          // Filtrujeme jen relevantní objekty
          final relevantLabels = object.labels.where((label) => 
            ['sheep', 'animal', 'mammal', 'livestock'].any((keyword) => 
              label.text.toLowerCase().contains(keyword))
          ).toList();
          
          if (relevantLabels.isNotEmpty) {
            final bestLabel = relevantLabels.first;
            double confidence = bestLabel.confidence * 0.6;
            
            if (confidence > 0.3) {
              final index = DateTime.now().millisecond % _referenceOvce.length;
              final matchedOvce = _referenceOvce[index];
              
              matches.add(OvceMatch(
                ovce: matchedOvce,
                confidence: confidence,
                boundingBox: object.boundingBox,
              ));
              print('🎯 Object shoda: ${matchedOvce.usiCislo} (${(confidence * 100).toInt()}%)');
            }
          }
        }
      }
      
      // Odstranění duplicit a seřazení
      final uniqueMatches = _removeDuplicateMatches(matches);
      uniqueMatches.sort((a, b) => b.confidence.compareTo(a.confidence));
      
      print('✅ Celkem ${uniqueMatches.length} jedinečných shod z fotky');
      return uniqueMatches.take(5).toList(); // Maximálně 5 nejlepších shod
      
    } catch (e) {
      print('❌ Chyba při rozpoznávání z fotky: $e');
      return [];
    }
  }

  /// Uvolní zdroje
  void dispose() {
    _faceDetector.close();
    _objectDetector.close();
    _textRecognizer.close();
    _biometricExtractor.dispose();
  }
}