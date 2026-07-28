import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bazi_utils.dart';
import '../../domain/bazi_chart.dart';
import 'bazi_pillar_column.dart' show kBaziElementColors;

/// Internal model for one Ba Zi season.
class _Season {
  final String label;
  final String emoji;
  final String range;
  final String element; // expected element for this season
  final int repMonth; // representative month for pillar calculation
  final int repDay;
  final List<int> months; // calendar months covered

  const _Season({
    required this.label,
    required this.emoji,
    required this.range,
    required this.element,
    required this.repMonth,
    required this.repDay,
    required this.months,
  });
}

const List<_Season> _kSeasons = [
  _Season(
    label: 'Musim Kayu 木',
    emoji: '🌱',
    range: 'Feb–Mei',
    element: 'kayu',
    repMonth: 3,
    repDay: 15,
    months: [2, 3, 4, 5],
  ),
  _Season(
    label: 'Musim Api 火',
    emoji: '🔥',
    range: 'Mei–Agu',
    element: 'api',
    repMonth: 6,
    repDay: 15,
    months: [5, 6, 7, 8],
  ),
  _Season(
    label: 'Musim Logam 金',
    emoji: '⚔',
    range: 'Agu–Nov',
    element: 'logam',
    repMonth: 9,
    repDay: 15,
    months: [8, 9, 10, 11],
  ),
  _Season(
    label: 'Musim Air 水',
    emoji: '💧',
    range: 'Nov–Feb',
    element: 'air',
    repMonth: 12,
    repDay: 15,
    months: [11, 12, 1, 2],
  ),
];

/// Guidance strings per status × season.
const Map<String, Map<String, String>> _kGuidance = {
  'yong': {
    'kayu':
        'Ekspansi & inovasi — energi mendukung pertumbuhan dan proyek baru.',
    'api':
        'Akselerasi sosial — momentum untuk networking, promosi, dan visibilitas.',
    'logam':
        'Disiplin & panen — waktu terbaik untuk konsolidasi aset dan negosiasi.',
    'air':
        'Refleksi strategis — perkuat keahlian inti dan bangun fondasi jangka panjang.',
  },
  'ji': {
    'kayu':
        'Jaga energi — hindari ekspansi berlebihan, fokus pada yang sudah ada.',
    'api': 'Kelola emosi — tekanan sosial meningkat, jaga stabilitas batin.',
    'logam':
        'Perhatikan kesehatan — energi cenderung kompetitif, pilih pertempuran dengan bijak.',
    'air':
        'Waspadai ketidakpastian — rencanakan cadangan dan hindari risiko besar.',
  },
  'netral': {
    'kayu':
        'Energi stabil — cocok untuk menyelesaikan agenda yang sudah berjalan.',
    'api': 'Ritme normal — jaga konsistensi dan komunikasi yang sehat.',
    'logam': 'Fondasi terjaga — waktu untuk evaluasi dan penyesuaian rencana.',
    'air':
        'Ketenangan produktif — waktu untuk refleksi dan perencanaan mendalam.',
  },
};

/// Seasonal roadmap card — shows how each Ba Zi season interacts with the
/// user's Day Master (Yong Shen / Ji Shen), with the current season highlighted.
///
/// Seasons follow Ba Zi solar term boundaries (not Gregorian quarters):
///   Kayu  寅卯辰  ~Feb 4  – May 6
///   Api   巳午未  ~May 6  – Aug 7
///   Logam 申酉戌  ~Aug 7  – Nov 7
///   Air   亥子丑  ~Nov 7  – Feb 4
class BaziSeasonalRoadmap extends StatelessWidget {
  final BaziChart natalChart;
  final int year;

  const BaziSeasonalRoadmap({
    super.key,
    required this.natalChart,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dmIdx = natalChart.dayPillar.stemIndex;

    // Year stem index for month pillar formula (Five Tigers rule)
    final yearPillar = BaziUtils.getYearPillar(year, 3, 1);
    final yearStemIdx = yearPillar.stemIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('🗺 ', style: const TextStyle(fontSize: 13)),
            Text(
              'Peta Kosmis $year',
              style: GoogleFonts.cinzel(
                fontSize: 12,
                color: AppTheme.accentGold,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._kSeasons.map((season) {
          final monthPillar = BaziUtils.getMonthPillar(
            season.repMonth,
            season.repDay,
            yearStemIdx,
            year,
          );

          final branchElem = BaziUtils.branchElements[monthPillar.branchIndex];
          final isYong = natalChart.dmStrength.yongShen.contains(branchElem);
          final isJi = natalChart.dmStrength.jiShen.contains(branchElem);
          final statusKey = isYong ? 'yong' : (isJi ? 'ji' : 'netral');

          final tenGodId = BaziUtils.getTenGodId(dmIdx, monthPillar.stemIndex);
          final tenGodName = _kTenGodShort[tenGodId] ?? tenGodId;
          final tenGodHanzi = _kTenGodHanzi[tenGodId] ?? '';

          final isCurrent = season.months.contains(now.month);
          final isPast = _isSeasonPast(season, now);

          final elemColor =
              kBaziElementColors[branchElem] ?? AppTheme.accentGold;

          return Opacity(
            opacity: isPast ? 0.45 : 1.0,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrent
                    ? elemColor.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCurrent
                      ? elemColor.withValues(alpha: 0.55)
                      : Colors.white.withValues(alpha: 0.07),
                  width: isCurrent ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(season.emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          season.label,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isCurrent ? elemColor : Colors.white70,
                          ),
                        ),
                      ),
                      Text(
                        season.range,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: Colors.white38,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(statusKey: statusKey),
                      if (isCurrent) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: elemColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'KINI',
                            style: GoogleFonts.outfit(
                              fontSize: 8,
                              color: Colors.black87,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        '$tenGodHanzi $tenGodName',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: elemColor.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        ' — ',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: Colors.white24,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _kGuidance[statusKey]?[branchElem] ??
                              'Energi berjalan dengan ritme normal.',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: Colors.white54,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  bool _isSeasonPast(_Season season, DateTime now) {
    final month = now.month;
    // Air season (Nov–Feb) crosses year boundary — special handling
    if (season.element == 'air') {
      // Past if current month is Mar–Oct (Air season already ended)
      return month >= 3 && month <= 10;
    }
    // Other seasons: all months must be before current month
    if (season.months.contains(month)) return false;
    return season.months.every((m) => m < month);
  }
}

// ─── Ten God short labels ─────────────────────────────────────────────────────

const Map<String, String> _kTenGodShort = {
  'friend': 'Sahabat',
  'rob_wealth': 'Penantang',
  'eating_god': 'Pencipta',
  'hurting_officer': 'Visioner',
  'indirect_wealth': 'Jaring',
  'direct_wealth': 'Pembangun',
  'seven_killings': 'Pendobrak',
  'direct_officer': 'Penjaga',
  'indirect_resource': 'Filsuf',
  'direct_resource': 'Pustaka',
};

const Map<String, String> _kTenGodHanzi = {
  'friend': '比肩',
  'rob_wealth': '劫財',
  'eating_god': '食神',
  'hurting_officer': '傷官',
  'indirect_wealth': '偏財',
  'direct_wealth': '正財',
  'seven_killings': '七殺',
  'direct_officer': '正官',
  'indirect_resource': '偏印',
  'direct_resource': '正印',
};

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String statusKey;

  const _StatusBadge({required this.statusKey});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (statusKey) {
      'yong' => ('✦ Menguntungkan', const Color(0xFF34D399)),
      'ji' => ('⚡ Kewaspadaan', const Color(0xFFFB923C)),
      _ => ('≈ Stabil', Colors.white54),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
