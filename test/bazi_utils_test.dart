import 'package:flutter_test/flutter_test.dart';
import 'package:aestral/core/utils/bazi_utils.dart';

void main() {
  group('BaziUtils — Four Pillars Calculation', () {
    // ─── Year Pillar ──────────────────────────────────────────────────────

    test('Year Pillar 1990: geng_wu (Logam Yang - Kuda)', () {
      final chart = BaziUtils.calculateBaziChart(DateTime(1990, 10, 10));
      expect(chart.yearPillar.id, 'geng_wu');
      expect(chart.yearPillar.stemId, 'geng');
      expect(chart.yearPillar.branchId, 'wu');
    });

    test(
      'Year Pillar 2000-01-01: ji_mao — sebelum Li Chun pakai tahun 1999',
      () {
        // Jan 1 < Feb 4 (Li Chun) → adjusted year = 1999 = Ji Mao
        final chart = BaziUtils.calculateBaziChart(DateTime(2000, 1, 1));
        expect(chart.yearPillar.id, 'ji_mao');
      },
    );

    test(
      'Year Pillar 1984-02-04: jia_zi — tepat di Li Chun (batas tahun Ba Zi)',
      () {
        // Feb 4 = Li Chun → adjusted year = 1984 = Jia Zi
        final chart = BaziUtils.calculateBaziChart(DateTime(1984, 2, 4));
        expect(chart.yearPillar.id, 'jia_zi');
      },
    );

    // ─── Month Pillar ─────────────────────────────────────────────────────

    test('Month Pillar 1990-10-10: bing_xu (Han Lu — bulan Anjing)', () {
      // Oct 8–Nov 6 = Xu (Dog) month; Geng Wu year → Tiger stem Bing
      final chart = BaziUtils.calculateBaziChart(DateTime(1990, 10, 10));
      expect(chart.monthPillar.id, 'bing_xu');
      expect(chart.monthPillar.stemId, 'bing');
      expect(chart.monthPillar.branchId, 'xu');
    });

    test('Month Pillar 2000-01-01: bing_zi (Da Xue — bulan Tikus)', () {
      // Jan 1–5 masih bulan Rat (Da Xue dari 7 Des); Ji Mao year → Tiger stem Bing
      final chart = BaziUtils.calculateBaziChart(DateTime(2000, 1, 1));
      expect(chart.monthPillar.id, 'bing_zi');
    });

    test(
      'Month Pillar 1984-02-04: bing_yin (Li Chun — awal bulan Harimau)',
      () {
        // Feb 4 = Li Chun = awal Tiger month; Jia Zi year → Tiger stem Bing
        final chart = BaziUtils.calculateBaziChart(DateTime(1984, 2, 4));
        expect(chart.monthPillar.id, 'bing_yin');
        expect(chart.monthPillar.stemId, 'bing');
        expect(chart.monthPillar.branchId, 'yin');
      },
    );

    // ─── Day Pillar ───────────────────────────────────────────────────────

    test('Day Pillar 2000-01-01: geng_chen — titik referensi JDN 2451545', () {
      // Reference point: JDN 2451545 = Geng(6) Chen(4)
      final chart = BaziUtils.calculateBaziChart(DateTime(2000, 1, 1));
      expect(chart.dayPillar.id, 'geng_chen');
      expect(chart.dayPillar.stemId, 'geng');
      expect(chart.dayPillar.branchId, 'chen');
    });

    test('Day Pillar 1990-10-10: geng_wu (-3370 hari dari referensi)', () {
      final chart = BaziUtils.calculateBaziChart(DateTime(1990, 10, 10));
      expect(chart.dayPillar.id, 'geng_wu');
    });

    test('Day Pillar 1984-02-04: geng_yin (-5810 hari dari referensi)', () {
      final chart = BaziUtils.calculateBaziChart(DateTime(1984, 2, 4));
      expect(chart.dayPillar.id, 'geng_yin');
    });

    // ─── Day Master ───────────────────────────────────────────────────────

    test('Day Master 1990-10-10: geng (Logam Yang)', () {
      final chart = BaziUtils.calculateBaziChart(DateTime(1990, 10, 10));
      expect(chart.dayMasterId, 'geng');
      expect(chart.dayMasterElement, 'logam');
    });

    // ─── Wu Xing Balance ──────────────────────────────────────────────────

    test('Wu Xing Balance 1990-10-10 tanpa jam — dengan Cang Gan', () {
      // Year geng(logam)+wu(api|ding,ji), Month bing(api)+xu(tanah|wu,xin,ding),
      // Day  geng(logam)+wu(api|ding,ji)
      // → kayu=0, api=6, tanah=4, logam=3, air=0, total=13
      final chart = BaziUtils.calculateBaziChart(DateTime(1990, 10, 10));
      expect(chart.hourPillar, isNull);
      expect(chart.wuXingBalance.kayu, 0);
      expect(chart.wuXingBalance.api, 6);
      expect(chart.wuXingBalance.tanah, 4);
      expect(chart.wuXingBalance.logam, 3);
      expect(chart.wuXingBalance.air, 0);
      expect(chart.wuXingBalance.total, 13);
    });

    test('Wu Xing Balance 2000-01-01 tanpa jam — dengan Cang Gan', () {
      // Year ji(tanah)+mao(kayu|yi), Month bing(api)+zi(air|gui),
      // Day  geng(logam)+chen(tanah|wu,yi,gui)
      // → kayu=3, api=1, tanah=3, logam=1, air=3, total=11
      final chart = BaziUtils.calculateBaziChart(DateTime(2000, 1, 1));
      expect(chart.wuXingBalance.kayu, 3);
      expect(chart.wuXingBalance.api, 1);
      expect(chart.wuXingBalance.tanah, 3);
      expect(chart.wuXingBalance.logam, 1);
      expect(chart.wuXingBalance.air, 3);
      expect(chart.wuXingBalance.total, 11);
    });

    // ─── Hour Pillar ──────────────────────────────────────────────────────

    test('Hour Pillar 14:00 tanpa longitude: tanpa TST koreksi', () {
      final chart = BaziUtils.calculateBaziChart(
        DateTime(1990, 10, 10),
        birthHour: 14,
      );
      expect(chart.hourPillar, isNotNull);
      expect(chart.adjustedHour, 14);
      expect(chart.trueSolarTimeNote, isNull); // tanpa longitude
      // 13 (3 pilar) + 5 (gui_wei + hidden ji,ding,yi) = 18
      expect(chart.wuXingBalance.total, 18);
    });

    test('Hour Pillar 14:00 bujur 106.84° Jakarta: TST = 14:07', () {
      // stdMeridian = 105°, offset = (106.84 - 105) × 4 = 7.36 mnt → 14:07
      final chart = BaziUtils.calculateBaziChart(
        DateTime(1990, 10, 10),
        birthHour: 14,
        longitude: 106.84,
      );
      expect(chart.adjustedHour, 14); // masih jam 14 (belum berganti blok)
      expect(chart.trueSolarTimeNote, isNotNull);
      expect(chart.trueSolarTimeNote, contains('106.84'));
      expect(chart.trueSolarTimeNote, contains('105'));
    });

    // ─── Solar Term Edge Cases (Bug Fix Regression) ───────────────────────

    test('Year Pillar 2021-02-03: xin_chou — Li Chun jatuh Feb 3 di 2021', () {
      // Li Chun 2021 = Feb 3 (bukan Feb 4 fixed)
      // Dengan lookup table: Feb 3 2021 adalah pada/setelah Li Chun → tahun 2021 = Xin Chou
      final chart = BaziUtils.calculateBaziChart(DateTime(2021, 2, 3));
      expect(chart.yearPillar.id, 'xin_chou');
      expect(chart.yearPillar.stemId, 'xin');
      expect(chart.yearPillar.branchId, 'chou');
    });

    test('Year Pillar 2021-02-02: geng_zi — sehari sebelum Li Chun 2021', () {
      // Feb 2, 2021 masih sebelum Li Chun (Feb 3) → adjustedYear = 2020 = Geng Zi
      final chart = BaziUtils.calculateBaziChart(DateTime(2021, 2, 2));
      expect(chart.yearPillar.id, 'geng_zi');
      expect(chart.yearPillar.stemId, 'geng');
      expect(chart.yearPillar.branchId, 'zi');
    });

    test(
      'Month Pillar 2024-04-04: chen (Dragon) — QingMing jatuh Apr 4 di 2024',
      () {
        // Qing Ming 2024 = Apr 4, bukan Apr 5 → bulan Dragon (Chen), bukan Rabbit (Mao)
        final chart = BaziUtils.calculateBaziChart(DateTime(2024, 4, 4));
        expect(chart.monthPillar.branchId, 'chen');
      },
    );

    test(
      'Month Pillar 2024-04-03: mao (Rabbit) — sehari sebelum QingMing 2024',
      () {
        // Apr 3, 2024 masih bulan Rabbit (sebelum Qing Ming Apr 4)
        final chart = BaziUtils.calculateBaziChart(DateTime(2024, 4, 3));
        expect(chart.monthPillar.branchId, 'mao');
      },
    );

    // ─── True Solar Time ──────────────────────────────────────────────────

    test('applyTrueSolarTime: 14:00 bujur 106.84° → 14:07', () {
      final tst = BaziUtils.applyTrueSolarTime(14, 0, 106.84);
      expect(tst.hour, 14);
      expect(tst.minute, 7);
    });

    test(
      'applyTrueSolarTime: 14:00 bujur 119.4° Makassar (WITA) → koreksi negatif',
      () {
        // stdMeridian = 120°, offset = (119.4 - 120) × 4 = -2.4 mnt → 13:58
        final tst = BaziUtils.applyTrueSolarTime(14, 0, 119.4);
        expect(tst.hour, 13);
        expect(tst.minute, 58); // round(-2.4) = -2, 14:00 - 2 mnt = 13:58
      },
    );
  });
}
