import 'dart:io';

import 'package:flutter/material.dart';
import '../models/ovce.dart';
import '../services/ovce_service.dart';
import 'nova_ovce_screen.dart';

class DetailOvceScreen extends StatefulWidget {
  final Ovce ovce;

  const DetailOvceScreen({super.key, required this.ovce});

  @override
  State<DetailOvceScreen> createState() => _DetailOvceScreenState();
}

class _DetailOvceScreenState extends State<DetailOvceScreen> {
  final OvceService _ovceService = OvceService();
  late Ovce _aktualizovanaOvce;

  @override
  void initState() {
    super.initState();
    _aktualizovanaOvce = widget.ovce;
    print('🏠 DetailOvceScreen initState - ušní číslo: ${_aktualizovanaOvce.usiCislo}');
    print('🏠 DetailOvceScreen initState - počet fotek: ${_aktualizovanaOvce.fotky.length}');
    for (int i = 0; i < _aktualizovanaOvce.fotky.length; i++) {
      print('🏠 Fotka $i: ${_aktualizovanaOvce.fotky[i]}');
      print('🏠 Fotka $i existuje: ${File(_aktualizovanaOvce.fotky[i]).existsSync()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail ovce ${_aktualizovanaOvce.usiCislo}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.of(context).push<Ovce?>(
                MaterialPageRoute(
                  builder: (context) => NovaOvceScreen(
                    ovce: _aktualizovanaOvce,
                    onSave: (editovanaOvce) async {
                      try {
                        await _ovceService.updateOvce(_aktualizovanaOvce.usiCislo, editovanaOvce);
                        
                        // Znovu načteme aktualizovaná data z repository
                        final aktualizovanaOvceZRepo = _ovceService.getAllOvce()
                            .firstWhere((o) => o.usiCislo == editovanaOvce.usiCislo);
                        
                        print('🔄 Po aktualizaci - ušní číslo: ${aktualizovanaOvceZRepo.usiCislo}');
                        print('🔄 Po aktualizaci - počet fotek: ${aktualizovanaOvceZRepo.fotky.length}');
                        for (int i = 0; i < aktualizovanaOvceZRepo.fotky.length; i++) {
                          print('🔄 Fotka $i: ${aktualizovanaOvceZRepo.fotky[i]}');
                          print('🔄 Fotka $i existuje: ${File(aktualizovanaOvceZRepo.fotky[i]).existsSync()}');
                        }
                        
                        setState(() {
                          _aktualizovanaOvce = aktualizovanaOvceZRepo;
                        });
                        
                        print('🔄 setState dokončen - fotky v UI: ${_aktualizovanaOvce.fotky.length}');
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ovce byla úspěšně aktualizována')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Chyba při aktualizaci: ${e.toString()}')),
                          );
                        }
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fotky
            if (_aktualizovanaOvce.fotky.isNotEmpty) ...[
              const Text(
                'Fotky',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Počet fotek: ${_aktualizovanaOvce.fotky.length}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _aktualizovanaOvce.fotky.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: GestureDetector(
                          onTap: () {
                            // Zobrazit foto na celou obrazovku
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                child: Container(
                                  width: double.infinity,
                                  height: 400,
                                  child: Image.file(
                                    File(_aktualizovanaOvce.fotky[index]),
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Chyba při načítání fotky: $error');
                                      print('Cesta k souboru: ${_aktualizovanaOvce.fotky[index]}');
                                      return Container(
                                        color: Colors.grey[300],
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.error, size: 50),
                                            const SizedBox(height: 8),
                                            Text('Chyba při načítání\n${_aktualizovanaOvce.fotky[index]}', 
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Image.file(
                            File(_aktualizovanaOvce.fotky[index]),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('Chyba při načítání fotky v detailu: $error');
                              print('Cesta k souboru: ${_aktualizovanaOvce.fotky[index]}');
                              print('Soubor existuje: ${File(_aktualizovanaOvce.fotky[index]).existsSync()}');
                              return Container(
                                color: Colors.grey[300],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.broken_image, size: 40),
                                    const SizedBox(height: 4),
                                    Text('Chyba', style: TextStyle(fontSize: 10)),
                                    Text('${index + 1}', style: TextStyle(fontSize: 8)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              const Text(
                'Fotky',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Žádné fotky\nPřidejte fotky pomocí editace',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Informace o ovci
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Základní informace',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow('Ušní číslo:', _aktualizovanaOvce.usiCislo),
                    _buildInfoRow('Datum narození:', '${_aktualizovanaOvce.datumNarozeni.day}.${_aktualizovanaOvce.datumNarozeni.month}.${_aktualizovanaOvce.datumNarozeni.year}'),
                    _buildInfoRow('Věk:', '${_aktualizovanaOvce.vek} let'),
                    _buildInfoRow('Plemeno:', _aktualizovanaOvce.plemeno),
                    _buildInfoRow('Kategorie:', _aktualizovanaOvce.kategorie),
                    _buildInfoRow('Pohlaví:', _aktualizovanaOvce.pohlavi),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rodokmen',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow('Matka:', _aktualizovanaOvce.matka.isEmpty ? 'Neznámá' : _aktualizovanaOvce.matka),
                    _buildInfoRow('Otec:', _aktualizovanaOvce.otec.isEmpty ? 'Neznámý' : _aktualizovanaOvce.otec),
                    _buildInfoRow('Číslo matky:', _aktualizovanaOvce.cisloMatky),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            if (_aktualizovanaOvce.poznamka.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Poznámka',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(_aktualizovanaOvce.poznamka),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Registrace',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow('Datum registrace:', '${_aktualizovanaOvce.datumRegistrace.day}.${_aktualizovanaOvce.datumRegistrace.month}.${_aktualizovanaOvce.datumRegistrace.year}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
