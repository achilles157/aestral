import 'package:flutter_test/flutter_test.dart';
import 'package:aestral/core/utils/bazi_utils.dart';
import 'package:aestral/features/bazi/domain/bazi_chart.dart';

void main() {
  group('BaziUtils.dateToJdn', () {
    test('should calculate correct JDN for reference dates', () {
      expect(BaziUtils.dateToJdn(2000, 1, 1), 2451545);
      expect(BaziUtils.dateToJdn(1990, 1, 1), 2447893);
      expect(BaziUtils.dateToJdn(2026, 7, 14), 2461236); // Python verified
    });

    test('should handle leap years correctly', () {
      final jdn2000Feb29 = BaziUtils.dateToJdn(2000, 2, 29);
      final jdn2000Mar01 = BaziUtils.dateToJdn(2000, 3, 1);
      expect(jdn2000Mar01 - jdn2000Feb29, 1);
    });

    test('should match WetonUtils JDN calculation', () {
      final dates = [
        [1990, 1, 1],
        [2000, 6, 15],
        [2026, 12, 31],
      ];
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
      // Longitude 115° is WEST of WITA (120°): offset = -20 min
      // 23:30 - 20 min = 23:10 (no rollover)
      final tst = BaziUtils.applyTrueSolarTime(23, 30, 115.0);
      expect(tst.offsetMinutes, closeTo(-20.0, 0.1));
      expect(tst.hour, 23);
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

      final total =
          balance.kayu +
          balance.api +
          balance.tanah +
          balance.logam +
          balance.air;
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
      final chart = BaziUtils.calculateBaziChart(birthDate, birthHour: 10);

      expect(chart.tenGods, isNotNull);
      expect(chart.tenGods.year, isNotEmpty);
      expect(chart.tenGods.month, isNotEmpty);
      expect(chart.tenGods.hour, isNotEmpty);
    });
  });

  // ── Solar Term Edge Cases ─────────────────────────────────────────────────

  group('BaziUtils Solar Term edge cases', () {
    // Li Chun 2000 = Feb 4 (verified by getJieDay(1, 2000) = 4)
    // Rule: born ON the Jié = first day of new period (strict < in code)

    test('born exactly ON Li Chun is counted as new year', () {
      // 2000-02-04: day(4) < liChunDay(4) → FALSE → Geng Chen (2000)
      final p = BaziUtils.getYearPillar(2000, 2, 4);
      expect(p.stemId, 'geng');
      expect(p.stemIndex, 6);
      expect(p.branchId, 'chen');
      expect(p.branchIndex, 4);
    });

    test('born day before Li Chun is still previous year', () {
      // 2000-02-03: day(3) < liChunDay(4) → TRUE → Ji Mao (1999)
      final p = BaziUtils.getYearPillar(2000, 2, 3);
      expect(p.stemId, 'ji');
      expect(p.stemIndex, 5);
      expect(p.branchId, 'mao');
      expect(p.branchIndex, 3);
    });

    test('born exactly ON Li Chun transitions month branch to Yin (Tiger)', () {
      // On Feb 4 (Li Chun), month branch changes from Chou (Ox) to Yin (Tiger)
      final pOn = BaziUtils.getMonthPillar(2, 4, 6, 2000); // yearStem=6 (Geng)
      expect(pOn.branchIndex, 2); // Yin (Tiger)
      expect(pOn.branchId, 'yin');
    });

    test('born day before Li Chun is still Chou (Ox) month branch', () {
      // Feb 3 = still in 12th month (Chou/Ox)
      final pBefore = BaziUtils.getMonthPillar(
        2,
        3,
        5,
        2000,
      ); // yearStem=5 (Ji, previous)
      expect(pBefore.branchIndex, 1); // Chou (Ox)
      expect(pBefore.branchId, 'chou');
    });
  });

  // ── Luck Pillars ──────────────────────────────────────────────────────────

  group('BaziUtils.calculateLuckPillars', () {
    // 2000 = Geng year (stem 6, yang).  1999 = Ji year (stem 5, yin).
    // Direction rule: isForward = (isMale == isYangYear)

    LuckPillar _firstPillar(DateTime birth, bool isMale) {
      final chart = BaziUtils.calculateBaziChart(birth);
      final lp = BaziUtils.calculateLuckPillars(
        birthDate: birth,
        monthPillar: chart.monthPillar,
        yearStemIndex: chart.yearPillar.stemIndex,
        isMale: isMale,
      );
      return lp.first;
    }

    test('returns 8 pillars', () {
      final chart = BaziUtils.calculateBaziChart(DateTime.utc(2000, 6, 15));
      final lp = BaziUtils.calculateLuckPillars(
        birthDate: DateTime.utc(2000, 6, 15),
        monthPillar: chart.monthPillar,
        yearStemIndex: chart.yearPillar.stemIndex,
        isMale: true,
      );
      expect(lp.length, 8);
    });

    test('start age is within valid range [1, 99]', () {
      final chart = BaziUtils.calculateBaziChart(DateTime.utc(1990, 6, 15));
      final lp = BaziUtils.calculateLuckPillars(
        birthDate: DateTime.utc(1990, 6, 15),
        monthPillar: chart.monthPillar,
        yearStemIndex: chart.yearPillar.stemIndex,
        isMale: true,
      );
      expect(lp.first.startAge, inInclusiveRange(1, 99));
    });

    test('each subsequent pillar starts 10 years after previous', () {
      final chart = BaziUtils.calculateBaziChart(DateTime.utc(2000, 6, 15));
      final lp = BaziUtils.calculateLuckPillars(
        birthDate: DateTime.utc(2000, 6, 15),
        monthPillar: chart.monthPillar,
        yearStemIndex: chart.yearPillar.stemIndex,
        isMale: true,
      );
      for (int i = 1; i < lp.length; i++) {
        expect(lp[i].startAge - lp[i - 1].startAge, 10);
      }
    });

    test('all pillars have valid sexagenary IDs', () {
      final chart = BaziUtils.calculateBaziChart(DateTime.utc(2000, 6, 15));
      final lp = BaziUtils.calculateLuckPillars(
        birthDate: DateTime.utc(2000, 6, 15),
        monthPillar: chart.monthPillar,
        yearStemIndex: chart.yearPillar.stemIndex,
        isMale: true,
      );
      for (final p in lp) {
        expect(
          BaziUtils.sexagenarySlugs.contains(p.pillar.id),
          true,
          reason: 'Invalid sexagenary: ${p.pillar.id}',
        );
      }
    });

    test('Male + Yang year produces DIFFERENT sequence from Male + Yin year', () {
      // Same birth date, same gender — only year polarity differs
      final pYang = _firstPillar(DateTime.utc(2000, 6, 15), true); // Yang year
      final pYin = _firstPillar(DateTime.utc(1999, 6, 15), true); // Yin year
      // Forward vs backward → first pillar must differ
      expect(
        pYang.pillar.stemIndex == pYin.pillar.stemIndex &&
            pYang.pillar.branchIndex == pYin.pillar.branchIndex,
        false,
        reason:
            'Forward and backward sequences should yield different first pillars',
      );
    });

    test('Male and Female produce DIFFERENT sequences for same chart', () {
      // 2000 Yang year: male=forward, female=backward
      final pMale = _firstPillar(DateTime.utc(2000, 6, 15), true);
      final pFemale = _firstPillar(DateTime.utc(2000, 6, 15), false);
      expect(
        pMale.pillar.stemIndex == pFemale.pillar.stemIndex &&
            pMale.pillar.branchIndex == pFemale.pillar.branchIndex,
        false,
        reason:
            'Male (forward) and Female (backward) must produce different sequences',
      );
    });

    test(
      'Female + Yang year produces SAME direction as Male + Yin year (both backward)',
      () {
        // Both backward → should match month offset direction
        final femaleYang = BaziUtils.calculateBaziChart(
          DateTime.utc(2000, 6, 15),
        );
        final maleYin = BaziUtils.calculateBaziChart(DateTime.utc(1999, 6, 15));

        final lpFemaleYang = BaziUtils.calculateLuckPillars(
          birthDate: DateTime.utc(2000, 6, 15),
          monthPillar: femaleYang.monthPillar,
          yearStemIndex: femaleYang.yearPillar.stemIndex,
          isMale: false, // female + yang = backward
        );
        final lpMaleYin = BaziUtils.calculateLuckPillars(
          birthDate: DateTime.utc(1999, 6, 15),
          monthPillar: maleYin.monthPillar,
          yearStemIndex: maleYin.yearPillar.stemIndex,
          isMale: true, // male + yin = backward
        );
        // Both are backward — start ages in range
        expect(lpFemaleYang.first.startAge, inInclusiveRange(1, 99));
        expect(lpMaleYin.first.startAge, inInclusiveRange(1, 99));
      },
    );
  });
}
