import 'dart:ui';

/// Barevný profil ovce pro rozpoznávání
class ColorProfile {
  final Color dominantColor;        // Hlavní barva srsti
  final Color secondaryColor;       // Sekundární barva
  final List<Color> uniqueMarks;    // Jedinečné skvrny/znaky
  final double brightness;          // Celková světlost (0.0-1.0)
  final double contrast;            // Kontrast barev (0.0-1.0)

  ColorProfile({
    required this.dominantColor,
    required this.secondaryColor,
    this.uniqueMarks = const [],
    required this.brightness,
    required this.contrast,
  });

  /// Porovná dva barevné profily a vrátí similarity score (0.0-1.0)
  double compareTo(ColorProfile other) {
    double colorSimilarity = _compareColors(dominantColor, other.dominantColor);
    double secondarySimilarity = _compareColors(secondaryColor, other.secondaryColor);
    double brightnessSimilarity = 1.0 - (brightness - other.brightness).abs();
    double contrastSimilarity = 1.0 - (contrast - other.contrast).abs();
    
    return (colorSimilarity + secondarySimilarity + brightnessSimilarity + contrastSimilarity) / 4.0;
  }

  double _compareColors(Color c1, Color c2) {
    double rDiff = (c1.red - c2.red).abs() / 255.0;
    double gDiff = (c1.green - c2.green).abs() / 255.0;
    double bDiff = (c1.blue - c2.blue).abs() / 255.0;
    return 1.0 - ((rDiff + gDiff + bDiff) / 3.0);
  }

  Map<String, dynamic> toJson() => {
    'dominantColor': dominantColor.value,
    'secondaryColor': secondaryColor.value,
    'uniqueMarks': uniqueMarks.map((c) => c.value).toList(),
    'brightness': brightness,
    'contrast': contrast,
  };

  factory ColorProfile.fromJson(Map<String, dynamic> json) => ColorProfile(
    dominantColor: Color(json['dominantColor']),
    secondaryColor: Color(json['secondaryColor']),
    uniqueMarks: (json['uniqueMarks'] as List).map((c) => Color(c)).toList(),
    brightness: json['brightness'],
    contrast: json['contrast'],
  );
}

/// Geometrické rozměry hlavy ovce
class ShapeMetrics {
  final double headWidth;           // Šířka hlavy (relativní)
  final double headHeight;          // Výška hlavy (relativní)
  final double earLength;           // Délka uší (relativní)
  final double earWidth;            // Šířka uší (relativní)
  final double muzzleWidth;         // Šířka čenichu (relativní)
  final double eyeDistance;         // Vzdálenost očí (relativní)
  final double noseToEarRatio;      // Poměr nos-ucho

  ShapeMetrics({
    required this.headWidth,
    required this.headHeight,
    required this.earLength,
    required this.earWidth,
    required this.muzzleWidth,
    required this.eyeDistance,
    required this.noseToEarRatio,
  });

  /// Porovná dva shape metrics a vrátí similarity score (0.0-1.0)
  double compareTo(ShapeMetrics other) {
    double widthSim = 1.0 - (headWidth - other.headWidth).abs();
    double heightSim = 1.0 - (headHeight - other.headHeight).abs();
    double earLengthSim = 1.0 - (earLength - other.earLength).abs();
    double earWidthSim = 1.0 - (earWidth - other.earWidth).abs();
    double muzzleSim = 1.0 - (muzzleWidth - other.muzzleWidth).abs();
    double eyeSim = 1.0 - (eyeDistance - other.eyeDistance).abs();
    double ratioSim = 1.0 - (noseToEarRatio - other.noseToEarRatio).abs();
    
    return (widthSim + heightSim + earLengthSim + earWidthSim + muzzleSim + eyeSim + ratioSim) / 7.0;
  }

  Map<String, dynamic> toJson() => {
    'headWidth': headWidth,
    'headHeight': headHeight,
    'earLength': earLength,
    'earWidth': earWidth,
    'muzzleWidth': muzzleWidth,
    'eyeDistance': eyeDistance,
    'noseToEarRatio': noseToEarRatio,
  };

  factory ShapeMetrics.fromJson(Map<String, dynamic> json) => ShapeMetrics(
    headWidth: json['headWidth'],
    headHeight: json['headHeight'],
    earLength: json['earLength'],
    earWidth: json['earWidth'],
    muzzleWidth: json['muzzleWidth'],
    eyeDistance: json['eyeDistance'],
    noseToEarRatio: json['noseToEarRatio'],
  );
}

/// Unikátní znaky ovce
class UniqueMarks {
  final List<String> scars;         // Jizvy
  final List<String> birthmarks;    // Mateřské znaky
  final List<String> colorPatterns; // Barevné vzory
  final List<String> earNotches;    // Zářezy v uších
  final String woolTexture;         // Textura vlny
  final String notes;               // Poznámky

  UniqueMarks({
    this.scars = const [],
    this.birthmarks = const [],
    this.colorPatterns = const [],
    this.earNotches = const [],
    this.woolTexture = '',
    this.notes = '',
  });

  /// Porovná unikátní znaky a vrátí similarity score (0.0-1.0)
  double compareTo(UniqueMarks other) {
    double scarsSimilarity = _compareStringLists(scars, other.scars);
    double marksSimilarity = _compareStringLists(birthmarks, other.birthmarks);
    double patternsSimilarity = _compareStringLists(colorPatterns, other.colorPatterns);
    double notchesSimilarity = _compareStringLists(earNotches, other.earNotches);
    double textureSimilarity = woolTexture == other.woolTexture ? 1.0 : 0.0;
    
    return (scarsSimilarity + marksSimilarity + patternsSimilarity + notchesSimilarity + textureSimilarity) / 5.0;
  }

  double _compareStringLists(List<String> list1, List<String> list2) {
    if (list1.isEmpty && list2.isEmpty) return 1.0;
    if (list1.isEmpty || list2.isEmpty) return 0.0;
    
    int matches = 0;
    for (String item1 in list1) {
      for (String item2 in list2) {
        if (item1.toLowerCase() == item2.toLowerCase()) {
          matches++;
          break;
        }
      }
    }
    
    return matches / ((list1.length + list2.length) / 2.0);
  }

  Map<String, dynamic> toJson() => {
    'scars': scars,
    'birthmarks': birthmarks,
    'colorPatterns': colorPatterns,
    'earNotches': earNotches,
    'woolTexture': woolTexture,
    'notes': notes,
  };

  factory UniqueMarks.fromJson(Map<String, dynamic> json) => UniqueMarks(
    scars: List<String>.from(json['scars'] ?? []),
    birthmarks: List<String>.from(json['birthmarks'] ?? []),
    colorPatterns: List<String>.from(json['colorPatterns'] ?? []),
    earNotches: List<String>.from(json['earNotches'] ?? []),
    woolTexture: json['woolTexture'] ?? '',
    notes: json['notes'] ?? '',
  );
}

/// Kompletní biometrická data ovce
class OvceBiometrics {
  final String usiCislo;                    // Identifikace ovce
  final List<double> faceEmbedding;         // 128D vektor rysů obličeje (ML Kit)
  final ColorProfile colorProfile;          // Barevný profil
  final ShapeMetrics shapeMetrics;          // Geometrické rozměry
  final UniqueMarks uniqueMarks;            // Unikátní znaky
  final DateTime lastUpdated;               // Poslední aktualizace
  final double confidence;                  // Spolehlivost biometrických dat (0.0-1.0)
  final int trainingPhotosCount;            // Počet fotek použitých pro trénink

  OvceBiometrics({
    required this.usiCislo,
    required this.faceEmbedding,
    required this.colorProfile,
    required this.shapeMetrics,
    required this.uniqueMarks,
    required this.lastUpdated,
    required this.confidence,
    required this.trainingPhotosCount,
  });

  /// Porovná biometrická data s jinými a vrátí celkové similarity score (0.0-1.0)
  double compareTo(OvceBiometrics other) {
    // Face embedding comparison (cosine similarity)
    double faceSimilarity = _cosineSimilarity(faceEmbedding, other.faceEmbedding);
    
    // Individual component similarities
    double colorSimilarity = colorProfile.compareTo(other.colorProfile);
    double shapeSimilarity = shapeMetrics.compareTo(other.shapeMetrics);
    double marksSimilarity = uniqueMarks.compareTo(other.uniqueMarks);
    
    // Weighted average (face embedding má nejvyšší váhu)
    double weightedScore = (faceSimilarity * 0.5) + 
                          (colorSimilarity * 0.2) + 
                          (shapeSimilarity * 0.2) + 
                          (marksSimilarity * 0.1);
    
    // Adjust by confidence levels
    double confidenceAdjustment = (confidence + other.confidence) / 2.0;
    
    return weightedScore * confidenceAdjustment;
  }

  /// Cosine similarity pro face embeddings
  double _cosineSimilarity(List<double> vec1, List<double> vec2) {
    if (vec1.length != vec2.length) return 0.0;
    
    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;
    
    for (int i = 0; i < vec1.length; i++) {
      dotProduct += vec1[i] * vec2[i];
      norm1 += vec1[i] * vec1[i];
      norm2 += vec2[i] * vec2[i];
    }
    
    if (norm1 == 0.0 || norm2 == 0.0) return 0.0;
    
    return dotProduct / (sqrt(norm1) * sqrt(norm2));
  }

  double sqrt(double x) => x < 0 ? 0.0 : x == 0 ? 0.0 : x / (1 + x);

  Map<String, dynamic> toJson() => {
    'usiCislo': usiCislo,
    'faceEmbedding': faceEmbedding,
    'colorProfile': colorProfile.toJson(),
    'shapeMetrics': shapeMetrics.toJson(),
    'uniqueMarks': uniqueMarks.toJson(),
    'lastUpdated': lastUpdated.toIso8601String(),
    'confidence': confidence,
    'trainingPhotosCount': trainingPhotosCount,
  };

  factory OvceBiometrics.fromJson(Map<String, dynamic> json) => OvceBiometrics(
    usiCislo: json['usiCislo'],
    faceEmbedding: List<double>.from(json['faceEmbedding']),
    colorProfile: ColorProfile.fromJson(json['colorProfile']),
    shapeMetrics: ShapeMetrics.fromJson(json['shapeMetrics']),
    uniqueMarks: UniqueMarks.fromJson(json['uniqueMarks']),
    lastUpdated: DateTime.parse(json['lastUpdated']),
    confidence: json['confidence'],
    trainingPhotosCount: json['trainingPhotosCount'],
  );

  /// Vytvoří prázdný biometrický profil pro novou ovci
  factory OvceBiometrics.empty(String usiCislo) => OvceBiometrics(
    usiCislo: usiCislo,
    faceEmbedding: List.filled(128, 0.0), // Prázdný 128D vektor
    colorProfile: ColorProfile(
      dominantColor: const Color(0xFFFFFFFF),
      secondaryColor: const Color(0xFF000000),
      brightness: 0.5,
      contrast: 0.5,
    ),
    shapeMetrics: ShapeMetrics(
      headWidth: 0.5,
      headHeight: 0.5,
      earLength: 0.5,
      earWidth: 0.5,
      muzzleWidth: 0.5,
      eyeDistance: 0.5,
      noseToEarRatio: 0.5,
    ),
    uniqueMarks: UniqueMarks(),
    lastUpdated: DateTime.now(),
    confidence: 0.0,
    trainingPhotosCount: 0,
  );
}