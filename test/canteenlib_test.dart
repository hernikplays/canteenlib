import 'package:canteenlib/canteenlib.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    Canteen c = Canteen("a");

    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () {
      expect(true, isTrue);
    });
  });
}
