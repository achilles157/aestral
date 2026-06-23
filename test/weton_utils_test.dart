import 'package:flutter_test/flutter_test.dart';
import 'package:aestral/core/utils/weton_utils.dart';

void main() {
  group('Weton & Javanese Calendar Calculations', () {
    test('June 20, 2026 should be Sabtu Pon, Wuku Galungan, 4 Sura 1960 (Be)', () {
      final date = DateTime(2026, 6, 20);
      final weton = WetonUtils.calculateWeton(date);

      expect(weton.saptawara, 'Sabtu');
      expect(weton.pancawara, 'Pon');
      expect(weton.neptuSaptawara, 9);
      expect(weton.neptuPancawara, 7);
      expect(weton.totalNeptu, 16);
      expect(weton.wuku, 'Galungan');
      expect(weton.javaneseDay, 4);
      expect(weton.javaneseMonth, 'Sura');
      expect(weton.javaneseYear, 1960);
      expect(weton.javaneseYearName, 'Be');
    });

    test('June 23, 2026 should be Selasa Legi, Wuku Kuningan, 7 Sura 1960 (Be)', () {
      final date = DateTime(2026, 6, 23);
      final weton = WetonUtils.calculateWeton(date);

      expect(weton.saptawara, 'Selasa');
      expect(weton.pancawara, 'Legi');
      expect(weton.neptuSaptawara, 3);
      expect(weton.neptuPancawara, 5);
      expect(weton.totalNeptu, 8);
      expect(weton.wuku, 'Kuningan');
      expect(weton.javaneseDay, 7);
      expect(weton.javaneseMonth, 'Sura');
      expect(weton.javaneseYear, 1960);
      expect(weton.javaneseYearName, 'Be');
    });

    test('March 24, 1936 (Epoch Asapon) should be Selasa Pon, 1 Sura 1867 (Alip)', () {
      final date = DateTime(1936, 3, 24);
      final weton = WetonUtils.calculateWeton(date);

      expect(weton.saptawara, 'Selasa');
      expect(weton.pancawara, 'Pon');
      expect(weton.javaneseDay, 1);
      expect(weton.javaneseMonth, 'Sura');
      expect(weton.javaneseYear, 1867);
      expect(weton.javaneseYearName, 'Alip');
    });
  });
}
