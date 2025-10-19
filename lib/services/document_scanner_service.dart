import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class DocumentScannerService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Naskenuje dokument a pokusí se rozpoznat informace o ovci
  Future<Map<String, String?>> scanDocumentForOvceInfo(File imageFile) async {
    try {
      print('📄 Spouštím OCR analýzu dokumentu...');
      
      final InputImage inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      print('📄 Rozpoznaný text:');
      print(recognizedText.text);
      
      // Parsování textu a hledání informací o ovci
      final ovceInfo = _parseOvceInfo(recognizedText.text);
      
      print('📄 Rozpoznané informace:');
      ovceInfo.forEach((key, value) {
        if (value != null && value.isNotEmpty) {
          print('  $key: $value');
        }
      });
      
      return ovceInfo;
    } catch (e) {
      print('❌ Chyba při OCR analýze: $e');
      return {};
    }
  }

  /// Parsuje rozpoznaný text a hledá informace o ovci
  Map<String, String?> _parseOvceInfo(String text) {
    final result = <String, String?>{
      'usiCislo': null,
      'plemeno': null,
      'kategorie': null,
      'pohlavi': null,
      'matka': null,
      'otec': null,
      'cisloMatky': null,
      'datumNarozeni': null,
    };

    // Normalizace textu - převod na lowercase a odstranění diakritiky
    final normalizedText = text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    print('📄 Normalizovaný text: $normalizedText');

    // Hledání ušního čísla (vzor: číslice, často 9 číslic)
    final usiCisloRegex = RegExp(r'\b(\d{9}|\d{8}|\d{6,10})\b');
    final usiCisloMatch = usiCisloRegex.firstMatch(normalizedText);
    if (usiCisloMatch != null) {
      result['usiCislo'] = usiCisloMatch.group(1);
      print('🔍 Nalezeno ušní číslo: ${result['usiCislo']}');
    }

    // Hledání plemene (BER, BAH, atd.)
    final plemenoRegex = RegExp(r'\b(ber|bah|jeh|berger|bahna|jehnata)\b', caseSensitive: false);
    final plemenoMatch = plemenoRegex.firstMatch(normalizedText);
    if (plemenoMatch != null) {
      String plemeno = plemenoMatch.group(1)!.toUpperCase();
      if (plemeno.contains('BER')) result['plemeno'] = 'BER';
      else if (plemeno.contains('BAH')) result['plemeno'] = 'BAH';
      else if (plemeno.contains('JEH')) result['plemeno'] = 'JEH';
      print('🔍 Nalezeno plemeno: ${result['plemeno']}');
    }

    // Hledání pohlaví
    if (normalizedText.contains('beran') || normalizedText.contains('samec')) {
      result['pohlavi'] = 'beran';
      print('🔍 Nalezeno pohlaví: beran');
    } else if (normalizedText.contains('ovce') || normalizedText.contains('samice')) {
      result['pohlavi'] = 'ovce';
      print('🔍 Nalezeno pohlaví: ovce');
    }

    // Hledání kategorie
    if (normalizedText.contains('beran')) {
      result['kategorie'] = 'beran';
    } else if (normalizedText.contains('ovce')) {
      result['kategorie'] = 'ovce';
    }

    // Hledání čísla matky (vzor: CZ následované čísly)
    final cisloMatkyRegex = RegExp(r'\bcz\s*(\d+)\b', caseSensitive: false);
    final cisloMatkyMatch = cisloMatkyRegex.firstMatch(normalizedText);
    if (cisloMatkyMatch != null) {
      result['cisloMatky'] = 'CZ${cisloMatkyMatch.group(1)}';
      print('🔍 Nalezeno číslo matky: ${result['cisloMatky']}');
    }

    // Hledání data narození (různé formáty)
    final datumRegex = RegExp(r'\b(\d{1,2})[.\-/](\d{1,2})[.\-/](\d{4}|\d{2})\b');
    final datumMatch = datumRegex.firstMatch(normalizedText);
    if (datumMatch != null) {
      final den = datumMatch.group(1)!.padLeft(2, '0');
      final mesic = datumMatch.group(2)!.padLeft(2, '0');
      String rok = datumMatch.group(3)!;
      if (rok.length == 2) {
        // Převod dvouciferného roku na čtyřciferný
        int rokInt = int.parse(rok);
        rok = rokInt > 50 ? '19$rok' : '20$rok';
      }
      result['datumNarozeni'] = '$den.$mesic.$rok';
      print('🔍 Nalezeno datum narození: ${result['datumNarozeni']}');
    }

    return result;
  }

  /// Uvolní zdroje
  void dispose() {
    _textRecognizer.close();
  }
}