import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/utils/bazi_utils.dart';
import '../../domain/bazi_chart.dart';
import 'bazi_pillar_column.dart' show kBaziElementColors;

/// Chinese name + short modern name for each Ten God.
const Map<String, (String, String)> _kTenGodNames = {
  'friend':            ('比肩', 'Sahabat'),
  'rob_wealth':        ('劫財', 'Kolaborator'),
  'eating_god':        ('食神', 'Pencipta'),
  'hurting_officer':   ('傷官', 'Pembangkang'),
  'indirect_wealth':   ('偏財', 'Jaring'),
  'direct_wealth':     ('正財', 'Pembangun'),
  'seven_killings':    ('七殺', 'Pendobrak'),
  'direct_officer':    ('正官', 'Penjaga'),
  'indirect_resource': ('偏印', 'Perenung'),
  'direct_resource':   ('正印', 'Pustaka'),
};

/// Compact Ten Gods (十神) row — one chip per pillar relative to Day Master.
class BaziTenGodsWidget extends StatelessWidget {
  final BaziChart chart;
  final Color elementColor;

  const BaziTenGodsWidget({
    super.key,
    required this.chart,
    required this.elementColor,
  });

  @override
  Widget build(BuildContext context) {
    final int dmIdx = chart.dayPillar.stemIndex;

    final List<({String label, BaziPillar? pillar, bool isSelf})> columns = [
      (label: '年', pillar: chart.yearPillar,  isSelf: false),
      (label: '月', pillar: chart.monthPillar, isSelf: false),
      (label: '日', pillar: chart.dayPillar,   isSelf: true),
      (label: '時', pillar: chart.hourPillar,  isSelf: false),
    ];

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '十神 ',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 14,
                  color: elementColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Ten Gods',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.white54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: columns
                .map((col) => Expanded(child: _GodChip(
                      col: col,
                      dmStemIndex: dmIdx,
                      elementColor: elementColor,
                    )))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _GodChip extends StatelessWidget {
  final ({String label, BaziPillar? pillar, bool isSelf}) col;
  final int dmStemIndex;
  final Color elementColor;

  const _GodChip({
    required this.col,
    required this.dmStemIndex,
    required this.elementColor,
  });

  @override
  Widget build(BuildContext context) {
    if (col.pillar == null) {
      // Hour pillar unknown
      return Column(
        children: [
          Text(col.label,
              style: GoogleFonts.outfit(fontSize: 10, color: Colors.white24)),
          const SizedBox(height: 4),
          Text('—',
              style: GoogleFonts.outfit(fontSize: 11, color: Colors.white24)),
        ],
      );
    }

    if (col.isSelf) {
      return Column(
        children: [
          Text(col.label,
              style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38)),
          const SizedBox(height: 4),
          Text('日主',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 13,
                  color: elementColor,
                  fontWeight: FontWeight.bold)),
          Text('Diri Sendiri',
              style: GoogleFonts.outfit(fontSize: 9, color: Colors.white38),
              textAlign: TextAlign.center),
        ],
      );
    }

    final String godId =
        BaziUtils.getTenGodId(dmStemIndex, col.pillar!.stemIndex);
    final (String hanzi, String nameId) =
        _kTenGodNames[godId] ?? ('?', godId);
    final Color color =
        kBaziElementColors[col.pillar!.element] ?? AppTheme.accentGold;

    return Column(
      children: [
        Text(col.label,
            style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38)),
        const SizedBox(height: 4),
        Text(hanzi,
            style: GoogleFonts.playfairDisplay(
                fontSize: 16, color: color, fontWeight: FontWeight.bold)),
        Text(nameId,
            style: GoogleFonts.outfit(fontSize: 9, color: Colors.white38),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
