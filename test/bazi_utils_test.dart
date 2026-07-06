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

    test('Year Pillar 2000-01-01: ji_mao — sebelum Li Chun pakai tahun 1999', () {
      // Jan 1 < Feb 4 (Li Chun) → adjusted year = 1999 = Ji Mao
      final chart = BaziUtils.calculateBaziChart(DateTime(2000, 1, 1));
      expect(chart.yearPillar.id, 'ji_mao');
    });

    test('Year Pillar 1984-02-04: jia_zi — tepat di Li Chun (batas tahun Ba Zi)', () {
      // Feb 4 = Li Chun → adjusted year = 1984 = Jia Zi
      final chart = BaziUtils.calculateBaziChart(DateTime(1984, 2, 4));
      expect(chart.yearPillar.id, 'jia_zi');
    });

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

    test('Month Pillar 1984-02-04: bing_yin (Li Chun — awal bulan Harimau)', () {
      // Feb 4 = Li Chun = awal Tiger month; Jia Zi year → Tiger stem Bing
      final chart = BaziUtils.calculateBaziChart(DateTime(1984, 2, 4));
      expect(chart.monthPillar.id, 'bing_yin');
      expect(chart.monthPillar.stemId, 'bing');
      expect(chart.monthPillar.branchId, 'yin');
    });

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

    test('Wu Xing Balance 1990-10-10 tanpa jam — 6 karakter', () {
      // Year geng(logam)+wu(api), Month bing(api)+xu(tanah), Day geng(logam)+wu(api)
      // → kayu=0, api=3, tanah=1, logam=2, air=0
      final chart = BaziUtils.calculateBaziChart(DateTime(1990, 10, 10));
      expect(chart.hourPillar, isNull);
      expect(chart.wuXingBalance.kayu,  0);
      expect(chart.wuXingBalance.api,   3);
      expect(chart.wuXingBalance.tanah, 1);
      expect(chart.wuXingBalance.logam, 2);
      expect(chart.wuXingBalance.air,   0);
      expect(chart.wuXingBalance.total, 6);
    });

    test('Wu Xing Balance 2000-01-01 tanpa jam — 6 karakter', () {
      // Year ji(tanah)+mao(kayu), Month bing(api)+zi(air), Day geng(logam)+chen(tanah)
      // → kayu=1, api=1, tanah=2, logam=1, air=1
      final chart = BaziUtils.calculateBaziChart(DateTime(2000, 1, 1));
      expect(chart.wuXingBalance.kayu,  1);
      expect(chart.wuXingBalance.api,   1);
      expect(chart.wuXingBalance.tanah, 2);
      expect(chart.wuXingBalance.logam, 1);
      expect(chart.wuXingBalance.air,   1);
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
      expect(chart.wuXingBalance.total, 8);    // 8 karakter penuh
    });

    test('Hour Pillar 14:00 bujur 106.84° Jakarta: TST = 14:07', () {
      // stdMeridian = 105°, offset = (106.84 - 105) × 4 = 7.36 mnt → 14:07
      final chart = BaziUtils.calculateBaziChart(
        DateTime(1990, 10, 10),
        birthHour: 14,
        longitude: 106.84,
      );
      expect(chart.adjustedHour, 14);  // masih jam 14 (belum berganti blok)
      expect(chart.trueSolarTimeNote, isNotNull);
      expect(chart.trueSolarTimeNote, contains('106.84'));
      expect(chart.trueSolarTimeNote, contains('105'));
    });

    // ─── True Solar Time ──────────────────────────────────────────────────

    test('applyTrueSolarTime: 14:00 bujur 106.84° → 14:07', () {
      final tst = BaziUtils.applyTrueSolarTime(14, 0, 106.84);
      expect(tst.hour,   14);
      expect(tst.minute, 7);
    });

    test('applyTrueSolarTime: 14:00 bujur 119.4° Makassar (WITA) → koreksi negatif', () {
      // stdMeridian = 120°, offset = (119.4 - 120) × 4 = -2.4 mnt → 13:57
      final tst = BaziUtils.applyTrueSolarTime(14, 0, 119.4);
      expect(tst.hour,   13);
      expect(tst.minute, 58); // round(-2.4) = -2, 14:00 - 2 mnt = 13:58
    });
  });
}
