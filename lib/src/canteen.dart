import 'package:http/http.dart' as http;

import 'tridy.dart';

/*
 MIT License

Copyright (c) 2022 Matyáš Caras and contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

/// Reprezentuje kantýnu
///
/// **Všechny metody v případě chyby vrací [Future] s chybovou hláškou.**
class Canteen {
  /// Adresa kantýny
  String url;

  /// Sušenky potřebné pro komunikaci
  Map<String, String> cookies = {"JSESSIONID": "", "XSRF-TOKEN": ""};

  /// Je uživatel přihlášen?
  bool prihlasen = false;
  Canteen(this.url);

  /// Vrátí informace o uživateli ve formě instance [Uzivatel]
  Future<Uzivatel> ziskejUzivatele() async {
    if (!prihlasen) return Future.error("Uživatel není přihlášen");
    var r = await _getRequest("/web/setting");
    if (r.contains("přihlášení uživatele")) {
      prihlasen = false;
      return Future.error("Uživatel není přihlášen");
    }
    var m = double.tryParse(RegExp(r' +<span id="Kredit" .+?>(.+?)(?=&)')
        .firstMatch(r)!
        .group(1)!
        .replaceAll(",", ".")
        .replaceAll(RegExp(r"[^\w.]"), ""));
    var jmenoMatch = RegExp(r'(?<=jméno: <b>).+?(?=<\/b)').firstMatch(r);
    var prijmeniMatch = RegExp(r'(?<=příjmení: <b>).+?(?=<\/b)').firstMatch(r);
    var kategorieMatch =
        RegExp(r'(?<=kategorie: <b>).+?(?=<\/b)').firstMatch(r);
    var ucetMatch = RegExp(r'(?<=účet pro platby do jídelny: <b>).+?(?=<\/b)')
        .firstMatch(r);
    var varMatch =
        RegExp(r'(?<=variabilní symbol: <b>).+?(?=<\/b)').firstMatch(r);
    var specMatch =
        RegExp(r'(?<=specifický symbol: <b>).+?(?=<\/b)').firstMatch(r);

    var jmeno = jmenoMatch?.group(0) ?? "";
    var prijmeni = prijmeniMatch?.group(0) ?? "";
    var kategorie = kategorieMatch?.group(0) ?? "";
    var ucet = ucetMatch?.group(0) ?? "";
    var varSymbol = varMatch?.group(0) ?? "";
    var specSymbol = specMatch?.group(0) ?? "";

    return Uzivatel(
        jmeno: jmeno,
        prijmeni: prijmeni,
        kategorie: kategorie,
        ucetProPlatby: ucet,
        varSymbol: varSymbol,
        specSymbol: specSymbol,
        kredit: m ?? 0.0);
  }

  Future<void> _getFirstSession() async {
    if (url.endsWith("/")) {
      url = url.substring(0, url.length - 1);
    } // odstranit lomítko
    var res = await http.get(Uri.parse(url));
    _parseCookies(res.headers['set-cookie']!);
  }

  /// Převede cookie řetězec z požadavku do mapy
  void _parseCookies(String cookieString) {
    Map<String, String> cookies = this.cookies;
    var regCookie = RegExp(r'([A-Z\-]+=.+?(?=;))|(remember-me=.+?)(?=;)')
        .allMatches(cookieString)
        .toList();
    for (var cook in regCookie) {
      var c = cook.group(0).toString().split("=");
      cookies[c[0]] = c[1];
    }
  }

  /// Přihlášení do iCanteen
  ///
  /// Vstup:
  ///
  /// - `user` - uživatelské jméno | [String]
  /// - `password` - heslo | [String]
  ///
  /// Výstup:
  /// - [bool] ve [Future], v případě přihlášení `true`, v případě špatného hesla `false`
  Future<bool> login(String user, String password) async {
    if (cookies["JSESSIONID"] == "" || cookies["XSRF-TOKEN"] == "") {
      await _getFirstSession();
    }
    var res =
        await http.post(Uri.parse(url + "/j_spring_security_check"), headers: {
      "Cookie": "JSESSIONID=" +
          cookies["JSESSIONID"]! +
          "; " +
          "XSRF-TOKEN=" +
          cookies["XSRF-TOKEN"]! +
          ";",
      "Content-Type": "application/x-www-form-urlencoded",
    }, body: {
      "j_username": user,
      "j_password": password,
      "terminal": "false",
      "_csrf": cookies["XSRF-TOKEN"],
      "_spring_security_remember_me": "on",
      "targetUrl":
          "/faces/secured/main.jsp?terminal=false&status=true&printer=&keyboard="
    });
    if (res.headers['set-cookie']!.contains("remember-me=;")) {
      return false; // špatné heslo
    }
    if (res.statusCode != 302) {
      return Future.error("Chyba: ${res.body}");
    }
    _parseCookies(res.headers['set-cookie']!);

    prihlasen = true;
    return true;
  }

  /// Builder pro GET request
  Future<String> _getRequest(String path) async {
    var r = await http.get(Uri.parse(url + path), headers: {
      "Cookie": "JSESSIONID=" +
          cookies["JSESSIONID"]! +
          "; " +
          "XSRF-TOKEN=" +
          cookies["XSRF-TOKEN"]! +
          (cookies.containsKey("remember-me")
              ? "; " + cookies["remember-me"]! + ";"
              : ";"),
    });
    if (r.statusCode != 200) {
      return Future.error("Chyba: ${r.body}");
    }
    if (r.headers.containsKey("set-cookie")) {
      _parseCookies(r.headers["set-cookie"]!);
    }
    return r.body;
  }

  /// Získá jídelníček bez cen
  ///
  /// Výstup:
  /// - [List] s [Jidelnicek], který neobsahuje ceny
  ///
  /// __Lze použít bez přihlášení__
  Future<List<Jidelnicek>> ziskejJidelnicek() async {
    var res = await _getRequest("/");
    var reg = RegExp(
            r'((?=<div class="jidelnicekDen">).+?(?=<div class="jidelnicekDen">))|((?=<div class="jidelnicekDen">).*<\/span>)',
            dotAll: true)
        .allMatches(res)
        .toList();
    List<Jidelnicek> jidelnicek = [];
    for (var t in reg) {
      // projedeme každý den individuálně
      var j = t
              .group(0)
              .toString() /*.replaceAll(RegExp(r'(   )+|([^>a-z]\n)'),
          '')*/
          ; // převedeme text na něco přehlednějšího
      var den = DateTime.parse(RegExp(r'(?<=day-).+?(?=")', dotAll: true)
          .firstMatch(j)!
          .group(0)
          .toString());
      var jidlaDenne = RegExp(
              r'(?=<div class="container">).+?<\/div>.+?(?=<\/div>)',
              dotAll: true)
          .allMatches(j)
          .toList(); // získáme jednotlivá jídla pro den / VERZE 2.18
      if (jidlaDenne.isEmpty) {
        jidlaDenne = RegExp(
                r'(?=<div style="padding: 2 0 2 20">).+?(?=<\/div>)',
                dotAll: true)
            .allMatches(j)
            .toList(); // získáme jednotlivá jídla pro den / VERZE 2.10
      }

      List<Jidlo> jidla = [];
      for (var jidloNaDen in jidlaDenne) {
        // projedeme vsechna jidla
        var s = jidloNaDen.group(0)!.replaceAll(
            RegExp(
                r'[a-zA-ZěščřžýáíéÉÍÁÝŽŘČŠĚŤŇťň.,:]  [a-zA-ZěščřžýáíéÉÍÁÝŽŘČŠĚŤŇťň.,:]'),
            ''); // odstraní dvojté mezery mezi písmeny
        var vydejna = RegExp(r'(?<=<span style="color: #1b75bb;">).+?(?=<)')
            .firstMatch(s); // název výdejny / verze 2.18
        vydejna ??= RegExp(
                // TODO: Lepší systém pro podporu různých verzí iCanteen
                r'(?<=<span class="smallBoldTitle" style="color: #1b75bb;">).+?(?=<)')
            .firstMatch(s); // název výdejny / verze 2.10
        var hlavni = RegExp(
                r' {20}(([a-zA-ZěščřžýáíéÉÍÁÝŽŘČŠĚŤŇťň.,:\/]+ )+[a-zA-ZěščřžýáíéÉÍÁÝŽŘČŠĚŤŇťň.,:\/]+)',
                dotAll: true)
            .firstMatch(s)!
            .group(1)
            .toString(); // Jídlo
        jidla.add(Jidlo(
            nazev: hlavni,
            objednano: false,
            varianta: vydejna!.group(0).toString(),
            lzeObjednat: false,
            den: den,
            naBurze: false));
      }
      jidelnicek.add(Jidelnicek(den, jidla));
    }
    return jidelnicek;
  }

  /// Získá jídlo pro daný den
  ///
  /// __Vyžaduje přihlášení pomocí [login]__
  ///
  /// Vstup:
  /// - `den` - *volitelné*, určuje pro jaký den chceme získat jídelníček | [DateTime]
  ///
  /// Výstup:
  /// - [Jidelnicek] obsahující detaily, které vidí přihlášený uživatel
  Future<Jidelnicek> jidelnicekDen({DateTime? den}) async {
    if (!prihlasen) {
      return Future.error("Uživatel není přihlášen");
    }
    den ??= DateTime.now();
    var res = await _getRequest(
        "/faces/secured/main.jsp?day=${den.year}-${(den.month < 10) ? "0" + den.month.toString() : den.month}-${(den.day < 10) ? "0" + den.day.toString() : den.day}&terminal=false&printer=false&keyboard=false");
    if (res.contains("<title>iCanteen - přihlášení uživatele</title>")) {
      prihlasen = false;
      return Future.error("Uživatel není přihlášen");
    }
    var obedDen = DateTime.parse(RegExp(r'(?<=day-).+?(?=")', dotAll: true)
        .firstMatch(res)!
        .group(0)
        .toString());
    var jidla = <Jidlo>[];
    var jidelnicek = RegExp(
            r'((?<=<div class="jidWrapLeft">).+?((?=<br>)|(do burzy)))',
            dotAll: true)
        .allMatches(res)
        .toList();
    for (var obed in jidelnicek) {
      // formátování do třídy
      var o = obed
          .group(0)
          .toString()
          .replaceAll(RegExp(r'(   )+|([^>a-z]\n)'), '');
      var objednano = o.contains("Máte objednáno");
      var lzeObjednat =
          !(o.contains("nelze zrušit") || o.contains("nelze objednat"));
      var cenaMatch =
          RegExp(r'(?<=Cena objednaného jídla">).+?(?=&)').firstMatch(o);
      cenaMatch ??=
          RegExp(r'(?<=Cena při objednání jídla:&nbsp;).+?(?=&)').firstMatch(o);
      cenaMatch ??=
          RegExp(r'(?<=Cena při objednání jídla">).+?(?=&)').firstMatch(o);
      var cena =
          double.parse(cenaMatch!.group(0).toString().replaceAll(",", "."));
      var jidlaProDen = RegExp(r'(?<=Polévka: ).+')
          .firstMatch(o)!
          .group(0)
          .toString()
          .split(" / ");
      var vydejna = RegExp(
              r'(?<=<span class="smallBoldTitle button-link-align">).+?(?=<)')
          .firstMatch(o)!
          .group(0)
          .toString();
      String? orderUrl;
      String? burzaUrl;
      if (lzeObjednat) {
        // pokud lze objednat, nastavíme adresu pro objednání
        var match = RegExp(r"(?<=ajaxOrder\(this, ').+?(?=')").firstMatch(o);
        if (match != null) {
          orderUrl = match.group(0)!.replaceAll("amp;", "");
        }
      } else {
        // jinak nastavíme URL pro burzu
        var match = RegExp(r"(?<=ajaxOrder\(this, ')(.+?)(?=').+?do burzy")
            .firstMatch(o);
        if (match != null) {
          burzaUrl = match.group(1)!.replaceAll("amp;", "");
        }
      }
      jidla.add(Jidlo(
          nazev: jidlaProDen[1]
              .replaceAll(r' (?=[^a-zA-ZěščřžýáíéĚŠČŘŽÝÁÍÉŤŇťň])', ''),
          objednano: objednano,
          varianta: vydejna,
          lzeObjednat: lzeObjednat,
          cena: cena,
          orderUrl: orderUrl,
          den: obedDen,
          burzaUrl: burzaUrl,
          naBurze:
              (burzaUrl == null) ? false : !burzaUrl.contains("plusburza")));
      // KONEC formátování do třídy
    }

    return Jidelnicek(obedDen, jidla);
  }

  /// Objedná vybrané jídlo
  ///
  /// Vstup:
  /// - `j` - Jídlo, které chceme objednat | [Jidlo]
  ///
  /// Výstup:
  /// - Upravená instance [Jidlo] tohoto jídla
  Future<Jidlo> objednat(Jidlo j) async {
    if (!prihlasen) {
      return Future.error("Uživatel není přihlášen");
    }
    if (!j.lzeObjednat || j.orderUrl == null || j.orderUrl!.isEmpty) {
      return Future.error(
          "Jídlo nelze objednat nebo nemá adresu pro objednání");
    }
    var res =
        await _getRequest("/faces/secured/" + j.orderUrl!); // provést operaci
    if (res.contains("Chyba")) {
      return Future.error("Při požadavku došlo k chybě");
    }
    if (res.contains("přihlášení uživatele")) {
      prihlasen = false;
      return Future.error("Uživatel není přihlášen");
    }

    var novy = await _getRequest(
        "/faces/secured/db/dbJidelnicekOnDayView.jsp?day=${j.den.year}-${(j.den.month < 10) ? "0" + j.den.month.toString() : j.den.month}-${(j.den.day < 10) ? "0" + j.den.day.toString() : j.den.day}&terminal=false&rating=null&printer=false&keyboard=false"); // získat novou URL pro objednávání
    var lzeObjednat =
        !(novy.contains("nelze zrušit") || novy.contains("nelze objednat"));
    String? orderUrl;
    String? burzaUrl;

    if (lzeObjednat) {
      // pokud lze objednat, nastavíme adresu pro objednání
      var match = RegExp(r"(?<=ajaxOrder\(this, ').+?(?=')").firstMatch(novy);
      if (match != null) {
        orderUrl = match.group(0)!.replaceAll("amp;", "");
      }
    } else {
      // jinak nastavíme URL pro burzu
      var match = RegExp(r"(?<=ajaxOrder\(this, ')(.+?)(?=').+?do burzy")
          .firstMatch(novy);
      if (match != null) {
        burzaUrl = match.group(1)!.replaceAll("amp;", "");
      }
    }

    return Jidlo(
        varianta: j.varianta,
        nazev: j.nazev,
        objednano: !j.objednano,
        cena: j.cena,
        lzeObjednat: j.lzeObjednat,
        orderUrl: orderUrl,
        den: j.den,
        burzaUrl: burzaUrl,
        naBurze: (burzaUrl == null)
            ? false
            : !burzaUrl.contains("plusburza")); // vrátit upravenou instanci
  }

  /// Uloží vaše jídlo z/do burzy
  ///
  /// Vstup:
  /// - `j` - Jídlo, které chceme dát/vzít do/z burzy | [Jidlo]
  ///
  /// Výstup:
  /// - Upravená instance [Jidlo] tohoto jídla
  Future<Jidlo> doBurzy(Jidlo j) async {
    if (!prihlasen) {
      return Future.error("Uživatel není přihlášen");
    }
    if (j.burzaUrl == null || j.burzaUrl!.isEmpty) {
      return Future.error(
          "Jídlo nelze uložit do burzy nebo nemá adresu pro uložení");
    }
    var res =
        await _getRequest("/faces/secured/" + j.burzaUrl!); // provést operaci
    if (res.contains("Chyba")) return j;
    if (res.contains("přihlášení uživatele")) {
      prihlasen = false;
      return Future.error("Uživatel není přihlášen");
    }

    var novy = await _getRequest(
        "/faces/secured/db/dbJidelnicekOnDayView.jsp?day=${j.den.year}-${(j.den.month < 10) ? "0" + j.den.month.toString() : j.den.month}-${(j.den.day < 10) ? "0" + j.den.day.toString() : j.den.day}&terminal=false&rating=null&printer=false&keyboard=false"); // získat novou URL pro objednávání
    var lzeObjednat =
        !(novy.contains("nelze zrušit") || novy.contains("nelze objednat"));
    String? orderUrl;
    String? burzaUrl;

    if (lzeObjednat) {
      // pokud lze objednat, nastavíme adresu pro objednání
      var match = RegExp(r"(?<=ajaxOrder\(this, ').+?(?=')").firstMatch(novy);
      if (match != null) {
        orderUrl = match.group(0)!.replaceAll("amp;", "");
      }
    } else {
      // jinak nastavíme URL pro burzu
      var match = RegExp(r"(?<=ajaxOrder\(this, ')(.+?)(?=').+?do burzy")
          .firstMatch(novy);
      if (match != null) {
        burzaUrl = match.group(1)!.replaceAll("amp;", "");
      }
    }

    return Jidlo(
        varianta: j.varianta,
        nazev: j.nazev,
        objednano: !j.objednano,
        cena: j.cena,
        lzeObjednat: j.lzeObjednat,
        orderUrl: orderUrl,
        den: j.den,
        burzaUrl: burzaUrl,
        naBurze: (burzaUrl == null)
            ? false
            : !burzaUrl.contains("plusburza")); // vrátit upravenou instanci
  }

  /// Získá aktuální jídla v burze
  ///
  /// Výstup:
  /// - List instancí [Burza], každá obsahuje informace o jídle v burze
  Future<List<Burza>> ziskatBurzu() async {
    if (!prihlasen) return Future.error("Uživatel není přihlášen");
    List<Burza> burza = [];
    var r = await _getRequest("/faces/secured/burza.jsp");
    if (r.contains("Chyba")) return Future.error("Při požadavku došlo k chybě");
    if (r.contains("přihlášení uživatele")) {
      prihlasen = false;
      return Future.error("Uživatel není přihlášen");
    }
    var dostupnaJidla =
        RegExp(r'(?<=<tr class="mouseOutRow">).+?(?=<\/tr>)', dotAll: true)
            .allMatches(r); // vyfiltrujeme jednotlivá jídla
    if (dostupnaJidla.isNotEmpty) {
      for (var burzaMatch in dostupnaJidla) {
        var bu = burzaMatch.group(0)!;
        var data = RegExp(
                r'((?<=<td>).+?(?=<))|(?<=<td align="left">).+?(?=<)|((?<=<td align="right">).+?(?=<))',
                dotAll: true)
            .allMatches(bu)
            .toList();
        // Získat datum
        var datumRaw = RegExp(r'\d\d\.\d\d\.\d{4}')
            .firstMatch(data[1].group(0)!)!
            .group(0)!
            .split(".");
        var datum =
            DateTime.parse("${datumRaw[2]}-${datumRaw[1]}-${datumRaw[0]}");
        // Získat variantu
        var varianta = data[0].group(0)!;
        // Získat název jídla
        var nazev = data[2].group(0)!.replaceAll(RegExp(r'\n|  '), "");
        // Získat počet kusů
        var pocet = int.parse(data[3].group(0)!.replaceAll(" ks", ""));
        var url = RegExp(r"(?<=')db.+?(?=')").firstMatch(bu)!.group(0)!;
        var jidlo = Burza(
            den: datum,
            varianta: varianta,
            nazev: nazev,
            pocet: pocet,
            url: url);
        burza.add(jidlo);
      }
    }
    return burza;
  }

  /// Objedná jídlo z burzy pomocí URL z instance třídy Burza
  ///
  /// Vstup:
  /// - `b` - Jídlo __z burzy__, které chceme objednat | [Burza]
  ///
  /// Výstup:
  /// - [bool], `true`, pokud bylo jídlo úspěšně objednáno z burzy, jinak `false`
  Future<bool> objednatZBurzy(Burza b) async {
    var res = await _getRequest("/faces/secured/" + b.url!);
    if (res.contains("Chyba")) return false;
    return true;
  }
}
