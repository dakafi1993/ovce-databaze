import '../models/ovce.dart';
import '../repositories/ovce_repository.dart';

// Service vrstva pro business logiku týkající se ovcí
class OvceService {
  final OvceRepository _repository = OvceRepository();

  // Získat všechny ovce
  List<Ovce> getAllOvce() {
    return _repository.getAllOvce();
  }

  // Přidat novou ovci s validací
  Future<bool> addOvce(Ovce ovce) async {
    // Validace - kontrola, zda už neexistuje ovce se stejným ušním číslem
    if (_repository.findByUsiCislo(ovce.usiCislo) != null) {
      throw Exception('Ovce s ušním číslem ${ovce.usiCislo} již existuje');
    }

    // Validace povinných polí
    if (ovce.usiCislo.isEmpty) {
      throw Exception('Ušní číslo je povinné');
    }
    
    if (ovce.plemeno.isEmpty) {
      throw Exception('Plemeno je povinné');
    }

    _repository.addOvce(ovce);
    return true;
  }

  // Aktualizovat existující ovci
  Future<bool> updateOvce(String puvodniUsiCislo, Ovce novaOvce) async {
    // Pokud se změnilo ušní číslo, zkontrolovat, zda nové neexistuje
    if (puvodniUsiCislo != novaOvce.usiCislo) {
      if (_repository.findByUsiCislo(novaOvce.usiCislo) != null) {
        throw Exception('Ovce s ušním číslem ${novaOvce.usiCislo} již existuje');
      }
    }

    return _repository.updateOvce(puvodniUsiCislo, novaOvce);
  }

  // Smazat ovci
  Future<bool> deleteOvce(String usiCislo) async {
    await _repository.deleteOvce(usiCislo);
    return true;
  }

  // Vyhledat ovci podle ušního čísla
  Ovce? findOvce(String usiCislo) {
    return _repository.findByUsiCislo(usiCislo);
  }

  // Vyhledat ovce podle kritérií
  List<Ovce> searchOvce({
    String? plemeno,
    String? kategorie,
    String? pohlavi,
  }) {
    List<Ovce> vysledek = _repository.getAllOvce();

    if (plemeno != null && plemeno.isNotEmpty) {
      vysledek = vysledek.where((ovce) => 
        ovce.plemeno.toLowerCase().contains(plemeno.toLowerCase())).toList();
    }

    if (kategorie != null && kategorie.isNotEmpty) {
      vysledek = vysledek.where((ovce) => 
        ovce.kategorie.toLowerCase().contains(kategorie.toLowerCase())).toList();
    }

    if (pohlavi != null && pohlavi.isNotEmpty) {
      vysledek = vysledek.where((ovce) => 
        ovce.pohlavi.toLowerCase().contains(pohlavi.toLowerCase())).toList();
    }

    return vysledek;
  }

  // Získat statistiky chovu
  Map<String, dynamic> getStatistiky() {
    final stats = Map<String, dynamic>.from(_repository.getStatistiky());
    final ovce = _repository.getAllOvce();
    
    // Přidat průměrný věk
    if (ovce.isNotEmpty) {
      final prumernyVek = ovce.map((o) => o.vek).reduce((a, b) => a + b) / ovce.length;
      stats['prumernyVek'] = prumernyVek.toStringAsFixed(1);
    } else {
      stats['prumernyVek'] = '0.0';
    }

    // Přidat nejstarší a nejmladší ovci
    if (ovce.isNotEmpty) {
      ovce.sort((a, b) => a.vek.compareTo(b.vek));
      stats['nejmladsi'] = ovce.first.usiCislo;
      stats['nejstarsi'] = ovce.last.usiCislo;
    }

    return stats;
  }

  // Validace údajů o ovci
  List<String> validateOvce(Ovce ovce) {
    final chyby = <String>[];

    if (ovce.usiCislo.isEmpty) {
      chyby.add('Ušní číslo je povinné');
    }

    if (ovce.plemeno.isEmpty) {
      chyby.add('Plemeno je povinné');
    }

    // Kontrola formátu ušního čísla (mělo by obsahovat pouze číslice)
    if (ovce.usiCislo.isNotEmpty && !RegExp(r'^\d+$').hasMatch(ovce.usiCislo)) {
      chyby.add('Ušní číslo smí obsahovat pouze číslice');
    }

    // Kontrola věku (musí být rozumný)
    if (ovce.vek < 0 || ovce.vek > 20) {
      chyby.add('Věk ovce musí být mezi 0 a 20 lety');
    }

    // Kontrola kategorie
    if (ovce.kategorie.isNotEmpty && !['BER', 'BAH', 'JEH', 'beran', 'ovce'].contains(ovce.kategorie)) {
      chyby.add('Neplatná kategorie. Povolené: BER, BAH, JEH, beran, ovce');
    }

    // Kontrola pohlaví
    if (ovce.pohlavi.isNotEmpty && !['beran', 'ovce'].contains(ovce.pohlavi)) {
      chyby.add('Pohlaví musí být "beran" nebo "ovce"');
    }

    return chyby;
  }
}