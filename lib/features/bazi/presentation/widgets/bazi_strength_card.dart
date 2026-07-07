import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/bazi_chart.dart';
import 'bazi_pillar_column.dart' show kBaziElementColors;
import 'bazi_shared_constants.dart';

/// Displays Day Master Strength (旺衰), Favorable (用神), Unfavorable (忌神)
/// elements, and Nobleman Star (天乙貴人) presence in the natal chart.
class BaziStrengthCard extends StatelessWidget {
  final BaziPillar dayPillar;
  final BaziPillar monthPillar;
  final String dmStrength;
  final List<String> yongShen;
  final List<String> jiShen;
  final List<int> noblemen;           // branch indices
  final List<BaziPillar?> allPillars; // to check nobleman presence
  final Color elementColor;
  /// Optional from baziStrengthLevelsProvider — falls back to hardcoded
  /// _strengthLevels / _strengthDesc if null.
  final List<Map<String, dynamic>>? strengthData;

  const BaziStrengthCard({
    super.key,
    required this.dayPillar,
    required this.monthPillar,
    required this.dmStrength,
    required this.yongShen,
    required this.jiShen,
    required this.noblemen,
    required this.allPillars,
    required this.elementColor,
    this.strengthData,
  });

  static const _strengthLevels = [
    'Sangat Lemah', 'Lemah', 'Sedang', 'Kuat', 'Sangat Kuat',
  ];

  static const _strengthDesc = {
    'Sangat Kuat':  'DM sangat dominan — butuh elemen penyeimbang',
    'Kuat':         'DM kuat — elemen penopang berlimpah',
    'Sedang':       'DM seimbang — chart relatif harmonis',
    'Lemah':        'DM lemah — perlu penguatan dari lingkungan',
    'Sangat Lemah': 'DM sangat lemah — butuh banyak dukungan',
  };

  @override
  Widget build(BuildContext context) {
    // Use JSON data if provided, fall back to hardcoded constants
    final levels = strengthData?.map((e) => e['label'] as String).toList()
        ?? _strengthLevels;
    final desc = (strengthData?.firstWhere(
              (e) => e['id'] == dmStrength,
              orElse: () => <String, dynamic>{},
            )['deskripsi'] as String?)
        ?? _strengthDesc[dmStrength]
        ?? '';
    final activeIdx = levels.indexOf(dmStrength);
    final presentBranches = allPillars
        .where((p) => p != null)
        .map((p) => p!.branchIndex)
        .toSet();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(children: [
            Text('☯', style: TextStyle(fontSize: 16, color: elementColor)),
            const SizedBox(width: 8),
            Text(
              '旺衰 · Kekuatan Hari Master',
              style: GoogleFonts.playfairDisplay(
                fontSize: 14,
                color: AppTheme.accentGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]),
          const SizedBox(height: 14),

          // ── Strength Gauge ───────────────────────────────────────────────
          Row(
            children: List.generate(levels.length, (i) {
              final isActive = i == activeIdx;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 4 ? 3 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? elementColor.withValues(alpha: 0.25)
                        : AppTheme.cardBg.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isActive
                          ? elementColor.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.06),
                      width: isActive ? 1.2 : 0.8,
                    ),
                  ),
                  child: Text(
                    levels[i],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 9.5,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                      color: isActive
                          ? elementColor
                          : AppTheme.textMuted.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: AppTheme.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          // ── Yong Shen 用神 ───────────────────────────────────────────────
          _sectionLabel('用神 · Elemen Menguntungkan', Colors.greenAccent.shade400),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: yongShen.map((el) => _elChip(el, favorable: true)).toList(),
          ),
          const SizedBox(height: 14),

          // ── Ji Shen 忌神 ────────────────────────────────────────────────
          _sectionLabel('忌神 · Elemen Kurang Menguntungkan', Colors.redAccent.shade200),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: jiShen.map((el) => _elChip(el, favorable: false)).toList(),
          ),
          const SizedBox(height: 14),

          // ── Nobleman 貴人 ────────────────────────────────────────────────
          _sectionLabel('天乙貴人 · Nobleman Star', AppTheme.accentGold),
          const SizedBox(height: 8),
          Row(
            children: noblemen.map((branchIdx) {
              final inChart = presentBranches.contains(branchIdx);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: inChart
                        ? AppTheme.accentGold.withValues(alpha: 0.15)
                        : AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: inChart
                          ? AppTheme.accentGold.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        kBaziBranchSymbol[branchIdx],
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          color: inChart
                              ? AppTheme.accentGold
                              : AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kBaziBranchName[branchIdx],
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: inChart
                                  ? AppTheme.textLight
                                  : AppTheme.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (inChart)
                            Text(
                              'Ada di chart ✦',
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                color: AppTheme.accentGold,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) => Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      );

  Widget _elChip(String el, {required bool favorable}) {
    final color = kBaziElementColors[el] ?? AppTheme.textMuted;
    final label = kBaziElementLabel[el] ?? el;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: favorable
            ? color.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: favorable
              ? color.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          color: favorable ? color : AppTheme.textMuted,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
