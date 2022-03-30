import 'package:canteenlib/canteenlib.dart';

void main(List<String> args) {
  Canteen c = Canteen("https://kantyna.neco.cz");
  c.login("uzivatel", "heslo").then((value) {
    c.jidelnicekDen(den: DateTime.parse("2022-04-04")).then((t) async {
      print((await c.ziskejUzivatele()).kredit);
      c.objednat(t.jidla[0]).then(
        (value) {
          t.jidla[0] = value; // divně udělané ale nic lepšího teď nevymyslím
          print(t.jidla[0].objednano);
          print(t.jidla[0].orderUrl);
        },
      );
    });
  }).catchError((o) {
    print(o);
    return null;
  });
}
