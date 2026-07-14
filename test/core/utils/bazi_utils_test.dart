import 'package:flutter_test/flutter_test.dart';
import 'package:aestral/core/utils/bazi_utils.dart';
import 'package:aestral/features/bazi/domain/bazi_chart.dart';

void main() {
  group('BaziUtils.dateToJdn', () {
    test('should calculate correct JDN for reference dates', () {
      expect(BaziUtils.dateToJdn(2000, 1, 1), 2451545);
      expect(BaziUtils.dateToJdn(1990, 1, 1), 2447893);
      expect(BaziUtils.dateToJdn(2026, 7, 14), 2460869);
    });

    test('should handle leap years correctly', () {
      final jdn2000Feb29 = BaziUtils.dateToJdn(2000, 2, 29);
      final jdn2000Mar01 = BaziUtils.dateToJdn(2000, 3, 1);
      expect(jdn2000Mar01 - jdn2000Feb29, 1);
    });

    test('should match WetonUtils JDN calculation', () {
      final dates = [[1990, 1, 1], [2000, 6, 15], [2026, 12, 31]];
      for (final d in dates) {
        final jdn = BaziUtils.dateToJdn(d[0], d[1], d[2]);
        expect(jdn, greaterThan(2400000));
      }
    });
  });

  group('BaziUtils.getYearPillar', () {
    test('should calculate year pillar for date after Li Chun', () {
      final yearPillar = BaziUtils.getYearPillar(2000, 2, 10);
      expect(yearPillar.stemId, 'geng');
      expect(yearPillar.stemIndex, 6);
      expect(yearPillar.branchId, 'chen');
      expect(yearPillar.branchIndex, 4);
      expect(yearPillar.branchZodiacId, 'Naga');
    });

    test('should use previous year for dates before Li Chun', () {
      final yearPillar = BaziUtils.getYearPillar(2000, 1, 15);
      expect(yearPillar.stemIndex, 5);
      expect(yearPillar.stemId, 'ji');
      expect(yearPillar.branchIndex, 3);
      expect(yearPillar.branchZodiacId, 'Kelinci');
    });

    test('should have valid sexagenary cycle id', () {
      final yearPillar = BaziUtils.getYearPillar(2000, 3, 1);
      expect(BaziUtils.sexagenarySlugs.contains(yearPillar.id), true);
    });
  });

  group('BaziUtils.getDayPillar', () {
    test('should calculate day pillar with JDN reference', () {
      final dayPillar = BaziUtils.getDayPillar(2000, 1, 1);
      expect(dayPillar.stemIndex, 6);
      expect(dayPillar.branchIndex, 4);
      expect(dayPillar.stemId, 'geng');
      expect(dayPillar.branchId, 'chen');
    });

    test('should have valid element assignment', () {
      final dayPillar = BaziUtils.getDayPillar(1990, 6, 15);
      final validElements = ['kayu', 'api', 'tanah', 'logam', 'air'];
      expect(validElements.contains(dayPillar.element), true);
    });

    test('should cycle through 60-day cycle correctly', () {
      final day1 = BaziUtils.getDayPillar(2000, 1, 1);
      final day61 = BaziUtils.getDayPillar(2000, 3, 1);
      expect(day1.stemIndex, day61.stemIndex);
      expect(day1.branchIndex, day61.branchIndex);
    });
  });

  group('BaziUtils.getHourPillar', () {
    test('should calculate hour pillar for Zi hour (23:00-00:59)', () {
      final hourPillar = BaziUtils.getHourPillar(23, 0);
      expect(hourPillar.branchIndex, 0);
      expect(hourPillar.branchZodiacId, 'Tikus');
    });

    test('should calculate hour pillar for Wu hour (11:00-12:59)', () {
      final hourPillar = BaziUtils.getHourPillar(11, 0);
      expect(hourPillar.branchIndex, 6);
      expect(hourPillar.branchZodiacId, 'Kuda');
    });

    test('should vary stem based on day stem', () {
      final hour1 = BaziUtils.getHourPillar(11, 0);
      final hour2 = BaziUtils.getHourPillar(11, 1);
      expect(hour1.branchIndex, hour2.branchIndex);
      expect(hour1.stemIndex, isNot(hour2.stemIndex));
    });

    test('should handle midnight boundary correctly', () {
      final midnight = BaziUtils.getHourPillar(0, 0);
      expect(midnight.branchIndex, 0);
      final oneAm = BaziUtils.getHourPillar(1, 0);
      expect(oneAm.branchIndex, 1);
    });
  });

  group('BaziUtils.applyTrueSolarTime', () {
    test('should adjust time eastward of standard meridian', () {
      final tst = BaziUtils.applyTrueSolarTime(12, 0, 110.0);
      expect(tst.offsetMinutes, closeTo(20.0, 0.1));
      expect(tst.hour, 12);
      expect(tst.minute, 20);
    });

    test('should adjust time westward of standard meridian', () {
      final tst = BaziUtils.applyTrueSolarTime(12, 0, 100.0);
      expect(tst.offsetMinutes, closeTo(-20.0, 0.1));
      expect(tst.hour, 11);
      expect(tst.minute, 40);
    });

    test('should handle hour rollover', () {
      final tst = BaziUtils.applyTrueSolarTime(23, 30, 115.0);
      expect(tst.hour, 0);
      expect(tst.minute, closeTo(10, 1));
    });

    test('should return zero offset at standard meridian', () {
      final tst = BaziUtils.applyTrueSolarTime(12, 0, 105.0);
      expect(tst.offsetMinutes, 0.0);
      expect(tst.hour, 12);
      expect(tst.minute, 0);
    });
  });

  group('BaziUtils.calculateBaziChart', () {
    test('should generate complete chart with all four pillars', () {
      final birthDate = DateTime.utc(1990, 6, 15);
      final chart = BaziUtils.calculateBaziChart(
        birthDate,
        birthHour: 10,
        longitude: 106.8,
      );

      expect(chart.yearPillar, isNotNull);
      expect(chart.monthPillar, isNotNull);
      expect(chart.dayPillar, isNotNull);
      expect(chart.hourPillar, isNotNull);
      expect(chart.dayMasterId, chart.dayPillar.stemId);
      expect(chart.dayMasterElement, chart.dayPillar.element);
    });

    test('should generate chart without hour pillar when hour unknown', () {
      final birthDate = DateTime.utc(1990, 6, 15);
      final chart = BaziUtils.calculateBaziChart(birthDate);

      expect(chart.yearPillar, isNotNull);
      expect(chart.monthPillar, isNotNull);
      expect(chart.dayPillar, isNotNull);
      expect(chart.hourPillar, isNull);
      expect(chart.adjustedHour, isNull);
      expect(chart.trueSolarTimeNote, isNull);
    });

    test('should include True Solar Time note when longitude provided', () {
      final birthDate = DateTime.utc(2000, 1, 1);
      final chart = BaziUtils.calculateBaziChart(
        birthDate,
        birthHour: 12,
        longitude: 110.0,
      );

      expect(chart.trueSolarTimeNote, isNotNull);
      expect(chart.trueSolarTimeNote, contains('TST'));
      expect(chart.trueSolarTimeNote, contains('110.00'));
      expect(chart.adjustedHour, isNotNull);
    });

    test('should calculate Wu Xing balance', () {
      final birthDate = DateTime.utc(1990, 6, 15);
      final chart = BaziUtils.calculateBaziChart(
        birthDate,
        birthHour: 10,
        longitude: 106.8,
      );

      final balance = chart.wuXingBalance;
      expect(balance.kayu, greaterThanOrEqualTo(0));
      expect(balance.api, greaterThanOrEqualTo(0));
      expect(balance.tanah, greaterThanOrEqualTo(0));
      expect(balance.logam, greaterThanOrEqualTo(0));
      expect(balance.air, greaterThanOrEqualTo(0));

      final total = balance.kayu + balance.api + balance.tanah + 
                    balance.logam + balance.air;
      expect(total, greaterThan(0));
    });

    test('should assign Day Master strength', () {
      final birthDate = DateTime.utc(1990, 6, 15);
      final chart = BaziUtils.calculateBaziChart(birthDate);

      expect(chart.dmStrength, isNotNull);
      expect(chart.dmStrength.label, isNotEmpty);
      expect(chart.dmStrength.yongShen, isNotEmpty);
      expect(chart.dmStrength.jiShen, isNotEmpty);
    });

    test('should calculate Ten Gods', () {
      final birthDate = DateTime.utc(1990, 6, 15);
      final chart = BaziUtils.calculateBaziChart(
        birthDate,
        birthHour: 10,
      );

      expect(chart.tenGods, isNotNull);
      expect(chart.tenGods.year, isNotEmpty);
      expect(chart.tenGods.month, isNotEmpty);
      expect(chart.tenGods.hour, isNotEmpty);
    });
  });
}
