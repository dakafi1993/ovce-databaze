import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'live_detekce_screen.dart';
import 'nova_ovce_screen.dart';
import '../services/ovce_service_api.dart';
import '../models/ovce.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final OvceService _ovceService = OvceService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 0 - Home Screen
          HomeScreen(title: 'Databáze ovcí'),
          
          // 1 - Live Detection Screen
          LiveDetekceScreen(),
          
          // 2 - Add Sheep Screen (placeholder)
          Container(),
          
          // 3 - Import Screen
          _buildImportScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) async {
          if (index == 2) {
            // Dialog pro výběr způsobu přidání ovce
            await _showAddSheepOptions();
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Domů',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Live detekce',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Přidat ovci',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_download),
            label: 'Import',
          ),
        ],
      ),
    );
  }

  /// Jednoduchý import screen
  Widget _buildImportScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import ovcí'),
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_download,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            const Text(
              'Import 26 ovcí z registru',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Přidá všechny ovce podle\nregistračního dokumentu',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _simpleImport,
              icon: const Icon(Icons.download),
              label: const Text('Spustit import'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Jednoduchý import bez dialogů
  Future<void> _simpleImport() async {
    print('🚀 JEDNODUCHÝ IMPORT - ZAČÁTEK');
    
    try {
      // Zobrazit snackbar s informací
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏳ Import ovcí započat...'),
          backgroundColor: Colors.blue,
        ),
      );

      // Inicializace service
      print('🔧 Inicializuji OvceService...');
      await _ovceService.initialize();
      print('✅ Service inicializován');

      // Přidání ovcí přímo přes API
      print('📊 Začínám přidávat ovce...');
      
      final ovceData = [
        {'usi_cislo': '006178035', 'datum_narozeni': '2020-03-10', 'kategorie': 'BER', 'plemeno': 'Suffolk'},
        {'usi_cislo': '023415035', 'datum_narozeni': '2019-02-24', 'kategorie': 'BAH', 'plemeno': 'Suffolk'},
        {'usi_cislo': '020437635', 'datum_narozeni': '2019-03-12', 'kategorie': 'BAH', 'plemeno': 'Suffolk'},
        {'usi_cislo': '020449035', 'datum_narozeni': '2019-02-26', 'kategorie': 'BAH', 'plemeno': 'Suffolk'},
        {'usi_cislo': '025380035', 'datum_narozeni': '2024-02-09', 'kategorie': 'JEH', 'plemeno': 'Suffolk'},
      ];

      int uspesne = 0;
      for (final data in ovceData) {
        try {
          print('📝 Přidávám ovci: ${data['usi_cislo']}');
          
          final ovce = Ovce(
            usiCislo: data['usi_cislo']!,
            datumNarozeni: DateTime.parse(data['datum_narozeni']!),
            matka: '',
            otec: '',
            plemeno: data['plemeno']!,
            kategorie: data['kategorie']!,
            cisloMatky: '',
            pohlavi: data['kategorie'] == 'BER' ? 'Samec' : 'Samice',
            poznamka: 'Import z registru ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
            datumRegistrace: DateTime.now(),
          );

          await _ovceService.addOvce(ovce);
          uspesne++;
          print('✅ Přidána ovce: ${ovce.usiCislo}');
        } catch (e) {
          print('❌ Chyba při přidávání ovce ${data['usi_cislo']}: $e');
        }
      }

      print('🎉 Import dokončen! Úspěšně: $uspesne');

      // Zobrazit výsledek
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Import dokončen! Přidáno $uspesne ovcí'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      print('💥 CHYBA při importu: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Chyba při importu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Dialog pro výběr způsobu přidání ovce
  Future<void> _showAddSheepOptions() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Přidat novou ovci'),
          content: const Text('Jak chcete přidat novou ovci?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Zrušit'),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pop(context, 'manual'),
              icon: const Icon(Icons.edit),
              label: const Text('Ručně'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, 'detection'),
              icon: const Icon(Icons.camera_alt),
              label: const Text('S detekcí'),
            ),
          ],
        );
      },
    );

    if (choice == 'detection') {
      await _smartAddSheep();
    } else if (choice == 'manual') {
      await _manualAddSheep();
    }
  }

  /// Ruční přidání ovce - přímo do formuláře
  Future<void> _manualAddSheep() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NovaOvceScreen(
          onSave: (ovce) async {
            try {
              await _ovceService.initialize();
              await _ovceService.addOvce(ovce);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Ovce byla úspěšně přidána'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Přejít zpět na home screen
                setState(() {
                  _currentIndex = 0;
                });
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Chyba: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  /// Smart přidávání ovce - spustí detekci, udělá fotku, pak formulář
  Future<void> _smartAddSheep() async {
    try {
      // Zobrazit loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Spouštím detekci...'),
              ],
            ),
          );
        },
      );

      // Přejít na live detekci a počkat na výsledek
      Navigator.pop(context); // Zavřít loading dialog
      
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (context) => LiveDetekceScreen(
            isSmartAddMode: true, // Speciální režim pro přidávání
          ),
        ),
      );

      if (result != null) {
        // Pokud máme data z detekce, přejdeme na formulář
        final detectedData = result['detectedData'] as Map<String, dynamic>?;
        final photoPath = result['photoPath'] as String?;

        // Přejít na formulář s předvyplněnými daty
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NovaOvceScreen(
              initialData: detectedData,
              initialPhotoPath: photoPath,
              onSave: (ovce) async {
                try {
                  await _ovceService.initialize();
                  await _ovceService.addOvce(ovce);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Ovce byla úspěšně přidána'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Přejít zpět na home screen
                    setState(() {
                      _currentIndex = 0;
                    });
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Chyba: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Zavřít loading dialog pokud je otevřený
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Chyba při spouštění detekce: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}