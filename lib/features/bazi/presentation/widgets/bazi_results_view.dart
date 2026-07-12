import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cosmic_loader.dart';
import '../../domain/bazi_chart.dart';
import '../../services/bazi_data_service.dart';
import 'bazi_four_pillars_chart.dart';
import 'bazi_day_master_card.dart';
import 'bazi_element_balance_card.dart';
import 'bazi_pillar_column.dart' show kBaziElementColors;
import 'bazi_luck_pillars_widget.dart';
import 'bazi_ten_gods_widget.dart';
import 'bazi_strength_card.dart';
import 'bazi_relations_card.dart';
import 'bazi_annual_pillar_card.dart';
import 'bazi_pillar_detail_card.dart';
import 'bazi_luck_pillars_placeholder.dart';

/// Step 2 — hasil kalkulasi Ba Zi: loading / error / results view.
class BaziResultsView extends ConsumerWidget {
  final BaziChart? chart;
  final DateTime? birthDate;
  final bool isLoading;
  final String? errorMsg;
  // Derived analytical state
  final String? dmStrength;
  final List<String>? yongShen;
  final List<String>? jiShen;
  final List<int>? noblemen;
  final List<int>? emptyBranches;
  final BaziRelations? branchRelations;
  final BaziPillar? annualPillar;
  final BaziRelations? annualRelations;
  final List<LuckPillar>? luckPillars;
  final bool luckForward;
  // Callbacks
  final VoidCallback onRetry;
  final VoidCallback onConsultOracle;
  final VoidCallback onRecalculate;

  const BaziResultsView({
    super.key,
    required this.chart,
    required this.birthDate,
    required this.isLoading,
    this.errorMsg,
    this.dmStrength,
    this.yongShen,
    this.jiShen,
    this.noblemen,
    this.emptyBranches,
    this.branchRelations,
    this.annualPillar,
    this.annualRelations,
    this.luckPillars,
    this.luckForward = true,
    required this.onRetry,
    required this.onConsultOracle,
    required this.onRecalculate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── Loading ─────────────────────────────────────────────────────────
    if (isLoading) {
      return Center(
        key: const ValueKey('loading'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CosmicLoader(
              label: 'Memetakan langit kelahiranmu...',
            ),
          ],
        ),
      );
    }

    // ── Error ────────────────────────────────────────────────────────────
    if (chart == null) {
      return Center(
        key: const ValueKey('error'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(
              errorMsg ?? 'Gagal menghitung peta Ba Zi.',
              style: GoogleFonts.outfit(color: Colors.white60),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: const Text('Coba lagi',
                  style: TextStyle(color: AppTheme.accentGold)),
            ),
          ],
        ),
      );
    }

    // ── Results ──────────────────────────────────────────────────────────
    final mastersAsync  = ref.watch(baziDayMastersProvider);
    final pillarsAsync  = ref.watch(baziPillarsProvider);
    final godsAsync     = ref.watch(baziGodsProvider);
    final strengthAsync = ref.watch(baziStrengthLevelsProvider);

    final masterData   = mastersAsync.asData?.value.findById(chart!.dayMasterId);
    final pillarData   = pillarsAsync.asData?.value.findById(chart!.dayPillar.id);
    final godsData     = godsAsync.asData?.value;
    final strengthData = strengthAsync.asData?.value;

    final Color elementColor =
        kBaziElementColors[chart!.dayMasterElement] ?? AppTheme.accentGold;

    return SingleChildScrollView(
      key: const ValueKey('results'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Text(
                  'Peta Langit Kelahiran',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${birthDate!.day} / ${birthDate!.month} / ${birthDate!.year}',
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          BaziFourPillarsChart(chart: chart!),
          const SizedBox(height: 8),

          BaziTenGodsWidget(
              chart: chart!, elementColor: elementColor, godsData: godsData),
          const SizedBox(height: 16),

          if (dmStrength != null) ...[
            BaziStrengthCard(
              dayPillar:    chart!.dayPillar,
              monthPillar:  chart!.monthPillar,
              dmStrength:   dmStrength!,
              yongShen:     yongShen ?? [],
              jiShen:       jiShen ?? [],
              noblemen:     noblemen ?? [],
              allPillars:   chart!.allPillars,
              elementColor: elementColor,
              strengthData: strengthData,
            ),
            const SizedBox(height: 16),
          ],

          BaziDayMasterCard(dayPillar: chart!.dayPillar, masterData: masterData),
          const SizedBox(height: 16),

          BaziElementBalanceCard(balance: chart!.wuXingBalance),
          const SizedBox(height: 16),

          if (branchRelations != null && emptyBranches != null) ...[
            BaziBranchRelationsCard(
              relations:     branchRelations!,
              emptyBranches: emptyBranches!,
              pillars:       chart!.allPillars,
            ),
            const SizedBox(height: 16),
          ],

          if (annualPillar != null && annualRelations != null) ...[
            BaziAnnualPillarCard(
              annualPillar:    annualPillar!,
              natalChart:      chart!,
              annualRelations: annualRelations!,
            ),
            const SizedBox(height: 16),
          ],

          if (pillarData != null)
            BaziPillarDetailCard(data: pillarData, elementColor: elementColor),

          // AI Oracle section
          const SizedBox(height: 16),
          if (masterData?['ai_hook'] != null &&
              (masterData!['ai_hook'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                masterData['ai_hook'] as String,
                style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white38,
                    height: 1.6,
                    fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          _BaziPrimaryButton(
            label: '✦ Bicara dengan Suhu Wang',
            onTap: onConsultOracle,
            color: elementColor,
          ),

          // Luck Pillars
          const SizedBox(height: 16),
          luckPillars != null
              ? BaziLuckPillarsWidget(
                  pillars:      luckPillars!,
                  elementColor: elementColor,
                  isForward:    luckForward,
                  birthDate:    birthDate!,
                )
              : BaziLuckPillarsPlaceholder(elementColor: elementColor),

          // Recalculate
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: onRecalculate,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white38, size: 16),
            label: Text(
              'Hitung ulang dengan data berbeda',
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared primary button ────────────────────────────────────────────────────

class _BaziPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  const _BaziPrimaryButton({required this.label, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.accentPurple;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: onTap != null ? c.withValues(alpha: 0.85) : Colors.white12,
          boxShadow: onTap != null
              ? [BoxShadow(color: c.withValues(alpha: 0.35), blurRadius: 16)]
              : [],
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: onTap != null ? Colors.white : Colors.white30,
                  fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
