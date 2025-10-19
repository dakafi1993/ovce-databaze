import 'dart:io';

import 'package:flutter/material.dart';
import '../models/ovce.dart';
import '../services/ovce_service_api.dart';
import '../services/pdf_export_service.dart';
import '../widgets/connection_status_widget.dart';
import '../data/registr_ovci.dart';
import 'nova_ovce_screen.dart';
import 'detail_ovce_screen.dart';
import 'live_detekce_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OvceService _ovceService = OvceService();
  final PdfExportService _pdfExportService = PdfExportService();
  late List<Ovce> _ovce;

  @override
  void initState() {
    super.initState();
    _loadOvce();
  }

  void _loadOvce() async {
    final ovce = await _ovceService.getAllOvce();
    setState(() {
      _ovce = ovce;
    });
  }

  void _zobrazitFormular() async {
    final result = await Navigator.of(context).push<Ovce?>(
      MaterialPageRoute(
        builder: (context) => NovaOvceScreen(
          onSave: (ovce) async {
            try {
              await _ovceService.addOvce(ovce);
              _loadOvce(); // Reload dat
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ovce byla úspěšně přidána')),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Chyba: ${e.toString()}')),
                );
              }
            }
          },
        ),
      ),
    );
    if (result != null) {
      _loadOvce();
    }
  }

  void _zobrazitDetail(Ovce ovce) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetailOvceScreen(ovce: ovce),
      ),
    );
    // Reload dat po návratu z detail screenu (pro případ editace)
    _loadOvce();
  }

  // Export do PDF s možnostmi
  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.print),
            title: const Text('Náhled a tisk'),
            onTap: () async {
              Navigator.pop(context);
              await _exportToPdf('print');
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Sdílet PDF'),
            onTap: () async {
              Navigator.pop(context);
              await _exportToPdf('share');
            },
          ),
          ListTile(
            leading: const Icon(Icons.save_alt),
            title: const Text('Uložit PDF'),
            onTap: () async {
              Navigator.pop(context);
              await _exportToPdf('save');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _exportToPdf(String action) async {
    try {
      await _pdfExportService.exportOvceToPDF(
        _ovce,
        action: action,
        customFileName: 'ovce_registr_${DateTime.now().day}_${DateTime.now().month}_${DateTime.now().year}.pdf',
      );
      
      if (mounted && action == 'save') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF bylo úspěšně uloženo')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba při exportu: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _importOvciZRegistru() async {
    final potvrzeni = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📋 Import z registru'),
        content: Text(
          'Chcete importovat všechny ovce z registru?\n\n'
          'Bude přidáno 26 záznamů podle registračního dokumentu.\n'
          'Data budou uložena na Railway server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Zrušit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Importovat'),
          ),
        ],
      ),
    );

    if (potvrzeni == true) {
      await RegistrOvci.pridejVsechnyOvce(context);
      _loadOvce(); // Obnovit seznam
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import z registru',
            onPressed: () async {
              await _importOvciZRegistru();
            },
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LiveDetekceScreen(),
                ),
              );
            },
            tooltip: 'Live detekce ovcí',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _ovce.isNotEmpty ? _showExportOptions : null,
            tooltip: 'Export do PDF',
          ),
        ],
      ),
      body: _ovce.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Žádné ovce v databázi\nPřidejte novou ovci pomocí tlačítka +',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => LiveDetekceScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Spustit Live Detekci Ovcí'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _ovce.length,
              itemBuilder: (context, index) {
                final ovce = _ovce[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green,
                      child: ovce.fotky.isNotEmpty
                          ? ClipOval(
                              child: Image.file(
                                File(ovce.fotky.first),
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Chyba při načítání avatar fotky: $error');
                                  print('Cesta k souboru: ${ovce.fotky.first}');
                                  print('Soubor existuje: ${File(ovce.fotky.first).existsSync()}');
                                  return Text(ovce.usiCislo[0].toUpperCase());
                                },
                              ),
                            )
                          : Text(
                              ovce.usiCislo[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    title: Text(
                      ovce.usiCislo,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Text(
                      '${ovce.plemeno} • ${ovce.kategorie}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    onTap: () => _zobrazitDetail(ovce),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Indikátor biometrických dat
                        if (ovce.hasGoodBiometrics)
                          Container(
                            margin: EdgeInsets.only(right: 8),
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade400),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility, color: Colors.green.shade700, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'AI',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                        final shouldDelete = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Smazat ovci'),
                            content: Text('Opravdu chcete smazat ovci ${ovce.usiCislo}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Zrušit'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Smazat'),
                              ),
                            ],
                          ),
                        );
                        
                        if (shouldDelete == true) {
                          try {
                            await _ovceService.deleteOvce(ovce.usiCislo);
                            _loadOvce();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Ovce byla smazána')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Chyba při mazání: ${e.toString()}')),
                              );
                            }
                          }
                        }
                      },
                    ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Zelený FAB pro live detekci  
          FloatingActionButton.extended(
            heroTag: "live_detection",
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LiveDetekceScreen(),
                ),
              );
            },
            backgroundColor: Colors.green,
            icon: const Icon(Icons.camera_alt),
            label: const Text('LIVE DETEKCE'),
          ),
          const SizedBox(height: 10),
          // Modré FAB pro přidání ovce
          FloatingActionButton.extended(
            heroTag: "add_sheep",
            onPressed: _zobrazitFormular,
            backgroundColor: Colors.blue,
            icon: const Icon(Icons.add),
            label: const Text('PŘIDAT OVCI'),
          ),
        ],
      ),
    );
  }
}
