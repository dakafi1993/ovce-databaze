import 'package:flutter/material.dart';
import '../models/ovce.dart';
import '../services/ovce_service_api.dart';

// Data ovcí z registru podle dokumentu
class RegistrOvci {
  static final List<Map<String, dynamic>> ovceData = [
    // Podle dokumentu - první strana
    {'usi_cislo': '006178035', 'datum_narozeni': '10.03.2020', 'kategorie': 'samec', 'plemeno': 'BER'},
    {'usi_cislo': '023415035', 'datum_narozeni': '24.02.2019', 'kategorie': 'samice', 'plemeno': 'BAH'},
    {'usi_cislo': '020437635', 'datum_narozeni': '12.03.2019', 'kategorie': 'samice', 'plemeno': 'BAH'},
    {'usi_cislo': '020449035', 'datum_narozeni': '26.02.2019', 'kategorie': 'samice', 'plemeno': 'BAH'},
    {'usi_cislo': '025380035', 'datum_narozeni': '09.02.2025', 'kategorie': 'samec', 'plemeno': 'JEH'},
    {'usi_cislo': '025971635', 'datum_narozeni': '06.03.2022', 'kategorie': 'samice', 'plemeno': 'BAH'},
    {'usi_cislo': '025975635', 'datum_narozeni': '12.01.2020', 'kategorie': 'samice', 'plemeno': 'BAH'},
    {'usi_cislo': '027734035', 'datum_narozeni': '24.02.2025', 'kategorie': 'samec', 'plemeno': 'JEH'},
    {'usi_cislo': '027754035', 'datum_narozeni': '03.03.2025', 'kategorie': 'samec', 'plemeno': 'JEH'},
    {'usi_cislo': '027582635', 'datum_narozeni': '08.02.2025', 'kategorie': 'samec', 'plemeno': 'JEH'},
    {'usi_cislo': '030622635', 'datum_narozeni': '19.12.2020', 'kategorie': 'samice', 'plemeno': 'BAH'},
    {'usi_cislo': '030678635', 'datum_narozeni': '05.06.2021', 'kategorie': 'samice', 'plemeno': 'BAH'},
    {'usi_cislo': '030678935', 'datum_narozeni': '04.03.2022', 'kategorie': 'samice', 'plemeno': 'BAH'},
    {'usi_cislo': '030681835', 'datum_narozeni': '22.03.2020', 'kategorie': 'samice', 'plemeno': 'BAH'},
    {'usi_cislo': '030684035', 'datum_narozeni': '29.01.2021', 'kategorie': 'samice', 'plemeno': 'BAH'},
    {'usi_cislo': '030914635', 'datum_narozeni': '11.03.2020', 'kategorie': 'samice', 'plemeno': 'BAH'},
    {'usi_cislo': '030917335', 'datum_narozeni': '28.03.2023', 'kategorie': 'samice', 'plemeno': 'BAH'},
    {'usi_cislo': '030918615', 'datum_narozeni': '19.03.2022', 'kategorie': 'samice', 'plemeno': 'BAH'},
    {'usi_cislo': '030920635', 'datum_narozeni': '11.03.2023', 'kategorie': 'samice', 'plemeno': 'BAH'},
    {'usi_cislo': '042278935', 'datum_narozeni': '22.03.2023', 'kategorie': 'samice', 'plemeno': 'BAH'},
    {'usi_cislo': '042280935', 'datum_narozeni': '01.03.2024', 'kategorie': 'samice', 'plemeno': 'BAH'},
    {'usi_cislo': '042281935', 'datum_narozeni': '02.03.2024', 'kategorie': 'samice', 'plemeno': 'BAH'},
    {'usi_cislo': '046302935', 'datum_narozeni': '14.03.2025', 'kategorie': 'samice', 'plemeno': 'JEH'},
    {'usi_cislo': '046303935', 'datum_narozeni': '17.03.2025', 'kategorie': 'samice', 'plemeno': 'JEH'},
    {'usi_cislo': '046304935', 'datum_narozeni': '24.03.2024', 'kategorie': 'samice', 'plemeno': 'BAH'},
    {'usi_cislo': '046305935', 'datum_narozeni': '19.02.2025', 'kategorie': 'samice', 'plemeno': 'JEH'},
  ];

  static DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('.');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      print('Chyba při parsování data: $dateStr');
    }
    return DateTime.now();
  }

  static Future<void> pridejVsechnyOvce(BuildContext context) async {
    final ovceService = OvceService();
    int uspesne = 0;
    int chyby = 0;

    // Zobrazit progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Přidávám ovce z registru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Zpracovávám ${ovceData.length} záznamů...'),
          ],
        ),
      ),
    );

    for (final data in ovceData) {
      try {
        final ovce = Ovce(
          usiCislo: data['usi_cislo'],
          datumNarozeni: _parseDate(data['datum_narozeni']),
          matka: '', // Neznámo z dokumentu
          otec: '', // Neznámo z dokumentu
          plemeno: data['plemeno'],
          kategorie: data['kategorie'],
          cisloMatky: '',
          pohlavi: data['kategorie'] == 'samec' ? 'Samec' : 'Samice',
          poznamka: 'Importováno z registru ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
          datumRegistrace: DateTime.now(),
        );

        await ovceService.addOvce(ovce);
        uspesne++;
        print('✅ Přidána ovce: ${ovce.usiCislo}');
      } catch (e) {
        chyby++;
        print('❌ Chyba při přidávání ovce ${data['usi_cislo']}: $e');
      }
    }

    // Zavřít progress dialog
    Navigator.pop(context);

    // Zobrazit výsledek
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Import dokončen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ Úspěšně přidáno: $uspesne ovcí'),
            Text('❌ Chyby: $chyby'),
            SizedBox(height: 16),
            Text('Data byla uložena na Railway server!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}