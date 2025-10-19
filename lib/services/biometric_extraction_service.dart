import 'dart:io';
import 'dart:ui';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image/image.dart' as img;
import '../models/ovce_biometrics.dart';

/// Servis pro extrakci biometrických rysů z fotografií ovcí
class BiometricExtractionService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      enableLandmarks: true,
      enableTracking: false,
    ),
  );

  final ObjectDetector _objectDetector = ObjectDetector(
    options: ObjectDetectorOptions(
      mode: DetectionMode.single,
      classifyObjects: true,
      multipleObjects: false,
    ),
  );

  /// Extrahuje kompletní biometrická data z fotografie ovce
  Future<OvceBiometrics?> extractBiometricsFromPhoto(
    String photoPath, 
    String usiCislo,
  ) async {
    try {
      print('🔍 Začínám extrakci biometrických dat z: $photoPath');
      
      final inputImage = InputImage.fromFilePath(photoPath);
      final imageFile = File(photoPath);
      final imageBytes = await imageFile.readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);
      
      if (decodedImage == null) {
        print('❌ Nepodařilo se dekódovat obrázek');
        return null;
      }

      // Paralelní zpracování různých aspektů
      final futures = await Future.wait([
        _extractFaceEmbedding(inputImage),
        _extractColorProfile(decodedImage),
        _extractShapeMetrics(inputImage, decodedImage),
      ]);

      final faceEmbedding = futures[0] as List<double>?;
      final colorProfile = futures[1] as ColorProfile?;
      final shapeMetrics = futures[2] as ShapeMetrics?;

      if (faceEmbedding == null || colorProfile == null || shapeMetrics == null) {
        print('❌ Nepodařilo se extrahovat některá biometrická data');
        return null;
      }

      // Vytvoření unikátních znaků (zatím prázdné, lze rozšířit)
      final uniqueMarks = UniqueMarks();

      // Výpočet confidence na základě kvality extrakce
      double confidence = _calculateExtractionConfidence(
        faceEmbedding, 
        colorProfile, 
        shapeMetrics,
      );

      final biometrics = OvceBiometrics(
        usiCislo: usiCislo,
        faceEmbedding: faceEmbedding,
        colorProfile: colorProfile,
        shapeMetrics: shapeMetrics,
        uniqueMarks: uniqueMarks,
        lastUpdated: DateTime.now(),
        confidence: confidence,
        trainingPhotosCount: 1,
      );

      print('✅ Biometrická data úspěšně extrahována (confidence: ${(confidence * 100).toInt()}%)');
      return biometrics;

    } catch (e) {
      print('❌ Chyba při extrakci biometrických dat: $e');
      return null;
    }
  }

  /// Extrahuje face embedding pomocí ML Kit face detection
  Future<List<double>?> _extractFaceEmbedding(InputImage inputImage) async {
    try {
      final faces = await _faceDetector.processImage(inputImage);
      
      if (faces.isEmpty) {
        print('⚠️ Žádný obličej nenalezen na obrázku');
        return null;
      }

      final face = faces.first;
      
      // Simulujeme 128D face embedding na základě ML Kit landmarks
      List<double> embedding = List.filled(128, 0.0);
      
      // Použijeme face landmarks pro vytvoření embedding
      if (face.landmarks.isNotEmpty) {
        int index = 0;
        for (var landmark in face.landmarks.values) {
          if (index < 126 && landmark != null) {
            embedding[index] = landmark.position.x / 1000.0; // Normalizace
            embedding[index + 1] = landmark.position.y / 1000.0;
            index += 2;
          }
        }
      }

      // Doplníme zbývající hodnoty na základě bounding boxu
      final boundingBox = face.boundingBox;
      embedding[126] = boundingBox.width / 1000.0;
      embedding[127] = boundingBox.height / 1000.0;

      print('✅ Face embedding extrahován (${faces.length} obličejů nalezeno)');
      return embedding;

    } catch (e) {
      print('❌ Chyba při extrakci face embedding: $e');
      return null;
    }
  }

  /// Extrahuje barevný profil z obrázku
  Future<ColorProfile?> _extractColorProfile(img.Image image) async {
    try {
      // Analýza barev v obrázku
      Map<int, int> colorCounts = {};
      int totalPixels = 0;
      double totalBrightness = 0.0;

      // Sample každý 10. pixel pro rychlost
      for (int y = 0; y < image.height; y += 10) {
        for (int x = 0; x < image.width; x += 10) {
          final pixel = image.getPixel(x, y);
          
          // Kvantizace barvy (zjednodušení na 64 úrovní)
          int quantizedColor = _quantizeColor(pixel);
          colorCounts[quantizedColor] = (colorCounts[quantizedColor] ?? 0) + 1;
          
          // Výpočet brightness
          double brightness = _getPixelBrightness(pixel);
          totalBrightness += brightness;
          totalPixels++;
        }
      }

      // Najdi dominantní a sekundární barvy
      var sortedColors = colorCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (sortedColors.length < 2) {
        print('⚠️ Nedostatek barevných dat');
        return null;
      }

      Color dominantColor = Color(sortedColors[0].key);
      Color secondaryColor = Color(sortedColors[1].key);
      
      double averageBrightness = totalBrightness / totalPixels;
      double contrast = _calculateContrast(dominantColor, secondaryColor);

      final colorProfile = ColorProfile(
        dominantColor: dominantColor,
        secondaryColor: secondaryColor,
        brightness: averageBrightness,
        contrast: contrast,
      );

      print('✅ Barevný profil extrahován (dominantní: ${dominantColor.value.toRadixString(16)})');
      return colorProfile;

    } catch (e) {
      print('❌ Chyba při extrakci barevného profilu: $e');
      return null;
    }
  }

  /// Extrahuje geometrické rozměry hlavy
  Future<ShapeMetrics?> _extractShapeMetrics(
    InputImage inputImage, 
    img.Image image,
  ) async {
    try {
      final faces = await _faceDetector.processImage(inputImage);
      
      if (faces.isEmpty) {
        print('⚠️ Žádný obličej pro shape metrics');
        return null;
      }

      final face = faces.first;
      final boundingBox = face.boundingBox;
      final landmarks = face.landmarks;

      // Normalizace rozměrů podle velikosti obrázku
      double imageWidth = image.width.toDouble();
      double imageHeight = image.height.toDouble();

      double headWidth = boundingBox.width / imageWidth;
      double headHeight = boundingBox.height / imageHeight;

      // Odhad rozměrů uší a čenichu na základě landmarks
      double earLength = headHeight * 0.3; // Odhad
      double earWidth = headWidth * 0.15;  // Odhad
      double muzzleWidth = headWidth * 0.4; // Odhad

      // Vzdálenost očí z landmarks
      double eyeDistance = 0.5; // Default
      if (landmarks.containsKey(FaceLandmarkType.leftEye) && 
          landmarks.containsKey(FaceLandmarkType.rightEye)) {
        final leftEye = landmarks[FaceLandmarkType.leftEye]!.position;
        final rightEye = landmarks[FaceLandmarkType.rightEye]!.position;
        eyeDistance = (leftEye.x - rightEye.x).abs() / imageWidth;
      }

      // Poměr nos-ucho
      double noseToEarRatio = earLength / (headHeight * 0.5);

      final shapeMetrics = ShapeMetrics(
        headWidth: headWidth,
        headHeight: headHeight,
        earLength: earLength,
        earWidth: earWidth,
        muzzleWidth: muzzleWidth,
        eyeDistance: eyeDistance,
        noseToEarRatio: noseToEarRatio,
      );

      print('✅ Shape metrics extrahován');
      return shapeMetrics;

    } catch (e) {
      print('❌ Chyba při extrakci shape metrics: $e');
      return null;
    }
  }

  /// Kvantizuje barvu pro snadnější analýzu
  int _quantizeColor(img.Pixel pixel) {
    int r = (pixel.r ~/ 32) * 32;
    int g = (pixel.g ~/ 32) * 32;
    int b = (pixel.b ~/ 32) * 32;
    return Color.fromARGB(255, r, g, b).value;
  }

  /// Vypočítá brightness pixelu
  double _getPixelBrightness(img.Pixel pixel) {
    return (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b) / 255.0;
  }

  /// Vypočítá kontrast mezi dvěma barvami
  double _calculateContrast(Color color1, Color color2) {
    double brightness1 = (0.299 * color1.red + 0.587 * color1.green + 0.114 * color1.blue) / 255.0;
    double brightness2 = (0.299 * color2.red + 0.587 * color2.green + 0.114 * color2.blue) / 255.0;
    return (brightness1 - brightness2).abs();
  }

  /// Vypočítá celkovou confidence extrakce
  double _calculateExtractionConfidence(
    List<double> faceEmbedding,
    ColorProfile colorProfile,
    ShapeMetrics shapeMetrics,
  ) {
    double faceConfidence = faceEmbedding.any((x) => x != 0.0) ? 0.8 : 0.2;
    double colorConfidence = colorProfile.contrast > 0.1 ? 0.9 : 0.5;
    double shapeConfidence = shapeMetrics.headWidth > 0.1 && shapeMetrics.headHeight > 0.1 ? 0.9 : 0.3;
    
    return (faceConfidence + colorConfidence + shapeConfidence) / 3.0;
  }

  /// Kombinuje více biometrických měření do jednoho
  OvceBiometrics combineBiometrics(
    List<OvceBiometrics> measurements,
    String usiCislo,
  ) {
    if (measurements.isEmpty) {
      return OvceBiometrics.empty(usiCislo);
    }

    if (measurements.length == 1) {
      return measurements.first;
    }

    // Průměrování face embeddings
    List<double> avgEmbedding = List.filled(128, 0.0);
    for (int i = 0; i < 128; i++) {
      double sum = 0.0;
      for (var measurement in measurements) {
        sum += measurement.faceEmbedding[i];
      }
      avgEmbedding[i] = sum / measurements.length;
    }

    // Průměrování ostatních metrik
    // (Zjednodušeno - v realitě by bylo složitější)
    final firstMeasurement = measurements.first;
    double avgConfidence = measurements.map((m) => m.confidence).reduce((a, b) => a + b) / measurements.length;

    return OvceBiometrics(
      usiCislo: usiCislo,
      faceEmbedding: avgEmbedding,
      colorProfile: firstMeasurement.colorProfile, // Použije první
      shapeMetrics: firstMeasurement.shapeMetrics,   // Použije první
      uniqueMarks: firstMeasurement.uniqueMarks,     // Použije první
      lastUpdated: DateTime.now(),
      confidence: avgConfidence,
      trainingPhotosCount: measurements.length,
    );
  }

  /// Uvolní zdroje
  void dispose() {
    _faceDetector.close();
    _objectDetector.close();
  }
}