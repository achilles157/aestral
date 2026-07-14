import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/bazi_chart.dart';
import 'bazi_pillar_column.dart' show kBaziElementColors;
import 'bazi_shared_constants.dart';

/// Displays Six Clashes (六冲), Six Harmonies (六合), Three Harmonies (三合),
/// and Empty Branches (空亡) detected within the chart.
class BaziBranchRelationsCard extends StatelessWidget {
  final BaziRelations relations;
  final List<int> emptyBranches;
  final List<BaziPillar?> pillars; // 0=Tahun,1=Bulan,2=Hari,3=Jam

  const BaziBranchRelationsCard({
    super.key,
    required this.relations,
    required this.emptyBranches,
    required this.pillars,
  });

  @override
  Widget build(BuildContext context) {
    final hasContent = !relations.isEmpty || emptyBranches.isNotEmpty;
    if (!hasContent) return const SizedBox.shrink();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Text(
            '⚡ Interaksi Pilar · Branch Relations',
            style: GoogleFonts.playfairDisplay(
              fontSize: 14,
              color: AppTheme.accentGold,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),

          // ── Six Clashes 六冲 ────────────────────────────────────────────
          if (relations.clashes.isNotEmpty) ...[
            _sectionLabel('六冲 · Six Clashes', const Color(0xFFF87171)),
            _helpText(
              'Oposisi langsung antara dua zodiak. Menciptakan tekanan atau perubahan mendadak di area pilar yang terlibat — bukan kutukan, sering justru pemicu transformasi terbesar.',
            ),
            ...relations.clashes.map((c) => _clashRow(c)),
            const SizedBox(height: 14),
          ],

          // ── Six Harmonies 六合 ──────────────────────────────────────────
          if (relations.harmonies.isNotEmpty) ...[
            _sectionLabel('六合 · Six Harmonies', AppTheme.accentGold),
            _helpText(
              'Pasangan alami yang sangat selaras — dua zodiak yang berpasangan mengalirkan energi lancar di area pilar yang diwakilinya.',
            ),
            ...relations.harmonies.map((h) => _harmonyRow(h)),
            const SizedBox(height: 14),
          ],

          // ── Three Harmonies 三合 ────────────────────────────────────────
          if (relations.triads.isNotEmpty) ...[
            _sectionLabel('三合 · Three Harmonies', const Color(0xFF60A5FA)),
            _helpText(
              'Koalisi tiga zodiak yang membentuk elemen baru secara kolektif. Semakin lengkap ketiga pilarnya, semakin kuat energi yang terbentuk.',
            ),
            ...relations.triads.map((t) => _triadRow(t)),
            const SizedBox(height: 14),
          ],

          // ── Empty Branches 空亡 ─────────────────────────────────────────
          _sectionLabel('空亡 · Empty Branches', AppTheme.textMuted),
          _helpText(
            'Zona kosong spiritual — area kehidupan di mana ambisi materi perlu dilepaskan. Paradoksnya, melepas di area ini justru membuka jalan kebijaksanaan dan kedamaian batin.',
          ),
          const SizedBox(height: 8),
          _emptyBranchesRow(),
        ],
      ),
    );
  }

  Widget _clashRow(BaziClash c) {
    final pA = _pillarAt(c.indexA);
    final pB = _pillarAt(c.indexB);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          _pillarBadge(c.indexA, pA),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '⚡',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFFF87171).withValues(alpha: 0.9),
              ),
            ),
          ),
          _pillarBadge(c.indexB, pB),
          const SizedBox(width: 8),
          Text(
            'Bentrok',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: const Color(0xFFF87171).withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _harmonyRow(BaziHarmony h) {
    final resultColor =
        kBaziElementColors[h.resultElement] ?? AppTheme.accentGold;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          _pillarBadge(h.indexA, _pillarAt(h.indexA)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '✦',
              style: TextStyle(fontSize: 14, color: Color(0xFFFBBF24)),
            ),
          ),
          _pillarBadge(h.indexB, _pillarAt(h.indexB)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: resultColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: resultColor.withValues(alpha: 0.35)),
            ),
            child: Text(
              '→ ${kBaziElementLabel[h.resultElement] ?? h.resultElement}',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: resultColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _triadRow(BaziTriad t) {
    final elColor = kBaziElementColors[t.element] ?? AppTheme.accentPurple;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          ...t.pillarIndices.map(
            (idx) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _pillarBadge(idx, _pillarAt(idx)),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: elColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: elColor.withValues(alpha: 0.35)),
            ),
            child: Text(
              '${t.isComplete ? "✓" : "~"} ${kBaziElementLabel[t.element] ?? t.element} ${t.isComplete ? "Lengkap" : "Parsial"}',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: elColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyBranchesRow() {
    // Which natal pillars contain empty branches
    final affectedLabels = <String>[];
    for (int i = 0; i < pillars.length; i++) {
      final p = pillars[i];
      if (p != null && emptyBranches.contains(p.branchIndex)) {
        affectedLabels.add(kBaziPillarLabels[i]);
      }
    }

    return Row(
      children: [
        ...emptyBranches.map(
          (b) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    kBaziBranchSymbol[b],
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    kBaziBranchName[b],
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (affectedLabels.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(
            '← terdampak di: ${affectedLabels.join(", ")}',
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: AppTheme.textMuted.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ] else
          Text(
            'Tidak ada pilar yang terdampak',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: AppTheme.textMuted.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  }

  Widget _pillarBadge(int idx, BaziPillar? pillar) {
    final label = idx < kBaziPillarLabels.length ? kBaziPillarLabels[idx] : '?';
    final symbol = pillar != null ? pillar.branchSymbol : '?';
    final color = pillar != null
        ? (kBaziElementColors[pillar.element] ?? AppTheme.textMuted)
        : AppTheme.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            symbol,
            style: GoogleFonts.playfairDisplay(fontSize: 14, color: color),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  BaziPillar? _pillarAt(int idx) =>
      (idx >= 0 && idx < pillars.length) ? pillars[idx] : null;

  Widget _sectionLabel(String text, Color color) => Text(
    text,
    style: GoogleFonts.outfit(
      fontSize: 10,
      color: color,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    ),
  );

  Widget _helpText(String text) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 8),
    child: Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 11,
        color: AppTheme.textMuted.withValues(alpha: 0.75),
        fontStyle: FontStyle.italic,
        height: 1.4,
      ),
    ),
  );
}
