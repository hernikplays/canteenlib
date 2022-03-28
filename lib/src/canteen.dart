import 'dart:io';

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
class Canteen {
  String url;
  Map<String, String> cookies = {"JSESSIONID": "", "XSRF-TOKEN": ""};
  bool prihlasen = false;
  Canteen(this.url);

  /// Vrátí informace o uživateli ve formě instance [Uzivatel]
  Future<Uzivatel> ziskejUzivatele() async {
    if (!prihlasen) throw Exception("Bez přihlášení");
    var r = await _getRequest("/web/setting");
    if (r == null) throw Exception("Při požadavku došlo k chybě");
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

  Future<void> getFirstSession() async {
    if (url.endsWith("/"))
      url = url.substring(0, url.length - 1); // odstranit lomítko
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
  /// `user` - uživatelské jméno
  /// `password` - heslo
  ///
  /// Vrátí `true`, když se uživatel přihlásil, v případě špatného hesla `false`
  /// V případě chyby na serveru vyhodí [Exception]
  Future<bool> login(String user, String password) async {
    if (cookies["JSESSIONID"] == "" || cookies["XSRF-TOKEN"] == "") {
      await getFirstSession();
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
      throw Exception("Chyba: ${res.body}");
    }
    _parseCookies(res.headers['set-cookie']!);

    prihlasen = true;
    return true;
  }

  /// Builder pro GET request
  /// V případě chyby na serveru (divný status kód) vyhodí [Exception]
  Future<String?> _getRequest(String path) async {
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
    if (r.statusCode != 302) {
      throw Exception("Chyba: ${r.body}");
    }
    if (r.headers.containsKey("set-cookie")) {
      _parseCookies(r.headers["set-cookie"]!);
    }
    return r.body;
  }

  /// Získá jídelníček bez cen
  /// **nevrací** ceny, ale umožňuje získat jídelníček bez přihlášení
  Future<List<Jidelnicek>> ziskejJidelnicek() async {
    var res = await _getRequest("/");
    var reg = RegExp(
            r'((?=<div class="jidelnicekDen">).+?(?=<div class="jidelnicekDen">))|((?=<div class="jidelnicekDen">).*<\/span>)',
            dotAll: true)
        .allMatches(res!)
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
            cislo: vydejna!.group(0).toString(),
            lzeObjednat: false,
            den: den,
            naBurze: false));
      }
      jidelnicek.add(Jidelnicek(den, jidla));
    }
    return jidelnicek;
  }

  /// Získá jídlo pro daný den
  /// Vyžaduje přihlášení pomocí [login]
  Future<Jidelnicek> jidelnicekDen({DateTime? den}) async {
    den ??= DateTime.now();
    var res = await _getRequest(
        "/faces/secured/main.jsp?day=${den.year}-${(den.month < 10) ? "0" + den.month.toString() : den.month}-${(den.day < 10) ? "0" + den.day.toString() : den.day}&terminal=false&printer=false&keyboard=false");
    if (res!.contains("<title>iCanteen - přihlášení uživatele</title>")) {
      prihlasen = false;
      throw Exception("Nepřihlášen");
    }
    var obedDen = DateTime.parse(RegExp(r'(?<=day-).+?(?=")', dotAll: true)
        .firstMatch(res)!
        .group(0)
        .toString());
    var jidla = <Jidlo>[];
    var jidelnicek =
        RegExp(r'(?<=<div class="jidWrapLeft">).+?(?=<br>)', dotAll: true)
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
          cislo: vydejna,
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
  /// Vrátí upravenou instanci [Jidlo], v případě chyby vrací originální
  Future<Jidlo> objednat(Jidlo j) async {
    if (!j.lzeObjednat || j.orderUrl == null || j.orderUrl!.isEmpty) {
      return j;
    }
    var res =
        await _getRequest("/faces/secured/" + j.orderUrl!); // provést operaci
    if (res == null || res.contains("Chyba")) return j;

    var novy = await _getRequest(
        "/faces/secured/db/dbJidelnicekOnDayView.jsp?day=${j.den.year}-${(j.den.month < 10) ? "0" + j.den.month.toString() : j.den.month}-${(j.den.day < 10) ? "0" + j.den.day.toString() : j.den.day}&terminal=false&rating=null&printer=false&keyboard=false"); // získat novou URL pro objednávání
    if (novy == null) return j;
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
        cislo: j.cislo,
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

  /// Uloží jídlo z/do burzy
  ///
  /// Vrací upravenou instanci [Jidlo], v případě chyby vrací originální
  Future<Jidlo> doBurzy(Jidlo j) async {
    if (j.burzaUrl == null || j.burzaUrl!.isEmpty) {
      return j;
    }
    var res =
        await _getRequest("/faces/secured/" + j.burzaUrl!); // provést operaci
    if (res == null || res.contains("Chyba")) return j;
    var novy = await _getRequest(
        "/faces/secured/db/dbJidelnicekOnDayView.jsp?day=${j.den.year}-${(j.den.month < 10) ? "0" + j.den.month.toString() : j.den.month}-${(j.den.day < 10) ? "0" + j.den.day.toString() : j.den.day}&terminal=false&rating=null&printer=false&keyboard=false"); // získat novou URL pro objednávání
    if (novy == null) return j;
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
        cislo: j.cislo,
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
}
