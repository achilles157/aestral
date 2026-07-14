/// Shared display constants for Bazi widgets.
///
/// Single source of truth — values mirror bazi-stems.json and bazi-branches.json.
/// Import this file instead of re-declaring the same maps/lists in each widget.
library;

/// Element → combined Indonesian + Chinese label (e.g. 'kayu' → 'Kayu 木').
const kBaziElementLabel = <String, String>{
  'kayu': 'Kayu 木',
  'api': 'Api 火',
  'tanah': 'Tanah 土',
  'logam': 'Logam 金',
  'air': 'Air 水',
};

/// Wu Xing generation-cycle order: 木 → 火 → 土 → 金 → 水.
const kBaziElementOrder = ['kayu', 'api', 'tanah', 'logam', 'air'];

/// Chinese symbol per element (parallel to kBaziElementOrder).
const kBaziElementSymbol = ['木', '火', '土', '金', '水'];

/// Short Indonesian name per element (parallel to kBaziElementOrder).
const kBaziElementName = ['Kayu', 'Api', 'Tanah', 'Logam', 'Air'];

/// Branch Chinese symbols — index 0 = Zi 子, index 11 = Hai 亥.
const kBaziBranchSymbol = [
  '子',
  '丑',
  '寅',
  '卯',
  '辰',
  '巳',
  '午',
  '未',
  '申',
  '酉',
  '戌',
  '亥',
];

/// Branch Indonesian zodiac names (parallel to kBaziBranchSymbol).
const kBaziBranchName = [
  'Tikus',
  'Kerbau',
  'Harimau',
  'Kelinci',
  'Naga',
  'Ular',
  'Kuda',
  'Kambing',
  'Monyet',
  'Ayam',
  'Anjing',
  'Babi',
];

/// Pillar position labels — index 0–3 = natal chart, index 4 = annual (流年).
const kBaziPillarLabels = ['Tahun', 'Bulan', 'Hari', 'Jam', '流年'];
