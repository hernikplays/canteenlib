import 'package:canteenlib/canteenlib.dart';

void main(List<String> args) async {
  Canteen c = Canteen(
      "https://kantyna.neco.cz"); // vytvořit instanci kantýny, všechna komunikace probíhá skrz ni
  try {
    await c.login("uzivatel", "heslo"); // přihlásit se
    var jidelnicek = await c.jidelnicekDen(den: DateTime.parse("2022-04-04"));
    print((await c.ziskejUzivatele()).kredit);
    var objednano = await c.objednat(jidelnicek.jidla[0]);
    print(objednano.objednano);
  } catch (e) {
    print("Při získávání informací nastala chyba: $e");
  }
}
