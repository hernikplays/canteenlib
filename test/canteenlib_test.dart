import 'package:canteenlib/canteenlib.dart';
import 'package:test/test.dart';
import 'package:dotenv/dotenv.dart' show load, env;

void main() {
  group('A group of tests', () {
    load();
    Canteen c = Canteen(env["ADDRESS"]!);

    test('Log-in test', () {
      c.login(env["USER"]!, env["PASS"]!).then((r) => expect(r, true));
    });

    test('First Test', () {
      c.login(env["USER"]!, env["PASS"]!).then((r) {
        c.jidelnicekDen().then((t) {
          expect(DateTime.now().day, t.den.day);
        });
      });
    });

    test('Neprázdný jídelníček', () {
      c.login(env["USER"]!, env["PASS"]!).then((r) {
        c.jidelnicekDen(den: DateTime.parse("2022-08-15")).then((t) {
          print(t.jidla[0].nazev);
          expect(t.jidla[0].nazev.isNotEmpty, true);
        });
      });
    });
  });
}
