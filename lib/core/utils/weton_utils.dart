
class WetonInfo {
  final String saptawara;
  final String pancawara;
  final int neptuSaptawara;
  final int neptuPancawara;
  final int totalNeptu;
  final String wuku;
  final int javaneseDay;
  final String javaneseMonth;
  final int javaneseYear;
  final String javaneseYearName;
  final String characterSummary;
  final String pangarasan;
  final String pancasuda;

  WetonInfo({
    required this.saptawara,
    required this.pancawara,
    required this.neptuSaptawara,
    required this.neptuPancawara,
    required this.totalNeptu,
    required this.wuku,
    required this.javaneseDay,
    required this.javaneseMonth,
    required this.javaneseYear,
    required this.javaneseYearName,
    required this.characterSummary,
    required this.pangarasan,
    required this.pancasuda,
  });

  Map<String, dynamic> toJson() {
    return {
      'pancawara_id': pancawara.toLowerCase(),
      'saptawara_id': saptawara.toLowerCase(),
      'wuku_index': WetonUtils.wukuNames.indexOf(wuku),
      'neptu_composite': totalNeptu,
    };
  }
}

class WetonUtils {
  static const List<String> saptawaraNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu'
  ];

  static const List<String> pancawaraNames = [
    'Legi',
    'Pahing',
    'Pon',
    'Wage',
    'Kliwon'
  ];

  static const List<String> wukuNames = [
    'Sinta', 'Landep', 'Wukir', 'Kurantil', 'Tolu', 'Gumbreg',
    'Warigalit', 'Warigagung', 'Julungwangi', 'Sungsang', 'Galungan', 'Kuningan',
    'Langkir', 'Mandasiya', 'Julungpujut', 'Pahang', 'Kuruwelut', 'Marakeh',
    'Tambir', 'Medangkungan', 'Maktal', 'Wuye', 'Manahil', 'Prangbakat',
    'Bala', 'Wugu', 'Wayang', 'Kulawu', 'Dukut', 'Watugunung'
  ];

  static const Map<String, int> saptawaraNeptu = {
    'Minggu': 5,
    'Senin': 4,
    'Selasa': 3,
    'Rabu': 7,
    'Kamis': 8,
    'Jumat': 6,
    'Sabtu': 9,
  };

  static const Map<String, int> pancawaraNeptu = {
    'Kliwon': 8,
    'Legi': 5,
    'Pahing': 9,
    'Pon': 7,
    'Wage': 4,
  };

  static int dateToJdn(int year, int month, int day) {
    int y = year;
    int m = month;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    int a = y ~/ 100;
    int b = 2 - a + (a ~/ 4);
    return (365.25 * (y + 4716)).toInt() + (30.6001 * (m + 1)).toInt() + day + b - 1524;
  }

  static WetonInfo calculateWeton(DateTime date) {
    final int jdn = dateToJdn(date.year, date.month, date.day);

    // Saptawara
    final int rem7 = jdn % 7;
    final String saptawara = saptawaraNames[rem7];
    final int neptuS = saptawaraNeptu[saptawara] ?? 0;

    // Pancawara
    final int rem5 = jdn % 5;
    final String pancawara = pancawaraNames[rem5];
    final int neptuP = pancawaraNeptu[pancawara] ?? 0;

    final int totalNeptu = neptuS + neptuP;

    // Wuku
    final int wukuIndex = ((jdn + 64) % 210) ~/ 7;
    final String wuku = wukuNames[wukuIndex];

    // Javanese Date based on Asapon Kurup (Epoch JDN 2428252 = 1 Sura 1867 Alip)
    final int daysDiff = jdn - 2428252;
    final yearLengths = [354, 355, 354, 354, 355, 354, 354, 355];
    final yearNames = ["Alip", "Ehe", "Jimawal", "Je", "Dal", "Be", "Wawu", "Jimakir"];
    
    int currentYear = 1867;
    int daysLeft = daysDiff;

    if (daysLeft >= 0) {
      while (true) {
        int yearIdx = (currentYear - 1867) % 8;
        int yLen = yearLengths[yearIdx];
        if (daysLeft < yLen) break;
        daysLeft -= yLen;
        currentYear += 1;
      }
    } else {
      while (daysLeft < 0) {
        currentYear -= 1;
        int yearIdx = (currentYear - 1867) % 8;
        int yLen = yearLengths[yearIdx];
        daysLeft += yLen;
      }
    }

    int yearIdx = (currentYear - 1867) % 8;
    bool isLeap = yearIdx == 1 || yearIdx == 4 || yearIdx == 7; // Ehe, Dal, Jimakir
    
    final monthLengths = [30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30, isLeap ? 30 : 29];
    final monthNames = [
      "Sura", "Sapar", "Mulud", "Bakda Mulud", "Jumadilawal", "Jumadilakir",
      "Rejeb", "Ruwah", "Pasa", "Sawal", "Sela", "Besar"
    ];

    int mIdx = 0;
    int mDay = daysLeft;
    for (int i = 0; i < monthLengths.length; i++) {
      if (mDay < monthLengths[i]) {
        mIdx = i;
        break;
      }
      mDay -= monthLengths[i];
    }

    final int javaneseDay = mDay + 1;
    final String javaneseMonth = monthNames[mIdx];
    final String javaneseYearName = yearNames[yearIdx];

    // Character mapping
    final charData = _getCharacterData(saptawara, totalNeptu);

    return WetonInfo(
      saptawara: saptawara,
      pancawara: pancawara,
      neptuSaptawara: neptuS,
      neptuPancawara: neptuP,
      totalNeptu: totalNeptu,
      wuku: wuku,
      javaneseDay: javaneseDay,
      javaneseMonth: javaneseMonth,
      javaneseYear: currentYear,
      javaneseYearName: javaneseYearName,
      characterSummary: charData['summary'] ?? '',
      pangarasan: charData['pangarasan'] ?? '',
      pancasuda: charData['pancasuda'] ?? '',
    );
  }

  // ─── Pangarasan ──────────────────────────────────────────────────────────
  // Source of truth: assets/weton/pangarasan-pancasuda.json
  // Loaded at startup via WetonUtils.loadCharacterData(). Empty map until then.
  static var _pangarasanByDay = <String, String>{};

  // ─── Pancasuda ───────────────────────────────────────────────────────────
  // Source of truth: assets/weton/pangarasan-pancasuda.json (index = totalNeptu % 7)
  // Loaded at startup via WetonUtils.loadCharacterData(). Empty list until then.
  static var _pancasudaByIndex = <String>[];

  /// Loads pangarasan and pancasuda lookup data from the decoded JSON asset.
  /// Call once before runApp() so calculateWeton() has data immediately available.
  static void loadCharacterData(Map<String, dynamic> data) {
    _pangarasanByDay = Map<String, String>.from(
      data['pangarasan'] as Map<String, dynamic>,
    );
    _pancasudaByIndex = List<String>.from(data['pancasuda'] as List<dynamic>);
  }

  /// Mengembalikan data karakter (pangarasan & pancasuda) secara algoritmik.
  ///
  /// - Pangarasan ditentukan oleh saptawara (hari Masehi).
  /// - Pancasuda ditentukan oleh totalNeptu % 7.
  static Map<String, String> _getCharacterData(String day, int totalNeptu) {
    return {
      'summary':    'Pribadi yang memiliki watak dinamis dan suka menolong sesama.',
      'pangarasan': _pangarasanByDay[day] ?? '',
      'pancasuda':  _pancasudaByIndex.isNotEmpty
                    ? _pancasudaByIndex[totalNeptu % 7]
                    : '',
    };
  }

  static int calculatePranataMangsaId(DateTime date) {
    final int month = date.month;
    final int day = date.day;
    final int year = date.year;
    
    // Gregorian leap year: divisible by 4, except century years unless divisible by 400.
    final bool isKabisat = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
    final int md = month * 100 + day;

    if (md >= 622 && md <= 801) return 1;
    if (md >= 802 && md <= 824) return 2;
    if (md >= 825 && md <= 917) return 3;
    if (md >= 918 && md <= 1012) return 4;
    if (md >= 1013 && md <= 1108) return 5;
    if (md >= 1109 && md <= 1221) return 6;
    if (md >= 1222 || md <= 202) return 7;
    
    final int kawoluEnd = isKabisat ? 229 : 228;
    if (md >= 203 && md <= kawoluEnd) return 8;
    
    if (md >= 301 && md <= 325) return 9;
    if (md >= 326 && md <= 418) return 10;
    if (md >= 419 && md <= 511) return 11;
    if (md >= 512 && md <= 621) return 12;
    
    return 12;
  }

  // ─── Dino Was (Personal Naas Day) ────────────────────────────────────────
  // Source: Kitab Primbon Betaljemur Adammakna
  // Dino Was repeats cyclically every 35 days (LCM of 7 and 5).

  /// Returns the Dino Was naas day combination for a given birth date.
  static ({String hari, String pasaran}) calculateDinoWas(DateTime birthDate) {
    final int birthJdn        = dateToJdn(birthDate.year, birthDate.month, birthDate.day);
    final int birthHariIdx    = birthJdn % 7;
    final int birthPasaranIdx = birthJdn % 5;

    final int naasHariIdx    = (birthHariIdx + 2) % 7;
    final int naasPasaranIdx = (birthPasaranIdx + 2) % 5;

    return (
      hari:    saptawaraNames[naasHariIdx],
      pasaran: pancawaraNames[naasPasaranIdx],
    );
  }

  /// Returns true if [targetDate] is the Dino Was day for [birthDate].
  static bool checkIsDinoWas(DateTime birthDate, DateTime targetDate) {
    final int birthJdn  = dateToJdn(birthDate.year, birthDate.month, birthDate.day);
    final int targetJdn = dateToJdn(targetDate.year, targetDate.month, targetDate.day);

    final int naasHariIdx    = (birthJdn % 7 + 2) % 7;
    final int naasPasaranIdx = (birthJdn % 5 + 2) % 5;

    return targetJdn % 7 == naasHariIdx && targetJdn % 5 == naasPasaranIdx;
  }
}
