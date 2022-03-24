import 'dart:io';

import 'package:http/http.dart' as http;

import 'jidlo.dart';

/*
 (C) 2022 Matyáš Caras and contributors
 This library is released under the GNU LGPLv3 license.
  If you have not received the license with this library, you can view it here http://www.gnu.org/licenses/lgpl-3.0.txt
*/
class Canteen {
  final String url;
  Map<String, String> cookies = {"JSESSIONID": "", "XSRF-TOKEN": ""};
  double _kredit = 0.0;
  bool prihlasen = false;
  Canteen(this.url);

  /// Vrátí aktuální kredit ze serveru jako [double]. Jelikož je async, nejdřív [Future]
  ///
  /// Nastane-li chyba, vrací 0
  Future<double> ziskejKredit() async {
    if (!prihlasen) return 0.0;
    var r = await _getRequest("/faces/secured/main.jsp");
    if (r == null) return 0.0;
    File("./test.txt").writeAsStringSync(r);
    var m = double.tryParse(RegExp(r' +<span id="Kredit" .+?>(.+?)(?=&)')
        .firstMatch(r)!
        .group(1)!
        .replaceAll(",", ".")
        .replaceAll(RegExp(r"[^\w.]"), ""));
    if (m == null) return 0.0;
    _kredit = m;
    return _kredit;
  }

  Future<void> getFirstSession() async {
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
  /// Vrátí `true`, když se uživatel přihlásil, jinak `false`
  /// TODO: Házet chyby
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

    _parseCookies(res.headers['set-cookie']!);
    if (res.statusCode != 302) {
      print(res.body);
      print("ERROR");
    }
    prihlasen = true;
    return true;
  }

  /// Builder pro GET request
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
            den: den));
      }
      jidelnicek.add(Jidelnicek(den, jidla));
    }
    return jidelnicek;
  }

  /// Získá jídlo pro daný den
  /// Vyžaduje přihlášení pomocí [login]
  /// Aktuálně pouze dnešní den
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
          den: obedDen));
      // KONEC formátování do třídy
    }

    return Jidelnicek(obedDen, jidla);
  }

  /// Objedná vybrané jídlo
  /// Vrátí upravenou instanci [Jidlo], v případě chyby vrací originální
  Future<Jidlo> objednat(Jidlo j) async {
    //TODO
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
        burzaUrl: burzaUrl); // vrátit upravenou instanci
  }

  Future<Jidlo> doBurzy(Jidlo j) async {
    //TODO
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
        burzaUrl: burzaUrl); // vrátit upravenou instanci
  }
}
