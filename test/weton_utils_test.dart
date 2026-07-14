import 'package:flutter_test/flutter_test.dart';
import 'package:aestral/core/utils/weton_utils.dart';

void main() {
  // ── dateToJdn ──────────────────────────────────────────────────────────────

  group('WetonUtils.dateToJdn', () {
    test('2000-01-01 should return JDN 2451545 (standard reference)', () {
      expect(WetonUtils.dateToJdn(2000, 1, 1), equals(2451545));
    });

    test('1936-03-24 (Asapon epoch) should return JDN 2428252', () {
      expect(WetonUtils.dateToJdn(1936, 3, 24), equals(2428252));
    });

    test('leap year Feb 29 should be valid', () {
      // 2000 is a leap year — JDN must be exactly 1 more than Feb 28
      final feb28 = WetonUtils.dateToJdn(2000, 2, 28);
      final feb29 = WetonUtils.dateToJdn(2000, 2, 29);
      expect(feb29 - feb28, equals(1));
    });
  });

  // ── Saptawara & Pancawara ─────────────────────────────────────────────────

  group('WetonUtils — Saptawara & Pancawara', () {
    test('Sabtu Pon: June 20, 2026', () {
      final weton = WetonUtils.calculateWeton(DateTime(2026, 6, 20));
      expect(weton.saptawara, 'Sabtu');
      expect(weton.pancawara, 'Pon');
      expect(weton.neptuSaptawara, 9);
      expect(weton.neptuPancawara, 7);
      expect(weton.totalNeptu, 16);
    });

    test('Selasa Legi: June 23, 2026', () {
      final weton = WetonUtils.calculateWeton(DateTime(2026, 6, 23));
      expect(weton.saptawara, 'Selasa');
      expect(weton.pancawara, 'Legi');
      expect(weton.neptuSaptawara, 3);
      expect(weton.neptuPancawara, 5);
      expect(weton.totalNeptu, 8);
    });

    test('Selasa Pon: March 24, 1936 (Asapon epoch)', () {
      final weton = WetonUtils.calculateWeton(DateTime(1936, 3, 24));
      expect(weton.saptawara, 'Selasa');
      expect(weton.pancawara, 'Pon');
    });

    test(
      'totalNeptu selalu antara 7 (min: Senin+Wage=4+4) dan 17 (max: Kamis+Pahing=8+9)',
      () {
        // Rabu Pahing: neptu 7+9 = 16
        final weton = WetonUtils.calculateWeton(DateTime(2026, 6, 24));
        expect(weton.totalNeptu, greaterThanOrEqualTo(7));
        expect(weton.totalNeptu, lessThanOrEqualTo(18));
      },
    );
  });

  // ── Wuku ───────────────────────────────────────────────────────────────────

  group('WetonUtils — Wuku', () {
    test('June 20, 2026 should be Wuku Galungan (index 10)', () {
      final weton = WetonUtils.calculateWeton(DateTime(2026, 6, 20));
      expect(weton.wuku, 'Galungan');
    });

    test('June 23, 2026 should be Wuku Kuningan (index 11)', () {
      final weton = WetonUtils.calculateWeton(DateTime(2026, 6, 23));
      expect(weton.wuku, 'Kuningan');
    });

    test('wuku harus selalu ada di list wukuNames', () {
      final dates = [
        DateTime(2026, 1, 1),
        DateTime(2026, 3, 15),
        DateTime(2026, 7, 7),
        DateTime(2026, 12, 31),
      ];
      for (final date in dates) {
        final weton = WetonUtils.calculateWeton(date);
        expect(WetonUtils.wukuNames, contains(weton.wuku));
      }
    });

    test('siklus wuku 210 hari: tanggal + 210 hari harus wuku yang sama', () {
      final base = DateTime(2026, 1, 1);
      final plus210 = base.add(const Duration(days: 210));
      final w1 = WetonUtils.calculateWeton(base);
      final w2 = WetonUtils.calculateWeton(plus210);
      expect(w1.wuku, equals(w2.wuku));
    });
  });

  // ── Javanese Calendar (Asapon Kurup) ──────────────────────────────────────

  group('WetonUtils — Kalender Jawa (Asapon)', () {
    test('March 24, 1936 = 1 Sura 1867 Alip (epoch)', () {
      final weton = WetonUtils.calculateWeton(DateTime(1936, 3, 24));
      expect(weton.javaneseDay, 1);
      expect(weton.javaneseMonth, 'Sura');
      expect(weton.javaneseYear, 1867);
      expect(weton.javaneseYearName, 'Alip');
    });

    test('June 20, 2026 = 4 Sura 1960 Be', () {
      final weton = WetonUtils.calculateWeton(DateTime(2026, 6, 20));
      expect(weton.javaneseDay, 4);
      expect(weton.javaneseMonth, 'Sura');
      expect(weton.javaneseYear, 1960);
      expect(weton.javaneseYearName, 'Be');
    });

    test('June 23, 2026 = 7 Sura 1960 Be', () {
      final weton = WetonUtils.calculateWeton(DateTime(2026, 6, 23));
      expect(weton.javaneseDay, 7);
      expect(weton.javaneseMonth, 'Sura');
      expect(weton.javaneseYear, 1960);
      expect(weton.javaneseYearName, 'Be');
    });

    test('javaneseDay selalu antara 1 dan 30', () {
      final dates = [
        DateTime(2026, 1, 1),
        DateTime(2026, 4, 17),
        DateTime(2026, 7, 7),
        DateTime(2026, 10, 31),
      ];
      for (final date in dates) {
        final weton = WetonUtils.calculateWeton(date);
        expect(weton.javaneseDay, greaterThanOrEqualTo(1));
        expect(weton.javaneseDay, lessThanOrEqualTo(30));
      }
    });

    test('javaneseMonth selalu salah satu dari 12 bulan Jawa', () {
      const validMonths = [
        'Sura',
        'Sapar',
        'Mulud',
        'Bakda Mulud',
        'Jumadilawal',
        'Jumadilakir',
        'Rejeb',
        'Ruwah',
        'Pasa',
        'Sawal',
        'Sela',
        'Besar',
      ];
      final dates = [
        DateTime(2026, 1, 1),
        DateTime(2026, 6, 20),
        DateTime(2026, 12, 31),
      ];
      for (final date in dates) {
        final weton = WetonUtils.calculateWeton(date);
        expect(validMonths, contains(weton.javaneseMonth));
      }
    });

    test('javaneseYearName selalu salah satu dari 8 tahun windu', () {
      const validYearNames = [
        'Alip',
        'Ehe',
        'Jimawal',
        'Je',
        'Dal',
        'Be',
        'Wawu',
        'Jimakir',
      ];
      final dates = [
        DateTime(2026, 6, 20),
        DateTime(2020, 1, 1),
        DateTime(2000, 1, 1),
      ];
      for (final date in dates) {
        final weton = WetonUtils.calculateWeton(date);
        expect(validYearNames, contains(weton.javaneseYearName));
      }
    });
  });

  // ── calculatePranataMangsaId ───────────────────────────────────────────────

  group('WetonUtils.calculatePranataMangsaId', () {
    test('Kasa (1): June 22 – Aug 1', () {
      expect(
        WetonUtils.calculatePranataMangsaId(DateTime(2026, 6, 22)),
        equals(1),
      );
      expect(
        WetonUtils.calculatePranataMangsaId(DateTime(2026, 7, 15)),
        equals(1),
      );
      expect(
        WetonUtils.calculatePranataMangsaId(DateTime(2026, 8, 1)),
        equals(1),
      );
    });

    test('Karo (2): Aug 2 – Aug 24', () {
      expect(
        WetonUtils.calculatePranataMangsaId(DateTime(2026, 8, 2)),
        equals(2),
      );
      expect(
        WetonUtils.calculatePranataMangsaId(DateTime(2026, 8, 24)),
        equals(2),
      );
    });

    test('Kapitu (7): straddles year boundary — Dec 22 and Jan 1', () {
      expect(
        WetonUtils.calculatePranataMangsaId(DateTime(2026, 12, 22)),
        equals(7),
      );
      expect(
        WetonUtils.calculatePranataMangsaId(DateTime(2026, 1, 1)),
        equals(7),
      );
      expect(
        WetonUtils.calculatePranataMangsaId(DateTime(2026, 2, 2)),
        equals(7),
      );
    });

    test('Kawolu (8): leap year ends Feb 29, non-leap ends Feb 28', () {
      // 2024 is a leap year
      expect(
        WetonUtils.calculatePranataMangsaId(DateTime(2024, 2, 29)),
        equals(8),
      );
      // 2026 is not a leap year
      expect(
        WetonUtils.calculatePranataMangsaId(DateTime(2026, 2, 28)),
        equals(8),
      );
    });

    test('Sada (12): May 12 – June 21', () {
      expect(
        WetonUtils.calculatePranataMangsaId(DateTime(2026, 5, 12)),
        equals(12),
      );
      expect(
        WetonUtils.calculatePranataMangsaId(DateTime(2026, 6, 21)),
        equals(12),
      );
    });

    test('id selalu antara 1 dan 12', () {
      for (int m = 1; m <= 12; m++) {
        final id = WetonUtils.calculatePranataMangsaId(DateTime(2026, m, 15));
        expect(id, greaterThanOrEqualTo(1));
        expect(id, lessThanOrEqualTo(12));
      }
    });
  });

  // ── WetonInfo.toJson ──────────────────────────────────────────────────────

  group('WetonInfo.toJson', () {
    test('toJson menghasilkan key yang benar', () {
      final weton = WetonUtils.calculateWeton(DateTime(2026, 6, 20));
      final json = weton.toJson();
      expect(json.containsKey('pancawara_id'), isTrue);
      expect(json.containsKey('saptawara_id'), isTrue);
      expect(json.containsKey('wuku_index'), isTrue);
      expect(json.containsKey('neptu_composite'), isTrue);
    });

    test('toJson: pancawara_id dan saptawara_id lowercase', () {
      final weton = WetonUtils.calculateWeton(DateTime(2026, 6, 20));
      final json = weton.toJson();
      expect(json['pancawara_id'], equals('pon'));
      expect(json['saptawara_id'], equals('sabtu'));
    });

    test('toJson: neptu_composite sesuai totalNeptu', () {
      final weton = WetonUtils.calculateWeton(DateTime(2026, 6, 20));
      final json = weton.toJson();
      expect(json['neptu_composite'], equals(weton.totalNeptu));
    });
  });
}
