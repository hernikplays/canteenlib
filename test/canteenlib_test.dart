import 'package:canteenlib/canteenlib.dart';
import 'package:test/test.dart';
import 'package:dotenv/dotenv.dart' show load, env;

void main() {
  group('A group of tests', () {
    load();
    Canteen c = Canteen(env["ADDRESS"]!);

    setUp(() {
      c.login(env["USER"]!, env["PASS"]!);
    });

    test('First Test', () {
      c.jidelnicekDen().then((t) {
        expect(DateTime.now().day, t.den.day);
      });
    });
  });
}
