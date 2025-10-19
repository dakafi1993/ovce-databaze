import 'ovce_biometrics.dart';

// Model pro ovci podle registru
class Ovce {
  final String? id; // ID pro databázi (null pro nové ovce)
  final String usiCislo; // Ušní číslo
  final DateTime datumNarozeni;
  final String matka; // Číslo matky
  final String otec; // Číslo otce
  final String plemeno;
  final String kategorie; // BER, BAH, JEH
  final String cisloMatky; // Číslo z dokumentu
  final String pohlavi; // Pohlaví
  final String poznamka;
  final List<String> fotky; // Cesty k fotkám
  final DateTime datumRegistrace;
  
  // Rozšířené vlastnosti pro biometrické rozpoznávání
  final OvceBiometrics? biometrics;           // Biometrická data
  final List<String> referencePhotos;        // Kvalitní referenční fotky pro ML
  final Map<String, double> recognitionHistory; // Historie rozpoznání (datum -> confidence)
  final double recognitionAccuracy;           // Celková přesnost rozpoznávání (0.0-1.0)
  final bool isTrainedForRecognition;         // Zda je ovce natrénovaná pro rozpoznávání

  Ovce({
    this.id,
    required this.usiCislo,
    required this.datumNarozeni,
    required this.matka,
    required this.otec,
    required this.plemeno,
    required this.kategorie,
    required this.cisloMatky,
    required this.pohlavi,
    this.poznamka = '',
    this.fotky = const [],
    required this.datumRegistrace,
    this.biometrics,
    this.referencePhotos = const [],
    this.recognitionHistory = const {},
    this.recognitionAccuracy = 0.0,
    this.isTrainedForRecognition = false,
  });

  // Pro zobrazení jména (používáme ušní číslo)
  String get jmeno => usiCislo;
  
  // Vypočítat věk
  int get vek {
    final now = DateTime.now();
    int age = now.year - datumNarozeni.year;
    if (now.month < datumNarozeni.month || 
        (now.month == datumNarozeni.month && now.day < datumNarozeni.day)) {
      age--;
    }
    return age;
  }

  // Zkontroluje, zda má ovce dostatečná biometrická data pro rozpoznávání
  bool get hasGoodBiometrics => 
    biometrics != null && 
    biometrics!.confidence > 0.7 && 
    biometrics!.trainingPhotosCount >= 3;

  // Vrátí průměrnou confidence z historie rozpoznání
  double get averageRecognitionConfidence {
    if (recognitionHistory.isEmpty) return 0.0;
    double sum = recognitionHistory.values.reduce((a, b) => a + b);
    return sum / recognitionHistory.length;
  }

  // Vytvoří kopii ovce s aktualizovanými biometrickými daty
  Ovce copyWithBiometrics({
    OvceBiometrics? newBiometrics,
    List<String>? newReferencePhotos,
    Map<String, double>? newRecognitionHistory,
    double? newRecognitionAccuracy,
    bool? newIsTrainedForRecognition,
  }) {
    return Ovce(
      id: id,
      usiCislo: usiCislo,
      datumNarozeni: datumNarozeni,
      matka: matka,
      otec: otec,
      plemeno: plemeno,
      kategorie: kategorie,
      cisloMatky: cisloMatky,
      pohlavi: pohlavi,
      poznamka: poznamka,
      fotky: fotky,
      datumRegistrace: datumRegistrace,
      biometrics: newBiometrics ?? biometrics,
      referencePhotos: newReferencePhotos ?? referencePhotos,
      recognitionHistory: newRecognitionHistory ?? recognitionHistory,
      recognitionAccuracy: newRecognitionAccuracy ?? recognitionAccuracy,
      isTrainedForRecognition: newIsTrainedForRecognition ?? isTrainedForRecognition,
    );
  }

  /// Převede ovci na JSON pro API
  Map<String, dynamic> toApiJson() {
    return {
      'id': id,
      'usi_cislo': usiCislo,
      'datum_narozeni': datumNarozeni.toIso8601String(),
      'matka': matka,
      'otec': otec,
      'plemeno': plemeno,
      'kategorie': kategorie,
      'cislo_matky': cisloMatky,
      'pohlavi': pohlavi,
      'poznamka': poznamka,
      'fotky': fotky,
      'datum_registrace': datumRegistrace.toIso8601String(),
      'biometrics': biometrics?.toJson(),
      'reference_photos': referencePhotos,
      'recognition_history': recognitionHistory,
      'recognition_accuracy': recognitionAccuracy,
      'is_trained_for_recognition': isTrainedForRecognition,
    };
  }

  /// Vytvoří ovci z JSON odpovědi API
  factory Ovce.fromApiJson(Map<String, dynamic> json) {
    return Ovce(
      id: json['id']?.toString(),
      usiCislo: json['usi_cislo'] ?? json['usiCislo'] ?? '',
      datumNarozeni: DateTime.tryParse(json['datum_narozeni'] ?? json['datumNarozeni'] ?? '') ?? DateTime.now(),
      matka: json['matka'] ?? '',
      otec: json['otec'] ?? '',
      plemeno: json['plemeno'] ?? '',
      kategorie: json['kategorie'] ?? '',
      cisloMatky: json['cislo_matky'] ?? json['cisloMatky'] ?? '',
      pohlavi: json['pohlavi'] ?? '',
      poznamka: json['poznamka'] ?? '',
      fotky: List<String>.from(json['fotky'] ?? []),
      datumRegistrace: DateTime.tryParse(json['datum_registrace'] ?? json['datumRegistrace'] ?? '') ?? DateTime.now(),
      biometrics: json['biometrics'] != null ? OvceBiometrics.fromJson(json['biometrics']) : null,
      referencePhotos: List<String>.from(json['reference_photos'] ?? json['referencePhotos'] ?? []),
      recognitionHistory: Map<String, double>.from(json['recognition_history'] ?? json['recognitionHistory'] ?? {}),
      recognitionAccuracy: (json['recognition_accuracy'] ?? json['recognitionAccuracy'] ?? 0.0).toDouble(),
      isTrainedForRecognition: json['is_trained_for_recognition'] ?? json['isTrainedForRecognition'] ?? false,
    );
  }
}
