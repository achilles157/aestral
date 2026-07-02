
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
    final charData = _getCharacterData(saptawara, pancawara);

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

  static Map<String, String> _getCharacterData(String day, String pasaran) {
    final String key = '${day}_$pasaran';
    final data = _wetonDatabase[key];
    if (data != null) return data;

    // Fallback if not specifically mapped
    return {
      'summary': 'Pribadi yang memiliki watak dinamis dan suka menolong sesama.',
      'pangarasan': 'Lakuning Banyu (Tenang, mengalir ke tempat rendah)',
      'pancasuda': 'Wasesa Segara (Pemaaf dan murah hati)',
    };
  }

  static const Map<String, Map<String, String>> _wetonDatabase = {
    'Sabtu_Pon': {
      'summary': 'Pribadi yang sabar, bertanggung jawab, berwawasan luas, dan suka menolong, dengan pembawaan yang tenang.',
      'pangarasan': 'Lakuning Banyu (Tenang, mengalir ke tempat rendah, rendah hati)',
      'pancasuda': 'Wasesa Segara (Pemaaf, pemurah, berwibawa)',
    },
    'Selasa_Legi': {
      'summary': 'Pribadi yang memiliki semangat tinggi, mandiri, cerdas, dan mudah bergaul, namun terkadang temperamental.',
      'pangarasan': 'Lakuning Geni (Hangat, bersemangat, namun mudah marah)',
      'pancasuda': 'Wisesa Segara (Suka memaafkan dan berhati mulia)',
    },
    'Senin_Kliwon': {
      'summary': 'Pribadi yang cerdas, sangat peduli dengan keluarga, namun terkadang terlalu perasa dan mudah cemas.',
      'pangarasan': 'Lakuning Kembang (Menawan, menyukai kedamaian)',
      'pancasuda': 'Bumi Kapetak (Tekun bekerja, tahan penderitaan)',
    },
    'Minggu_Wage': {
      'summary': 'Pribadi yang penurut, setia, berwibawa, dan pandai menghibur orang lain, namun cenderung keras kepala.',
      'pangarasan': 'Lakuning Angin (Pandai bergaul, menyejukkan)',
      'pancasuda': 'Wasesa Segara (Pemaaf dan murah hati)',
    },
    'Kamis_Wage': {
      'summary': 'Pribadi yang setia pada janji, suka menolong, pekerja keras, namun cenderung mudah tersinggung.',
      'pangarasan': 'Lakuning Lintang (Penyendiri, namun bersinar dalam kelompok)',
      'pancasuda': 'Bumi Kapetak (Sabar dan tekun bekerja)',
    },
    // We can add additional key mappings as fallback. Let's make sure the major ones are present.
  };

  static int calculatePranataMangsaId(DateTime date) {
    final int month = date.month;
    final int day = date.day;
    final int year = date.year;
    
    final bool isKabisat = year % 4 == 0;
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
}
