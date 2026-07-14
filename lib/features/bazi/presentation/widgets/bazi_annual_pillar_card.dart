import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/bazi_chart.dart';
import 'bazi_pillar_column.dart' show kBaziElementColors;
import 'bazi_shared_constants.dart';

/// Displays the current year's Annual Pillar (流年) and its interaction
/// with the natal chart (clashes / harmonies / element match).
class BaziAnnualPillarCard extends StatelessWidget {
  final BaziPillar annualPillar;
  final BaziChart natalChart;

  /// Relations computed from [...natalPillars, annualPillar].
  /// Index 4 = annual pillar. Any clash/harmony involving index 4
  /// is an interaction between the annual year and the natal chart.
  final BaziRelations annualRelations;

  const BaziAnnualPillarCard({
    super.key,
    required this.annualPillar,
    required this.natalChart,
    required this.annualRelations,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final annualColor =
        kBaziElementColors[annualPillar.element] ?? AppTheme.accentGold;
    final isSameDmElement = annualPillar.element == natalChart.dayMasterElement;

    // Interactions: clashes and harmonies where one pillar is index 4 (annual)
    final annualClashes = annualRelations.clashes
        .where((c) => c.indexA == 4 || c.indexB == 4)
        .toList();
    final annualHarmonies = annualRelations.harmonies
        .where((h) => h.indexA == 4 || h.indexB == 4)
        .toList();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Row(
            children: [
              Text(
                '流年',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  color: annualColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilar Tahun Ini · ${now.year}',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 14,
                        color: AppTheme.accentGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Annual Pillar',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Pillar Display ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: annualColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: annualColor.withValues(alpha: 0.30)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Stem
                Column(
                  children: [
                    Text(
                      annualPillar.stemSymbol,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 42,
                        color: annualColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      annualPillar.stemNameId,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: annualColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: 1,
                    height: 60,
                    color: annualColor.withValues(alpha: 0.20),
                  ),
                ),
                // Branch
                Column(
                  children: [
                    Text(
                      annualPillar.branchSymbol,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 42,
                        color: annualColor.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      annualPillar.branchZodiacId,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: annualColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Element badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: annualColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: annualColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    kBaziElementLabel[annualPillar.element] ??
                        annualPillar.element,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: annualColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Same as Day Master badge ────────────────────────────────────
          if (isSameDmElement)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: annualColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: annualColor.withValues(alpha: 0.35)),
              ),
              child: Text(
                '✦ Tahun ini berelemen sama dengan Hari Master anda',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: annualColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // ── Clashes with natal ──────────────────────────────────────────
          if (annualClashes.isNotEmpty) ...[
            if (isSameDmElement) const SizedBox(height: 10),
            _sectionLabel(
              '⚡ Bentrok dengan chart natal',
              const Color(0xFFF87171),
            ),
            const SizedBox(height: 6),
            ...annualClashes.map((c) {
              final natalIdx = c.indexA == 4 ? c.indexB : c.indexA;
              final natalLabel = natalIdx < kBaziPillarLabels.length
                  ? kBaziPillarLabels[natalIdx]
                  : '?';
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '流年 ↔ Pilar $natalLabel — perlu ekstra kehati-hatian',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFFF87171).withValues(alpha: 0.85),
                  ),
                ),
              );
            }),
            const SizedBox(height: 6),
            _guidanceText(
              'Tahun clash bukan tahun buruk — ini tahun bertekanan tinggi yang mendorong perubahan. Hindari keputusan besar yang terburu-buru, tapi jangan terlalu pasif.',
              const Color(0xFFF87171),
            ),
          ],

          // ── Harmonies with natal ────────────────────────────────────────
          if (annualHarmonies.isNotEmpty) ...[
            const SizedBox(height: 10),
            _sectionLabel('✦ Harmoni dengan chart natal', AppTheme.accentGold),
            const SizedBox(height: 6),
            ...annualHarmonies.map((h) {
              final natalIdx = h.indexA == 4 ? h.indexB : h.indexA;
              final natalLabel = natalIdx < kBaziPillarLabels.length
                  ? kBaziPillarLabels[natalIdx]
                  : '?';
              final elColor =
                  kBaziElementColors[h.resultElement] ?? AppTheme.accentGold;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '流年 ↔ Pilar $natalLabel — membentuk ${kBaziElementLabel[h.resultElement] ?? h.resultElement}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: elColor.withValues(alpha: 0.9),
                  ),
                ),
              );
            }),
            const SizedBox(height: 6),
            _guidanceText(
              'Tahun harmoni membawa arus yang mengalir lancar — waktu yang baik untuk membangun, berkolaborasi, dan memperluas.',
              AppTheme.accentGold,
            ),
          ],

          // ── No interaction ──────────────────────────────────────────────
          if (annualClashes.isEmpty &&
              annualHarmonies.isEmpty &&
              !isSameDmElement) ...[
            Text(
              'Tidak ada interaksi langsung dengan pilar natal.',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppTheme.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _guidanceText(String text, Color color) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 11,
        color: color.withValues(alpha: 0.65),
        fontStyle: FontStyle.italic,
        height: 1.4,
      ),
    ),
  );

  Widget _sectionLabel(String text, Color color) => Text(
    text,
    style: GoogleFonts.outfit(
      fontSize: 10,
      color: color,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
    ),
  );
}
