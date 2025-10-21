import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/ovce.dart';
import '../models/ovce_biometrics.dart';
import '../services/document_scanner_service.dart';
import '../services/biometric_extraction_service.dart';

class NovaOvceScreen extends StatefulWidget {
  final Function(Ovce) onSave;
  final Ovce? ovce; // Pro editaci existující ovce
  final Map<String, dynamic>? initialData; // Předvyplněná data z detekce
  final String? initialPhotoPath; // Počáteční fotka

  const NovaOvceScreen({
    super.key, 
    required this.onSave, 
    this.ovce,
    this.initialData,
    this.initialPhotoPath,
  });

  @override
  State<NovaOvceScreen> createState() => _NovaOvceScreenState();
}

class _NovaOvceScreenState extends State<NovaOvceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usiCisloController = TextEditingController();
  final _plemenoController = TextEditingController();
  final _kategorieController = TextEditingController();
  final _matkaController = TextEditingController();
  final _otecController = TextEditingController();
  final _cisloMatkyController = TextEditingController();
  final _pohlaviController = TextEditingController();
  final _poznamkaController = TextEditingController();
  
  final ImagePicker _picker = ImagePicker();
  final DocumentScannerService _documentScanner = DocumentScannerService();
  final BiometricExtractionService _biometricExtractor = BiometricExtractionService();
  List<String> _fotky = [];
  DateTime _datumNarozeni = DateTime.now();

  @override
  void initState() {
    super.initState();
    print('🚀 NovaOvceScreen initState - skenování dokumentu je dostupné!');
    
    // Pokud editujeme existující ovci, naplníme formulář
    if (widget.ovce != null) {
      final ovce = widget.ovce!;
      _usiCisloController.text = ovce.usiCislo;
      _plemenoController.text = ovce.plemeno;
      _kategorieController.text = ovce.kategorie;
      _matkaController.text = ovce.matka;
      _otecController.text = ovce.otec;
      _cisloMatkyController.text = ovce.cisloMatky;
      _pohlaviController.text = ovce.pohlavi;
      _poznamkaController.text = ovce.poznamka;
      _fotky = List.from(ovce.fotky);
      _datumNarozeni = ovce.datumNarozeni;
    }
    
    // Pokud máme předvyplněná data z detekce
    if (widget.initialData != null) {
      final data = widget.initialData!;
      _plemenoController.text = data['plemeno'] ?? '';
      _kategorieController.text = data['kategorie'] ?? '';
      _poznamkaController.text = data['poznamky'] ?? '';
      
      // Pokud je datum registrace definován, použijeme ho jako datum narození (default)
      if (data['datumRegistrace'] != null) {
        try {
          _datumNarozeni = DateTime.parse(data['datumRegistrace']);
        } catch (e) {
          print('Chyba při parsování data registrace: $e');
        }
      }
    }
    
    // Pokud máme počáteční fotku, přidáme ji
    if (widget.initialPhotoPath != null) {
      _fotky.add(widget.initialPhotoPath!);
    }
  }

  @override
  void dispose() {
    _usiCisloController.dispose();
    _plemenoController.dispose();
    _kategorieController.dispose();
    _matkaController.dispose();
    _otecController.dispose();
    _cisloMatkyController.dispose();
    _pohlaviController.dispose();
    _poznamkaController.dispose();
    _documentScanner.dispose();
    _biometricExtractor.dispose();
    super.dispose();
  }

  Future<void> _vyberFotkyZGalerie() async {
    print('🖼️ Spouštím výběr fotek z galerie...');
    final List<XFile> images = await _picker.pickMultiImage();
    print('🖼️ Vybráno ${images.length} fotek z galerie');
    
    if (images.isNotEmpty) {
      final List<String> noveFotky = [];
      for (final image in images) {
        print('🖼️ Zpracovávám fotku: ${image.path}');
        final trvalaCesta = await _kopirojFotku(image.path);
        noveFotky.add(trvalaCesta);
      }
      setState(() {
        _fotky.addAll(noveFotky);
        print('🖼️ Celkem fotek nyní: ${_fotky.length}');
      });
    }
  }

  Future<void> _poridFotkyKamerou() async {
    print('📷 Spouštím fotoaparát...');
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      print('📷 Pořízena fotka: ${image.path}');
      final trvalaCesta = await _kopirojFotku(image.path);
      setState(() {
        _fotky.add(trvalaCesta);
        print('📷 Celkem fotek nyní: ${_fotky.length}');
      });
    } else {
      print('📷 Žádná fotka nebyla pořízena');
    }
  }

  /// Naskenuje dokument a automaticky vyplní informace
  Future<void> _naskenujDokument() async {
    try {
      print('📄 Spouštím skenování dokumentu...');
      
      // Zobrazíme dialog s výběrem
      final scanOption = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Skenování dokumentu'),
          content: const Text('Vyberte způsob skenování dokumentu s informacemi o ovci:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Zrušit'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'camera'),
              child: const Text('Fotoaparát'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'gallery'),
              child: const Text('Galerie'),
            ),
          ],
        ),
      );

      if (scanOption == null) return;

      // Vybereme obrázek
      final XFile? image = await _picker.pickImage(
        source: scanOption == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 100, // Nejvyšší kvalita pro lepší OCR
      );

      if (image != null) {
        // Zobrazíme loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Rozpoznávám text z dokumentu...'),
              ],
            ),
          ),
        );

        // Spustíme OCR
        final ovceInfo = await _documentScanner.scanDocumentForOvceInfo(File(image.path));
        
        // Zavřeme loading dialog
        if (mounted) Navigator.pop(context);

        // Vyplníme formulář s rozpoznanými informacemi
        _vyplnFormularZInfo(ovceInfo);

        // Zobrazíme výsledek
        _zobrazVysledekSkenovani(ovceInfo);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Zavřeme loading dialog pokud je otevřený
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba při skenování dokumentu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('❌ Chyba při skenování dokumentu: $e');
    }
  }

  /// Vyplní formulář s informacemi z naskenovaného dokumentu
  void _vyplnFormularZInfo(Map<String, String?> info) {
    setState(() {
      if (info['usiCislo'] != null && info['usiCislo']!.isNotEmpty) {
        _usiCisloController.text = info['usiCislo']!;
      }
      if (info['plemeno'] != null && info['plemeno']!.isNotEmpty) {
        _plemenoController.text = info['plemeno']!;
      }
      if (info['kategorie'] != null && info['kategorie']!.isNotEmpty) {
        _kategorieController.text = info['kategorie']!;
      }
      if (info['pohlavi'] != null && info['pohlavi']!.isNotEmpty) {
        _pohlaviController.text = info['pohlavi']!;
      }
      if (info['matka'] != null && info['matka']!.isNotEmpty) {
        _matkaController.text = info['matka']!;
      }
      if (info['otec'] != null && info['otec']!.isNotEmpty) {
        _otecController.text = info['otec']!;
      }
      if (info['cisloMatky'] != null && info['cisloMatky']!.isNotEmpty) {
        _cisloMatkyController.text = info['cisloMatky']!;
      }
      if (info['datumNarozeni'] != null && info['datumNarozeni']!.isNotEmpty) {
        try {
          final parts = info['datumNarozeni']!.split('.');
          if (parts.length == 3) {
            _datumNarozeni = DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          }
        } catch (e) {
          print('Chyba při parsování data: $e');
        }
      }
    });
  }

  /// Zobrazí výsledek skenování
  void _zobrazVysledekSkenovani(Map<String, String?> info) {
    final nalezeneInfo = info.entries.where((entry) => 
      entry.value != null && entry.value!.isNotEmpty).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.document_scanner, color: Colors.green),
            SizedBox(width: 8),
            Text('Výsledek skenování'),
          ],
        ),
        content: nalezeneInfo.isNotEmpty
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rozpoznané informace:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...nalezeneInfo.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('• ${_getFieldName(entry.key)}: ${entry.value}'),
                )),
                const SizedBox(height: 16),
                const Text(
                  'Zkontrolujte prosím správnost rozpoznaných údajů a upravte je podle potřeby.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            )
          : const Text('Nepodařilo se rozpoznat žádné informace z dokumentu. Zkuste prosím jiný obrázek s lepší kvalitou.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Převede název pole na lidsky čitelný text
  String _getFieldName(String fieldName) {
    switch (fieldName) {
      case 'usiCislo': return 'Ušní číslo';
      case 'plemeno': return 'Plemeno';
      case 'kategorie': return 'Kategorie';
      case 'pohlavi': return 'Pohlaví';
      case 'matka': return 'Matka';
      case 'otec': return 'Otec';
      case 'cisloMatky': return 'Číslo matky';
      case 'datumNarozeni': return 'Datum narození';
      default: return fieldName;
    }
  }

  Future<String> _kopirojFotku(String puvodniCesta) async {
    try {
      // Pro Android používáme getApplicationSupportDirectory() místo getApplicationDocumentsDirectory()
      final appDir = await getApplicationSupportDirectory();
      final ovceDir = Directory('${appDir.path}/ovce_fotky');
      if (!ovceDir.existsSync()) {
        await ovceDir.create(recursive: true);
        print('✅ Vytvořen adresář pro fotky: ${ovceDir.path}');
      }
      
      final puvodniSoubor = File(puvodniCesta);
      if (!puvodniSoubor.existsSync()) {
        print('❌ CHYBA: Původní soubor neexistuje: $puvodniCesta');
        return puvodniCesta;
      }
      
      final nazevSouboru = 'foto_${DateTime.now().millisecondsSinceEpoch}_${puvodniSoubor.path.split('/').last}';
      final novaCesta = '${ovceDir.path}/$nazevSouboru';
      
      await puvodniSoubor.copy(novaCesta);
      print('✅ Fotka úspěšně zkopírována:');
      print('  Z: $puvodniCesta');
      print('  Do: $novaCesta');
      print('  Existuje: ${File(novaCesta).existsSync()}');
      return novaCesta;
    } catch (e) {
      print('❌ Chyba při kopírování fotky: $e');
      print('  Původní cesta: $puvodniCesta');
      return puvodniCesta; // Vrátíme původní cestu jako fallback
    }
  }

  void _vyberDatum() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _datumNarozeni,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _datumNarozeni) {
      setState(() {
        _datumNarozeni = picked;
      });
    }
  }

  Future<void> _ulozitOvci() async {
    if (_formKey.currentState!.validate()) {
      // Zobrazení loading dialogu
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Ukládám ovci a analyzuji fotky...'),
            ],
          ),
        ),
      );

      try {
        // Ujistíme se, že všechny fotky jsou zkopírovány do trvalého úložiště
        final List<String> trvaleFotky = [];
        for (final fotka in _fotky) {
          // Zkontrolujeme, jestli je fotka už v trvalém úložišti
          final appDir = await getApplicationSupportDirectory();
          final ovceDir = '${appDir.path}/ovce_fotky';
          
          if (fotka.contains(ovceDir)) {
            // Fotka je už v trvalém úložišti
            trvaleFotky.add(fotka);
            print('📁 Fotka už je trvalá: $fotka');
          } else {
            // Fotka je dočasná, zkopírujeme ji
            final trvalaCesta = await _kopirojFotku(fotka);
            trvaleFotky.add(trvalaCesta);
            print('📋 Fotka zkopírována: $fotka -> $trvalaCesta');
          }
        }

        // Extrakce biometrických dat z první fotky (pokud existuje)
        OvceBiometrics? biometrics;
        if (trvaleFotky.isNotEmpty) {
          print('🧬 Extrahuji biometrická data z fotky: ${trvaleFotky.first}');
          biometrics = await _biometricExtractor.extractBiometricsFromPhoto(
            trvaleFotky.first,
            _usiCisloController.text,
          );
          
          if (biometrics != null) {
            print('✅ Biometrická data úspěšně extrahována!');
            print('   - Confidence: ${biometrics.confidence}');
            print('   - Foto count: ${biometrics.trainingPhotosCount}');
          } else {
            print('⚠️ Nepodařilo se extrahovat biometrická data');
          }
        }
        
        final novaOvce = Ovce(
          usiCislo: _usiCisloController.text,
          datumNarozeni: _datumNarozeni,
          matka: _matkaController.text,
          otec: _otecController.text,
          plemeno: _plemenoController.text,
          kategorie: _kategorieController.text,
          cisloMatky: _cisloMatkyController.text,
          pohlavi: _pohlaviController.text,
          poznamka: _poznamkaController.text,
          fotky: trvaleFotky,
          datumRegistrace: widget.ovce?.datumRegistrace ?? DateTime.now(),
          biometrics: biometrics,
          referencePhotos: trvaleFotky.take(3).toList(), // První 3 fotky jako reference
          isTrainedForRecognition: biometrics != null && biometrics.confidence > 0.5,
        );

        // Zavři loading dialog
        if (mounted) Navigator.of(context).pop();

        widget.onSave(novaOvce);
        Navigator.of(context).pop(novaOvce);
      } catch (e) {
        // Zavři loading dialog při chybě
        if (mounted) Navigator.of(context).pop();
        
        // Zobraz chybovou zprávu
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chyba při ukládání: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        print('❌ Chyba při ukládání ovce: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ovce != null ? 'Editovat ovci' : 'Nová ovce'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner),
            onPressed: _naskenujDokument,
            tooltip: 'Naskenovat dokument',
          ),
          TextButton(
            onPressed: () async => await _ulozitOvci(),
            child: const Text('ULOŽIT', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fotky sekce
              const Text(
                'Fotky',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              // Info o biometrických datech
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'První fotka se použije pro automatické trénování live detekce. '
                        'Čím více kvalitních fotek, tím lepší rozpoznávání.',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Galerie
                    GestureDetector(
                      onTap: _vyberFotkyZGalerie,
                      child: Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_library, color: Colors.blue),
                            Text('Více fotek', style: TextStyle(fontSize: 9, color: Colors.blue)),
                            Text('z galerie', style: TextStyle(fontSize: 8, color: Colors.blue)),
                          ],
                        ),
                      ),
                    ),
                    // Kamera
                    GestureDetector(
                      onTap: _poridFotkyKamerou,
                      child: Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, color: Colors.green),
                            Text('Fotoaparát', style: TextStyle(fontSize: 9, color: Colors.green)),
                          ],
                        ),
                      ),
                    ),
                    // Skenování dokumentu
                    GestureDetector(
                      onTap: _naskenujDokument,
                      child: Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.orange),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.document_scanner, color: Colors.orange),
                            Text('Skenovat', style: TextStyle(fontSize: 9, color: Colors.orange)),
                            Text('dokument', style: TextStyle(fontSize: 8, color: Colors.orange)),
                          ],
                        ),
                      ),
                    ),
                    // Zobrazení vybraných fotek
                    ..._fotky.map((foto) => Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(right: 10),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(foto),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _fotky.remove(foto);
                                });
                              },
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Formulář
              TextFormField(
                controller: _usiCisloController,
                decoration: const InputDecoration(
                  labelText: 'Ušní číslo *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty == true ? 'Povinné pole' : null,
              ),
              const SizedBox(height: 16),
              
              // Datum narození
              InkWell(
                onTap: _vyberDatum,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Datum narození: ${_datumNarozeni.day}.${_datumNarozeni.month}.${_datumNarozeni.year}'),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _plemenoController,
                decoration: const InputDecoration(
                  labelText: 'Plemeno *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty == true ? 'Povinné pole' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _kategorieController,
                decoration: const InputDecoration(
                  labelText: 'Kategorie (BER/BAH/JEH)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _pohlaviController,
                decoration: const InputDecoration(
                  labelText: 'Pohlaví (beran/ovce)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _matkaController,
                decoration: const InputDecoration(
                  labelText: 'Číslo matky',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _otecController,
                decoration: const InputDecoration(
                  labelText: 'Číslo otce',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _cisloMatkyController,
                decoration: const InputDecoration(
                  labelText: 'Číslo matky (z dokumentu)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _poznamkaController,
                decoration: const InputDecoration(
                  labelText: 'Poznámka',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
