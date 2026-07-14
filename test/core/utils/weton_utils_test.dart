import 'package:flutter_test/flutter_test.dart';
import 'package:aestral/core/utils/weton_utils.dart';

void main() {
  group('WetonUtils.dateToJdn', () {
    test('should calculate correct JDN for known dates', () {
      expect(WetonUtils.dateToJdn(2000, 1, 1), 2451545);
      expect(WetonUtils.dateToJdn(1990, 1, 1), 2447893);
      expect(WetonUtils.dateToJdn(2026, 7, 14), 2461236); // Python verified
    });

    test('should handle leap years correctly', () {
      final jdn2000Feb29 = WetonUtils.dateToJdn(2000, 2, 29);
      final jdn2000Mar01 = WetonUtils.dateToJdn(2000, 3, 1);
      expect(jdn2000Mar01 - jdn2000Feb29, 1);

      final jdn2024Feb29 = WetonUtils.dateToJdn(2024, 2, 29);
      final jdn2024Feb28 = WetonUtils.dateToJdn(2024, 2, 28);
      expect(jdn2024Feb29 - jdn2024Feb28, 1);
    });

    test('should handle month transitions correctly', () {
      final jdnDec31 = WetonUtils.dateToJdn(1999, 12, 31);
      final jdnJan01 = WetonUtils.dateToJdn(2000, 1, 1);
      expect(jdnJan01 - jdnDec31, 1);
    });
  });

  group('WetonUtils.calculateWeton', () {
    test('should calculate correct weton for 2000-01-01', () {
      final date = DateTime.utc(2000, 1, 1);
      final weton = WetonUtils.calculateWeton(date);

      expect(weton.saptawara, 'Sabtu');
      expect(weton.pancawara, 'Legi');
      expect(weton.neptuSaptawara, 9);
      expect(weton.neptuPancawara, 5);
      expect(weton.totalNeptu, 14);
    });

    test('should calculate correct weton for 1990-01-01', () {
      final date = DateTime.utc(1990, 1, 1);
      final weton = WetonUtils.calculateWeton(date);

      expect(weton.saptawara, 'Senin');
      expect(weton.pancawara, 'Wage');
      expect(weton.neptuSaptawara, 4);
      expect(weton.neptuPancawara, 4);
      expect(weton.totalNeptu, 8);
    });

    test('should calculate correct weton for 2026-07-14', () {
      final date = DateTime.utc(2026, 7, 14);
      final weton = WetonUtils.calculateWeton(date);

      // JDN 2461236 % 7 = 1 -> Selasa, % 5 = 1 -> Pahing (Python verified)
      expect(weton.saptawara, 'Selasa');
      expect(weton.pancawara, 'Pahing');
      expect(weton.totalNeptu, 12); // 3 + 9
    });

    test('should calculate wuku correctly', () {
      final date = DateTime.utc(2000, 1, 1);
      final weton = WetonUtils.calculateWeton(date);

      expect(WetonUtils.wukuNames.contains(weton.wuku), true);
      final wukuIndex = WetonUtils.wukuNames.indexOf(weton.wuku);
      expect(wukuIndex, greaterThanOrEqualTo(0));
      expect(wukuIndex, lessThan(30));
    });

    test('should calculate Javanese date components', () {
      final date = DateTime.utc(2000, 1, 1);
      final weton = WetonUtils.calculateWeton(date);

      expect(weton.javaneseDay, greaterThanOrEqualTo(1));
      expect(weton.javaneseDay, lessThanOrEqualTo(30));
      expect(weton.javaneseYear, greaterThan(1800));
      expect(weton.javaneseYear, lessThan(2100));

      final validYearNames = [
        'Alip', 'Ehe', 'Jimawal', 'Je', 'Dal', 'Be', 'Wawu', 'Jimakir',
      ];
      expect(validYearNames.contains(weton.javaneseYearName), true);

      final validMonths = [
        'Sura', 'Sapar', 'Mulud', 'Bakda Mulud', 'Jumadilawal', 'Jumadilakir',
        'Rejeb', 'Ruwah', 'Pasa', 'Sawal', 'Sela', 'Besar',
      ];
      expect(validMonths.contains(weton.javaneseMonth), true);
    });

    test('should return consistent results for same date', () {
      final date = DateTime.utc(1995, 6, 15);
      final weton1 = WetonUtils.calculateWeton(date);
      final weton2 = WetonUtils.calculateWeton(date);

      expect(weton1.saptawara, weton2.saptawara);
      expect(weton1.pancawara, weton2.pancawara);
      expect(weton1.totalNeptu, weton2.totalNeptu);
      expect(weton1.wuku, weton2.wuku);
    });
  });

  group('WetonUtils.calculatePranataMangsaId', () {
    test('should return correct mangsa for each period', () {
      expect(WetonUtils.calculatePranataMangsaId(DateTime.utc(2026, 6, 22)), 1);
      expect(WetonUtils.calculatePranataMangsaId(DateTime.utc(2026, 7, 15)), 1);
      expect(WetonUtils.calculatePranataMangsaId(DateTime.utc(2026, 8, 2)), 2);
      expect(WetonUtils.calculatePranataMangsaId(DateTime.utc(2026, 8, 25)), 3);
      expect(WetonUtils.calculatePranataMangsaId(DateTime.utc(2026, 5, 12)), 12);
    });

    test('should handle leap year for Mangsa 8 (Kawolu)', () {
      expect(WetonUtils.calculatePranataMangsaId(DateTime.utc(2024, 2, 29)), 8);
      expect(WetonUtils.calculatePranataMangsaId(DateTime.utc(2024, 3, 1)), 9);
      expect(WetonUtils.calculatePranataMangsaId(DateTime.utc(2025, 2, 28)), 8);
      expect(WetonUtils.calculatePranataMangsaId(DateTime.utc(2025, 3, 1)), 9);
    });
  });

  group('WetonUtils.calculateDinoWas', () {
    test('should calculate Dino Was for birth date', () {
      final birthDate = DateTime.utc(1990, 1, 1);
      final dinoWas = WetonUtils.calculateDinoWas(birthDate);

      expect(dinoWas.hari, 'Rabu');
      expect(dinoWas.pasaran, 'Legi'); // Python verified: (3%5+2)%5=0→Legi
    });

    test('should return valid day and pasaran names', () {
      final birthDate = DateTime.utc(2000, 1, 7);
      final dinoWas = WetonUtils.calculateDinoWas(birthDate);

      expect(WetonUtils.saptawaraNames.contains(dinoWas.hari), true);
      expect(WetonUtils.pancawaraNames.contains(dinoWas.pasaran), true);
    });
  });

  group('WetonUtils.checkIsDinoWas', () {
    test('should detect Dino Was in 35-day cycle', () {
      final birthDate = DateTime.utc(2000, 1, 1);

      int dinoWasCount = 0;
      for (int i = 0; i < 70; i++) {
        final testDate = DateTime.utc(2000, 1, 1 + i);
        if (WetonUtils.checkIsDinoWas(birthDate, testDate)) {
          dinoWasCount++;
        }
      }

      expect(dinoWasCount, 2);
    });

    test('should return false for birth date itself', () {
      final birthDate = DateTime.utc(1990, 1, 1);
      final result = WetonUtils.checkIsDinoWas(birthDate, birthDate);
      expect(result, false);
    });
  });

  group('WetonInfo.toJson', () {
    test('should serialize to correct JSON format', () {
      final date = DateTime.utc(2000, 1, 1);
      final weton = WetonUtils.calculateWeton(date);
      final json = weton.toJson();

      expect(json['pancawara_id'], weton.pancawara.toLowerCase());
      expect(json['saptawara_id'], weton.saptawara.toLowerCase());
      expect(json['neptu_composite'], weton.totalNeptu);

      final wukuIndex = WetonUtils.wukuNames.indexOf(weton.wuku);
      expect(json['wuku_index'], wukuIndex);
    });
  });
}
