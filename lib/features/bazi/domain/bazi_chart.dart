/// Domain models for Ba Zi (四柱八字) Four Pillars of Destiny.
///
/// These models mirror the TypeScript interfaces in bazi.ts and are used
/// for both online (API) and offline (BaziUtils) calculation results.

class BaziPillar {
  /// Sexagenary slug matching bazi-pillars.json id, e.g. "geng_chen"
  final String id;

  /// Heavenly Stem id matching bazi-stems.json + 10day-masters.json, e.g. "geng"
  final String stemId;

  /// Earthly Branch id matching bazi-branches.json, e.g. "chen"
  final String branchId;

  final int stemIndex;
  final int branchIndex;

  /// Chinese character for stem, e.g. "庚"
  final String stemSymbol;

  /// Chinese character for branch, e.g. "辰"
  final String branchSymbol;

  /// Indonesian element name for stem, e.g. "Logam Yang"
  final String stemNameId;

  /// Indonesian zodiac name for branch, e.g. "Naga"
  final String branchZodiacId;

  /// Dominant element of the Heavenly Stem (for Flutter color-mapping)
  final String element;

  const BaziPillar({
    required this.id,
    required this.stemId,
    required this.branchId,
    required this.stemIndex,
    required this.branchIndex,
    required this.stemSymbol,
    required this.branchSymbol,
    required this.stemNameId,
    required this.branchZodiacId,
    required this.element,
  });

  factory BaziPillar.fromJson(Map<String, dynamic> json) => BaziPillar(
        id: json['id'] as String,
        stemId: json['stemId'] as String,
        branchId: json['branchId'] as String,
        stemIndex: json['stemIndex'] as int,
        branchIndex: json['branchIndex'] as int,
        stemSymbol: json['stemSymbol'] as String,
        branchSymbol: json['branchSymbol'] as String,
        stemNameId: json['stemNameId'] as String,
        branchZodiacId: json['branchZodiacId'] as String,
        element: json['element'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'stemId': stemId,
        'branchId': branchId,
        'stemIndex': stemIndex,
        'branchIndex': branchIndex,
        'stemSymbol': stemSymbol,
        'branchSymbol': branchSymbol,
        'stemNameId': stemNameId,
        'branchZodiacId': branchZodiacId,
        'element': element,
      };
}

class WuXingBalance {
  final int kayu;
  final int api;
  final int tanah;
  final int logam;
  final int air;

  const WuXingBalance({
    required this.kayu,
    required this.api,
    required this.tanah,
    required this.logam,
    required this.air,
  });

  int get total => kayu + api + tanah + logam + air;

  factory WuXingBalance.fromJson(Map<String, dynamic> json) => WuXingBalance(
        kayu: (json['kayu'] as num).toInt(),
        api: (json['api'] as num).toInt(),
        tanah: (json['tanah'] as num).toInt(),
        logam: (json['logam'] as num).toInt(),
        air: (json['air'] as num).toInt(),
      );

  /// Returns the dominant element (highest count). Ties favour the first in cycle order.
  String get dominant {
    final entries = {
      'kayu': kayu,
      'api': api,
      'tanah': tanah,
      'logam': logam,
      'air': air,
    };
    return entries.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  /// Returns the deficient element (lowest count).
  String get deficient {
    final entries = {
      'kayu': kayu,
      'api': api,
      'tanah': tanah,
      'logam': logam,
      'air': air,
    };
    return entries.entries.reduce((a, b) => a.value <= b.value ? a : b).key;
  }
}

class BaziChart {
  final BaziPillar yearPillar;
  final BaziPillar monthPillar;
  final BaziPillar dayPillar;

  /// Null when birth hour is unknown
  final BaziPillar? hourPillar;

  /// The Day Stem id — the "self" (日主) of the chart, e.g. "geng"
  final String dayMasterId;

  final String dayMasterElement;
  final WuXingBalance wuXingBalance;

  /// Human-readable True Solar Time correction note, null if no longitude given
  final String? trueSolarTimeNote;

  /// TST-adjusted hour used for Hour Pillar, null if birthHour not provided
  final int? adjustedHour;

  const BaziChart({
    required this.yearPillar,
    required this.monthPillar,
    required this.dayPillar,
    this.hourPillar,
    required this.dayMasterId,
    required this.dayMasterElement,
    required this.wuXingBalance,
    this.trueSolarTimeNote,
    this.adjustedHour,
  });

  factory BaziChart.fromJson(Map<String, dynamic> json) => BaziChart(
        yearPillar: BaziPillar.fromJson(json['yearPillar'] as Map<String, dynamic>),
        monthPillar: BaziPillar.fromJson(json['monthPillar'] as Map<String, dynamic>),
        dayPillar: BaziPillar.fromJson(json['dayPillar'] as Map<String, dynamic>),
        hourPillar: json['hourPillar'] != null
            ? BaziPillar.fromJson(json['hourPillar'] as Map<String, dynamic>)
            : null,
        dayMasterId: json['dayMasterId'] as String,
        dayMasterElement: json['dayMasterElement'] as String,
        wuXingBalance: WuXingBalance.fromJson(
            json['wuXingBalance'] as Map<String, dynamic>),
        trueSolarTimeNote: json['trueSolarTimeNote'] as String?,
        adjustedHour: json['adjustedHour'] as int?,
      );

  List<BaziPillar> get allPillars => [
        yearPillar,
        monthPillar,
        dayPillar,
        if (hourPillar != null) hourPillar!,
      ];
}

/// One 10-year Luck Pillar cycle (大運) derived from the month pillar sequence.
class LuckPillar {
  final BaziPillar pillar;

  /// Age at which this pillar begins (approximate, ±1 year).
  final int startAge;

  /// Age at which this pillar ends (startAge + 9).
  int get endAge => startAge + 9;

  const LuckPillar({required this.pillar, required this.startAge});
}
