import 'package:canteenlib/canteenlib.dart';
import 'package:test/test.dart';
import 'package:dotenv/dotenv.dart';

void main() {
  group('A group of tests', () {
    var env = DotEnv(includePlatformEnvironment: true)..load();
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
        c.jidelnicekDen(den: DateTime.now().add(Duration(days: 5))).then((t) {
          print(t.jidla[0].nazev);
          expect(t.jidla[0].nazev.isNotEmpty, true);
        });
      });
    });
  });
}
