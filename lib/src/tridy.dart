/// Reprezentuje jedno jídlo z jídelníčku
class Jidlo {
  /// Název jídla
  String nazev;

  /// Objednal si uživatel toto jídlo?
  bool objednano;

  /// Název varianty
  String varianta;

  /// Cena
  double? cena;

  ///Lze objednat?
  bool lzeObjednat;

  /// Je jídlo aktuálně na burze?
  bool naBurze;

  /// Den, který je jídlo vydáváno
  DateTime den;

  /// URL pro požadavek na objednání jídla
  final String? orderUrl;

  /// URL pro vložení jídla na burzu
  final String? burzaUrl;
  Jidlo(
      {required this.nazev,
      required this.objednano,
      required this.varianta,
      required this.den,
      this.cena,
      required this.lzeObjednat,
      this.orderUrl,
      this.burzaUrl,
      required this.naBurze});
}

/// Reprezentuje cizí jídlo na burze
class Burza {
  /// Den, který je jídlo vydáváno
  DateTime den;

  /// URL pro objednání
  final String? url;

  /// Název jídla
  String jidlo;

  /// Varianta
  String? varianta;

  /// Počet kusů tohoto jídla dostupného na burze
  int pocet;

  Burza(
      {required this.den,
      required this.url,
      required this.jidlo,
      required this.pocet,
      this.varianta});
}

/// Reprezentuje jídelníček pro jeden den
class Jidelnicek {
  /// Den, pro který je jídelníček zveřejněn
  DateTime den;

  /// Seznam jídel
  List<Jidlo> jidla;
  Jidelnicek(this.den, this.jidla);
}

/// Reprezentuje informace o přihlášeném uživateli
class Uzivatel {
  /// Uživatelské jméno
  String? uzivatelskeJmeno;

  /// Jméno, jak je uvedené v základních údajích o uživateli
  String? jmeno;

  /// Příjmení, jak je uvedené v základních údajích o uživateli
  String? prijmeni;

  /// Kategorie uživatele
  String? kategorie;

  /// Účet jídelny pro zasílání plateb
  String? ucetProPlatby;

  /// Variabilní symbol
  String? varSymbol;

  /// Specifický symbol
  String? specSymbol;

  /// Aktuální stav kreditu
  double kredit;

  Uzivatel(
      {this.uzivatelskeJmeno,
      this.jmeno,
      this.prijmeni,
      this.kategorie,
      this.ucetProPlatby,
      this.varSymbol,
      this.kredit = 0.0,
      this.specSymbol});
}
