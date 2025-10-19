import '../models/ovce.dart';

class OvceRepository {
  static final List<Ovce> _ovce = [
    Ovce(
      usiCislo: "006078035",
      datumNarozeni: DateTime(2020, 10, 3),
      matka: "",
      otec: "samec",
      plemeno: "BER",
      kategorie: "beran",
      cisloMatky: "CZ20000039107",
      pohlavi: "beran",
      datumRegistrace: DateTime(2020, 10, 3),
      fotky: [], // Prázdný seznam fotek
    ),
    Ovce(
      usiCislo: "015248635", 
      datumNarozeni: DateTime(2018, 2, 24),
      matka: "",
      otec: "samice",
      plemeno: "BAH",
      kategorie: "beran",
      cisloMatky: "CZ200000020935",
      pohlavi: "beran",
      datumRegistrace: DateTime(2018, 2, 24),
      fotky: [], // Prázdný seznam fotek
    ),
  ];

  List<Ovce> getAllOvce() {
    return List.from(_ovce);
  }

  Future<void> addOvce(Ovce ovce) async {
    _ovce.add(ovce);
  }

  Future<bool> updateOvce(String puvodniUsiCislo, Ovce novaOvce) async {
    final index = _ovce.indexWhere((ovce) => ovce.usiCislo == puvodniUsiCislo);
    if (index != -1) {
      _ovce[index] = novaOvce;
      return true;
    }
    return false;
  }

  Ovce? findByUsiCislo(String usiCislo) {
    try {
      return _ovce.firstWhere((ovce) => ovce.usiCislo == usiCislo);
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteOvce(String usiCislo) async {
    _ovce.removeWhere((ovce) => ovce.usiCislo == usiCislo);
  }

  Map<String, int> getStatistiky() {
    return {
      'celkem': _ovce.length,
      'berani': _ovce.where((ovce) => ovce.pohlavi == 'beran').length,
      'ovce': _ovce.where((ovce) => ovce.pohlavi == 'ovce').length,
    };
  }
}
