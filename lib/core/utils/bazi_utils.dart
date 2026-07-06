import '../../features/bazi/domain/bazi_chart.dart';

/// Ba Zi (四柱八字) Four Pillars of Destiny — offline calculation engine.
///
/// Pure Dart mirror of aestral-backend/src/bazi.ts.
/// Used as offline fallback when the Cloudflare Workers API is unreachable.
///
/// Algorithms:
/// - Year Pillar  : Li Chun (立春 ~Feb 4) solar boundary + 60-cycle
/// - Month Pillar : 12 Major Solar Terms (节 jié), approximate ±1 day
/// - Day Pillar   : JDN-based (reference: 1 Jan 2000 = Geng Chen)
/// - Hour Pillar  : 2-hour shi (時) blocks, Zi (子) starts at 23:00
/// - True Solar Time: longitude correction for Indonesia (WIB/WITA/WIT)
/// - Luck Pillars : 大運 8×10-year cycles from month pillar sequence

class BaziUtils {
  // ─── Heavenly Stems 天干 ────────────────────────────────────────────────

  static const List<String> stemIds = [
    'jia', 'yi', 'bing', 'ding', 'wu', 'ji', 'geng', 'xin', 'ren', 'gui',
  ];

  static const List<String> stemSymbols = [
    '甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸',
  ];

  static const List<String> stemNamesId = [
    'Kayu Yang', 'Kayu Yin', 'Api Yang', 'Api Yin', 'Tanah Yang',
    'Tanah Yin', 'Logam Yang', 'Logam Yin', 'Air Yang', 'Air Yin',
  ];

  static const List<String> stemElements = [
    'kayu', 'kayu', 'api', 'api', 'tanah', 'tanah', 'logam', 'logam', 'air', 'air',
  ];

  // ─── Earthly Branches 地支 ──────────────────────────────────────────────

  static const List<String> branchIds = [
    'zi', 'chou', 'yin', 'mao', 'chen', 'si', 'wu', 'wei', 'shen', 'you', 'xu', 'hai',
  ];

  static const List<String> branchSymbols = [
    '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
  ];

  static const List<String> branchZodiacsId = [
    'Tikus', 'Kerbau', 'Harimau', 'Kelinci', 'Naga', 'Ular',
    'Kuda', 'Kambing', 'Monyet', 'Ayam', 'Anjing', 'Babi',
  ];

  static const List<String> branchElements = [
    'air', 'tanah', 'kayu', 'kayu', 'tanah', 'api',
    'api', 'tanah', 'logam', 'logam', 'tanah', 'air',
  ];

  // ─── 60-Pillar Sexagenary Cycle 六十甲子 ────────────────────────────────

  static const List<String> sexagenarySlugs = [
    'jia_zi',   'yi_chou',   'bing_yin',  'ding_mao',  'wu_chen',
    'ji_si',    'geng_wu',   'xin_wei',   'ren_shen',  'gui_you',
    'jia_xu',   'yi_hai',    'bing_zi',   'ding_chou', 'wu_yin',
    'ji_mao',   'geng_chen', 'xin_si',    'ren_wu',    'gui_wei',
    'jia_shen', 'yi_you',    'bing_xu',   'ding_hai',  'wu_zi',
    'ji_chou',  'geng_yin',  'xin_mao',   'ren_chen',  'gui_si',
    'jia_wu',   'yi_wei',    'bing_shen', 'ding_you',  'wu_xu',
    'ji_hai',   'geng_zi',   'xin_chou',  'ren_yin',   'gui_mao',
    'jia_chen', 'yi_si',     'bing_wu',   'ding_wei',  'wu_shen',
    'ji_you',   'geng_xu',   'xin_hai',   'ren_zi',    'gui_chou',
    'jia_yin',  'yi_mao',    'bing_chen', 'ding_si',   'wu_wu',
    'ji_wei',   'geng_shen', 'xin_you',   'ren_xu',    'gui_hai',
  ];

  // ─── Core Utilities ─────────────────────────────────────────────────────

  /// Converts a Gregorian date to Julian Day Number.
  /// Identical to WetonUtils.dateToJdn — kept separate to avoid coupling.
  static int dateToJdn(int year, int month, int day) {
    int y = year;
    int m = month;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final int a = y ~/ 100;
    final int b = 2 - a + (a ~/ 4);
    return (365.25 * (y + 4716)).toInt() +
        (30.6001 * (m + 1)).toInt() +
        day +
        b -
        1524;
  }

  /// Returns 0-indexed position (0–59) in the sexagenary cycle.
  /// Uses the Chinese Remainder Theorem: solve p ≡ s (mod 10), p ≡ b (mod 12).
  static int _sexagenaryIndex(int stemIndex, int branchIndex) {
    final int diff = ((branchIndex - stemIndex) % 12 + 12) % 12;
    final int k = (((diff ~/ 2) * 5) % 6 + 6) % 6;
    return (stemIndex + 10 * k) % 60;
  }

  /// Assembles a BaziPillar from stem and branch indices.
  static BaziPillar _buildPillar(int stemIndex, int branchIndex) {
    final int cycleIdx = _sexagenaryIndex(stemIndex, branchIndex);
    return BaziPillar(
      id: sexagenarySlugs[cycleIdx],
      stemId: stemIds[stemIndex],
      branchId: branchIds[branchIndex],
      stemIndex: stemIndex,
      branchIndex: branchIndex,
      stemSymbol: stemSymbols[stemIndex],
      branchSymbol: branchSymbols[branchIndex],
      stemNameId: stemNamesId[stemIndex],
      branchZodiacId: branchZodiacsId[branchIndex],
      element: stemElements[stemIndex],
    );
  }

  // ─── True Solar Time ────────────────────────────────────────────────────

  /// Corrects local standard time to True Solar Time using longitude.
  /// Indonesia: WIB (105°), WITA (120°), WIT (135°).
  static ({int hour, int minute, double offsetMinutes}) applyTrueSolarTime(
    int localHour,
    int localMinute,
    double longitude,
  ) {
    final double standardMeridian = (longitude / 15).round() * 15.0;
    final double offsetMinutes = (longitude - standardMeridian) * 4.0;
    final double totalMinutes = localHour * 60 + localMinute + offsetMinutes;
    final double normalised = ((totalMinutes % 1440) + 1440) % 1440;
    return (
      hour: normalised ~/ 60,
      minute: normalised.remainder(60).round(),
      offsetMinutes: offsetMinutes,
    );
  }

  // ─── Pillar Calculations ────────────────────────────────────────────────

  /// Year Pillar — Li Chun (立春, ~Feb 4) is the Ba Zi new year boundary.
  static BaziPillar getYearPillar(int year, int month, int day) {
    final int adjustedYear =
        (month < 2 || (month == 2 && day < 4)) ? year - 1 : year;
    final int stemIndex = ((adjustedYear - 4) % 10 + 10) % 10;
    final int branchIndex = ((adjustedYear - 4) % 12 + 12) % 12;
    return _buildPillar(stemIndex, branchIndex);
  }

  /// Returns the Earthly Branch index for the Ba Zi month containing the date.
  static int _monthBranchIndex(int month, int day) {
    final int md = month * 100 + day;
    if (md < 106) return 0;   // Jan 1–5   : Rat   (Da Xue)
    if (md < 204) return 1;   // Jan 6–Feb 3: Ox   (Xiao Han)
    if (md < 306) return 2;   // Feb 4–Mar 5: Tiger (Li Chun)
    if (md < 405) return 3;   // Mar 6–Apr 4: Rabbit (Jing Zhe)
    if (md < 506) return 4;   // Apr 5–May 5: Dragon (Qing Ming)
    if (md < 606) return 5;   // May 6–Jun 5: Snake (Li Xia)
    if (md < 707) return 6;   // Jun 6–Jul 6: Horse (Mang Zhong)
    if (md < 807) return 7;   // Jul 7–Aug 6: Goat  (Xiao Shu)
    if (md < 908) return 8;   // Aug 7–Sep 7: Monkey (Li Qiu)
    if (md < 1008) return 9;  // Sep 8–Oct 7: Rooster (Bai Lu)
    if (md < 1107) return 10; // Oct 8–Nov 6: Dog  (Han Lu)
    if (md < 1207) return 11; // Nov 7–Dec 6: Pig  (Li Dong)
    return 0;                 // Dec 7–Dec 31: Rat  (Da Xue)
  }

  /// Month Pillar — branch from solar term, stem from year stem.
  static BaziPillar getMonthPillar(
      int month, int day, int yearStemIndex) {
    final int monthBranchIndex = _monthBranchIndex(month, day);
    final int tigerStemStart = (yearStemIndex % 5) * 2 + 2;
    final int monthSequence = (monthBranchIndex - 2 + 12) % 12;
    final int monthStemIndex = (tigerStemStart + monthSequence) % 10;
    return _buildPillar(monthStemIndex, monthBranchIndex);
  }

  /// Day Pillar — JDN reference: 1 Jan 2000 = Geng (6) Chen (4).
  static BaziPillar getDayPillar(int year, int month, int day) {
    final int jdn = dateToJdn(year, month, day);
    final int stemIndex = ((jdn - 2451545 + 6) % 10 + 10) % 10;
    final int branchIndex = ((jdn - 2451545 + 4) % 12 + 12) % 12;
    return _buildPillar(stemIndex, branchIndex);
  }

  /// Hour Pillar — 12 two-hour shi blocks, Zi starts at 23:00.
  static BaziPillar getHourPillar(int hour, int dayStemIndex) {
    final int hourBranchIndex = ((hour + 1) % 24) ~/ 2;
    final int stemStart = (dayStemIndex % 5) * 2;
    final int hourStemIndex = (stemStart + hourBranchIndex) % 10;
    return _buildPillar(hourStemIndex, hourBranchIndex);
  }

  // ─── Wu Xing Balance ────────────────────────────────────────────────────

  static WuXingBalance calculateWuXingBalance(List<BaziPillar?> pillars) {
    int kayu = 0, api = 0, tanah = 0, logam = 0, air = 0;

    void addElement(String el) {
      switch (el) {
        case 'kayu':  kayu++;  break;
        case 'api':   api++;   break;
        case 'tanah': tanah++; break;
        case 'logam': logam++; break;
        case 'air':   air++;   break;
      }
    }

    for (final pillar in pillars) {
      if (pillar == null) continue;
      addElement(stemElements[pillar.stemIndex]);
      addElement(branchElements[pillar.branchIndex]);
    }

    return WuXingBalance(
      kayu: kayu, api: api, tanah: tanah, logam: logam, air: air,
    );
  }

  // ─── Main Entry Point ───────────────────────────────────────────────────

  /// Calculates a complete Ba Zi chart offline.
  ///
  /// [birthDate]  — DateTime of birth (only date components used)
  /// [birthHour]  — Local standard time hour (0–23), null if unknown
  /// [longitude]  — Decimal degrees, used for True Solar Time correction
  static BaziChart calculateBaziChart(
    DateTime birthDate, {
    int? birthHour,
    double? longitude,
  }) {
    final int year  = birthDate.year;
    final int month = birthDate.month;
    final int day   = birthDate.day;

    final BaziPillar yearPillar  = getYearPillar(year, month, day);
    final BaziPillar monthPillar = getMonthPillar(month, day, yearPillar.stemIndex);
    final BaziPillar dayPillar   = getDayPillar(year, month, day);

    BaziPillar? hourPillar;
    String? trueSolarTimeNote;
    int? adjustedHour;

    if (birthHour != null) {
      int tstHour   = birthHour;
      int tstMinute = 0;

      if (longitude != null) {
        final tst = applyTrueSolarTime(birthHour, 0, longitude);
        tstHour       = tst.hour;
        tstMinute     = tst.minute;
        final int offsetMin   = tst.offsetMinutes.round();
        final String sign     = offsetMin >= 0 ? '+' : '-';
        final int absMin      = offsetMin.abs();
        final int stdMeridian = (longitude / 15).round() * 15;
        trueSolarTimeNote =
            '${birthHour.toString().padLeft(2, '0')}:00 → '
            '${tstHour.toString().padLeft(2, '0')}:${tstMinute.toString().padLeft(2, '0')} TST '
            '(bujur ${longitude.toStringAsFixed(2)}°, '
            'meridian standar $stdMeridian°, '
            'koreksi $sign$absMin mnt)';
      }

      hourPillar   = getHourPillar(tstHour, dayPillar.stemIndex);
      adjustedHour = tstHour;
    }

    final WuXingBalance balance = calculateWuXingBalance([
      yearPillar, monthPillar, dayPillar, hourPillar,
    ]);

    return BaziChart(
      yearPillar:        yearPillar,
      monthPillar:       monthPillar,
      dayPillar:         dayPillar,
      hourPillar:        hourPillar,
      dayMasterId:       dayPillar.stemId,
      dayMasterElement:  dayPillar.element,
      wuXingBalance:     balance,
      trueSolarTimeNote: trueSolarTimeNote,
      adjustedHour:      adjustedHour,
    );
  }

  // ─── Ten Gods 十神 ──────────────────────────────────────────────────────

  static const Map<String, String> _generates = {
    'kayu': 'api', 'api': 'tanah', 'tanah': 'logam', 'logam': 'air', 'air': 'kayu',
  };

  static const Map<String, String> _controls = {
    'kayu': 'tanah', 'tanah': 'air', 'air': 'api', 'api': 'logam', 'logam': 'kayu',
  };

  /// Returns the Ten God id for [targetStemIndex] relative to [dmStemIndex].
  /// IDs match 10gods.json: friend, rob_wealth, eating_god, hurting_officer,
  /// indirect_wealth, direct_wealth, seven_killings, direct_officer,
  /// indirect_resource, direct_resource.
  static String getTenGodId(int dmStemIndex, int targetStemIndex) {
    final String dmEl = stemElements[dmStemIndex];
    final String tgEl = stemElements[targetStemIndex];
    final bool same   = (dmStemIndex % 2) == (targetStemIndex % 2);

    if (tgEl == dmEl)             return same ? 'friend'            : 'rob_wealth';
    if (_generates[dmEl] == tgEl) return same ? 'eating_god'        : 'hurting_officer';
    if (_controls[dmEl]  == tgEl) return same ? 'indirect_wealth'   : 'direct_wealth';
    if (_controls[tgEl]  == dmEl) return same ? 'seven_killings'    : 'direct_officer';
    if (_generates[tgEl] == dmEl) return same ? 'indirect_resource' : 'direct_resource';
    return 'friend'; // unreachable with valid 0–9 stem indices
  }

  // ─── Luck Pillars 大運 ──────────────────────────────────────────────────

  /// Approximate dates (month, day) of the 12 節 solar terms.
  /// Used to calculate days-to-nearest-term for luck pillar starting age.
  static const List<(int, int)> _kSolarTermDates = [
    (1,  6),  // Xiao Han  小寒
    (2,  4),  // Li Chun   立春
    (3,  6),  // Jing Zhe  惊蛰
    (4,  5),  // Qing Ming 清明
    (5,  6),  // Li Xia    立夏
    (6,  6),  // Mang Zhong 芒种
    (7,  7),  // Xiao Shu  小暑
    (8,  7),  // Li Qiu    立秋
    (9,  8),  // Bai Lu    白露
    (10, 8),  // Han Lu    寒露
    (11, 7),  // Li Dong   立冬
    (12, 7),  // Da Xue    大雪
  ];

  /// Builds a [BaziPillar] directly from its 0–59 sexagenary cycle position.
  static BaziPillar _buildPillarFromCycleIndex(int cycleIdx) {
    final int i = ((cycleIdx % 60) + 60) % 60;
    return _buildPillar(i % 10, i % 12);
  }

  /// Returns the number of days between [birth] and the nearest 節 solar term.
  /// [isForward] true → count to the NEXT term; false → count to the PREVIOUS.
  static int _daysToNearestSolarTerm(DateTime birth, bool isForward) {
    final int birthJdn = dateToJdn(birth.year, birth.month, birth.day);
    final List<int> candidates = [];
    for (int yr = birth.year - 1; yr <= birth.year + 1; yr++) {
      for (final (int m, int d) in _kSolarTermDates) {
        candidates.add(dateToJdn(yr, m, d));
      }
    }
    if (isForward) {
      final nexts = candidates.where((j) => j > birthJdn).toList()..sort();
      return nexts.isEmpty ? 30 : nexts.first - birthJdn;
    } else {
      final prevs = candidates.where((j) => j < birthJdn).toList()
        ..sort((a, b) => b.compareTo(a));
      return prevs.isEmpty ? 30 : birthJdn - prevs.first;
    }
  }

  /// Calculates 8 Luck Pillars (大運) from the month pillar sequence.
  ///
  /// Direction rule:
  ///   Male  + Yang year → forward 顺运
  ///   Male  + Yin  year → backward 逆运
  ///   Female + Yang year → backward
  ///   Female + Yin  year → forward
  ///
  /// Starting age = round(days to nearest 節 ÷ 3), clamped to [1, 99].
  static List<LuckPillar> calculateLuckPillars({
    required DateTime birthDate,
    required BaziPillar monthPillar,
    required int yearStemIndex,
    required bool isMale,
    int count = 8,
  }) {
    final bool isYangYear = yearStemIndex % 2 == 0;
    final bool isForward  = isMale == isYangYear;

    final int days     = _daysToNearestSolarTerm(birthDate, isForward);
    final int startAge = (days / 3).round().clamp(1, 99);

    final int monthCycleIdx =
        _sexagenaryIndex(monthPillar.stemIndex, monthPillar.branchIndex);
    final int step = isForward ? 1 : -1;

    return List.generate(count, (i) {
      final int cycleIdx =
          ((monthCycleIdx + step * (i + 1)) % 60 + 60) % 60;
      return LuckPillar(
        pillar:   _buildPillarFromCycleIndex(cycleIdx),
        startAge: startAge + i * 10,
      );
    });
  }
}
