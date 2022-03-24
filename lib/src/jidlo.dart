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

  /// Den, který je jídlo vydáváno
  DateTime den;

  /// URL pro požadavek na objednání jídla
  final String? orderUrl;

  /// URL pro vložení jídla na burzu
  final String? burzaUrl;
  Jidlo(
      {required this.nazev,
      required this.objednano,
      required this.cislo,
      required this.den,
      this.cena,
      required this.lzeObjednat,
      this.orderUrl,
      this.burzaUrl});
}

/// Reprezentuje jídelníček pro jeden dan
class Jidelnicek {
  /// Den, pro který je jídelníček zveřejněn
  DateTime den;

  /// Seznam jídel
  List<Jidlo> jidla;
  Jidelnicek(this.den, this.jidla);
}
