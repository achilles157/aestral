import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/bazi_chart.dart';
import 'bazi_pillar_column.dart' show kBaziElementColors;

/// Displays the 8 Luck Pillars (大運) as a horizontal scrollable row of cards.
class BaziLuckPillarsWidget extends StatelessWidget {
  final List<LuckPillar> pillars;
  final Color elementColor;

  /// true = 顺运 (forward), false = 逆运 (backward)
  final bool isForward;

  const BaziLuckPillarsWidget({
    super.key,
    required this.pillars,
    required this.elementColor,
    required this.isForward,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                '大運 ',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  color: elementColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Luck Pillars',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _directionChip(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Mulai usia ${pillars.first.startAge} · Siklus 10 tahun',
            style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38),
          ),
          const SizedBox(height: 14),

          // Pillar cards
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: pillars
                  .map((lp) => _LuckPillarCard(lp: lp))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _directionChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: elementColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: elementColor.withOpacity(0.3)),
        ),
        child: Text(
          isForward ? '顺运' : '逆运',
          style: GoogleFonts.outfit(
            fontSize: 10,
            color: elementColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class _LuckPillarCard extends StatelessWidget {
  final LuckPillar lp;
  const _LuckPillarCard({required this.lp});

  @override
  Widget build(BuildContext context) {
    final Color color =
        kBaziElementColors[lp.pillar.element] ?? AppTheme.accentGold;
    return Container(
      width: 62,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          // Age range
          Text(
            '${lp.startAge}–${lp.endAge}',
            style: GoogleFonts.outfit(
              fontSize: 9,
              color: Colors.white38,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          // Stem
          Text(
            lp.pillar.stemSymbol,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Branch
          Text(
            lp.pillar.branchSymbol,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              color: color.withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lp.pillar.branchZodiacId,
            style: GoogleFonts.outfit(fontSize: 8, color: Colors.white38),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
