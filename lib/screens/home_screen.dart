import 'dart:io';

import 'package:flutter/material.dart';
import '../models/ovce.dart';
import '../services/ovce_service_api.dart';
import '../services/pdf_export_service.dart';
import '../widgets/connection_status_widget.dart';
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
  List<Ovce> _ovce = [];
  List<Ovce> _filteredOvce = [];
  
  // Filtry
  String? _selectedKategorie;
  int? _selectedRok;
  int? _selectedMesic;
  
  // Dostupné hodnoty pro filtry
  final List<String> _kategorie = ['BER', 'BAH', 'JEH', 'OTHER'];
  final List<String> _mesice = [
    'Leden', 'Únor', 'Březen', 'Duben', 'Květen', 'Červen',
    'Červenec', 'Srpen', 'Září', 'Říjen', 'Listopad', 'Prosinec'
  ];

  @override
  void initState() {
    super.initState();
    _loadOvce();
  }

  void _loadOvce() async {
    try {
      print('🔄 HomeScreen: Spouštím načítání ovcí...');
      // Inicializujeme servis při prvním načtení
      await _ovceService.initialize();
      final ovce = await _ovceService.getAllOvce();
      print('🏠 HomeScreen: Načteno ${ovce.length} ovcí');
      for (var i = 0; i < ovce.length && i < 3; i++) {
        print('🐑 HomeScreen: Ovce ${i+1}: ${ovce[i].usiCislo} - ${ovce[i].plemeno} - ${ovce[i].kategorie}');
      }
      setState(() {
        _ovce = ovce;
        _applyFilters();
      });
    } catch (e) {
      print('❌ Chyba při načítání ovcí: $e');
      // Zůstane prázdný seznam
    }
  }

  // Debug funkce pro vymazání cache
  void _clearCacheAndReload() async {
    try {
      print('🧹 Mažu cache a načítám čerstvá data...');
      await _ovceService.clearCacheAndReload();
      _loadOvce();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache vymazána, data aktualizována')),
        );
      }
    } catch (e) {
      print('❌ Chyba při mazání cache: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba při mazání cache: $e')),
        );
      }
    }
  }

  /// Aplikuje filtry na seznam ovcí
  void _applyFilters() {
    _filteredOvce = _ovce.where((ovce) {
      // Filtr podle kategorie
      if (_selectedKategorie != null && ovce.kategorie != _selectedKategorie) {
        return false;
      }
      
      // Filtr podle roku narození
      if (_selectedRok != null && ovce.datumNarozeni.year != _selectedRok) {
        return false;
      }
      
      // Filtr podle měsíce narození  
      if (_selectedMesic != null && ovce.datumNarozeni.month != _selectedMesic) {
        return false;
      }
      
      return true;
    }).toList();
  }

  /// Resetuje všechny filtry
  void _resetFilters() {
    setState(() {
      _selectedKategorie = null;
      _selectedRok = null;
      _selectedMesic = null;
      _applyFilters();
    });
  }

  /// Získá dostupné roky narození z dat
  List<int> _getAvailableYears() {
    final years = _ovce.map((ovce) => ovce.datumNarozeni.year).toSet().toList();
    years.sort((a, b) => b.compareTo(a)); // Řazení sestupně
    return years;
  }

  /// Vytvoří dropdown widget pro filtry
  Widget _buildFilterDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required Function(T?) onChanged,
    String Function(T)? displayName,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<T>(
        hint: Text(label),
        value: value,
        underline: Container(),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(displayName?.call(item) ?? item.toString()),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
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
      // Použít filtrované ovce pro export
      final exportData = _filteredOvce.isNotEmpty ? _filteredOvce : _ovce;
      
      // Vytvořit popis filtrů pro PDF
      String filterInfo = 'Kompletní seznam';
      if (_filteredOvce.length != _ovce.length) {
        List<String> activeFilters = [];
        if (_selectedKategorie != null) activeFilters.add('Kategorie: $_selectedKategorie');
        if (_selectedRok != null) activeFilters.add('Rok: $_selectedRok');
        if (_selectedMesic != null) activeFilters.add('Měsíc: ${_mesice[_selectedMesic! - 1]}');
        filterInfo = 'Filtrováno: ${activeFilters.join(', ')} (${_filteredOvce.length} z ${_ovce.length})';
      }
      
      await _pdfExportService.exportOvceToPDF(
        exportData,
        action: action,
        customFileName: 'ovce_registr_${DateTime.now().day}_${DateTime.now().month}_${DateTime.now().year}.pdf',
        filterInfo: filterInfo,
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





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearCacheAndReload,
            tooltip: 'Vymazat cache a obnovit data',
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
            onPressed: _filteredOvce.isNotEmpty ? _showExportOptions : null,
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
          : Column(
              children: [
                // Filtry
                Container(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Filtr podle kategorie
                        _buildFilterDropdown<String>(
                          label: 'Kategorie',
                          value: _selectedKategorie,
                          items: _kategorie,
                          onChanged: (value) {
                            setState(() {
                              _selectedKategorie = value;
                              _applyFilters();
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        
                        // Filtr podle roku
                        _buildFilterDropdown<int>(
                          label: 'Rok',
                          value: _selectedRok,
                          items: _getAvailableYears(),
                          onChanged: (value) {
                            setState(() {
                              _selectedRok = value;
                              _applyFilters();
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        
                        // Filtr podle měsíce
                        _buildFilterDropdown<int>(
                          label: 'Měsíc',
                          value: _selectedMesic,
                          items: List.generate(12, (i) => i + 1),
                          displayName: (month) => _mesice[month - 1],
                          onChanged: (value) {
                            setState(() {
                              _selectedMesic = value;
                              _applyFilters();
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        
                        // Reset filtry
                        if (_selectedKategorie != null || _selectedRok != null || _selectedMesic != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: 'Resetovat filtry',
                            onPressed: _resetFilters,
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Počet výsledků
                if (_filteredOvce.length != _ovce.length)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.filter_list, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Zobrazeno ${_filteredOvce.length} z ${_ovce.length} ovcí',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                
                // Seznam ovcí
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredOvce.length,
                    itemBuilder: (context, index) {
                      final ovce = _filteredOvce[index];
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
                  ),
              ],
            ),
    );
  }
}
