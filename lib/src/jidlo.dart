/// Reprezentuje jedno jídlo z jídelníčku
class Jidlo {
  /// Název jídla
  String nazev;

  /// Objednal si uživatel toto jídlo?
  bool objednano;

  /// Název výdejny
  String cislo;

  /// Cena
  double? cena;

  ///Lze objednat?
  bool lzeObjednat;
  final String? orderUrl;
  Jidlo(
      {required this.nazev,
      required this.objednano,
      required this.cislo,
      this.cena,
      required this.lzeObjednat,
      this.orderUrl});
}

/// Reprezentuje jídelníček pro jeden dan
class Jidelnicek {
  /// Den, pro který je jídelníček zveřejněn
  DateTime den;

  /// Seznam jídel
  List<Jidlo> jidla;
  Jidelnicek(this.den, this.jidla);
}
