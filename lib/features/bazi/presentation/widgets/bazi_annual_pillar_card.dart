import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/services/api_service.dart';
import '../../../../features/auth/services/auth_service.dart';
import '../../domain/bazi_chart.dart';
import 'bazi_pillar_column.dart' show kBaziElementColors;
import 'bazi_seasonal_roadmap.dart';
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
          // ── Seasonal Roadmap ─────────────────────────────────────────────
          const SizedBox(height: 14),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 14),
          BaziSeasonalRoadmap(natalChart: natalChart, year: now.year),
          // ── AI Annual Insight ──────────────────────────────────────────
          const SizedBox(height: 14),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 14),
          _AnnualAiInsightSection(
            chart: natalChart,
            annualPillar: annualPillar,
            year: now.year,
          ),
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

// ─── Annual AI Insight Section ─────────────────────────────────────────────

class _AnnualAiInsightSection extends ConsumerStatefulWidget {
  final BaziChart chart;
  final BaziPillar annualPillar;
  final int year;

  const _AnnualAiInsightSection({
    required this.chart,
    required this.annualPillar,
    required this.year,
  });

  @override
  ConsumerState<_AnnualAiInsightSection> createState() =>
      _AnnualAiInsightSectionState();
}

class _AnnualAiInsightSectionState
    extends ConsumerState<_AnnualAiInsightSection> {
  String? _insight;
  bool _loading = false;

  static String _cacheKey(int year, String dmId) =>
      'annual_ai_insight_${year}_$dmId';

  Future<void> _generate() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _cacheKey(widget.year, widget.chart.dayMasterId);

      // Check cache first (valid 1 year — annual pillar doesn't change)
      final cached = prefs.getString(key);
      if (cached != null) {
        if (mounted)
          setState(() {
            _insight = cached;
            _loading = false;
          });
        return;
      }

      final authHeader = await ref.read(authProvider.notifier).getAuthHeader();

      final prompt =
          'Tulis 3–4 kalimat tentang arti tahun ${widget.year} '
          '(${widget.annualPillar.stemNameId} ${widget.annualPillar.branchZodiacId}) '
          'untuk pengguna dengan Day Master ${widget.chart.dayMasterElement} '
          '(${widget.chart.dmStrength.label}). '
          'Yong Shen: ${widget.chart.dmStrength.yongShen.join(", ")}. '
          'Fokus: 1 peluang utama, 1 hal yang perlu diwaspadai, dan 1 rekomendasi aksi konkret. '
          'Nada empatik, psikologi modern, bukan ramalan buta.';

      final result = await ApiService.generateAiChat(
        prompt: prompt,
        authHeader: authHeader,
      );
      final text = result['response'] as String? ?? '';
      if (text.isNotEmpty) {
        await prefs.setString(key, text);
        if (mounted) setState(() => _insight = text);
      }
    } catch (e) {
      debugPrint('_AnnualAiInsightSection error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_insight != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '☯ Makna Tahun Ini untukmu',
                style: GoogleFonts.cinzel(
                  fontSize: 11,
                  color: AppTheme.accentGold,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove(
                    _cacheKey(widget.year, widget.chart.dayMasterId),
                  );
                  if (mounted) setState(() => _insight = null);
                },
                child: Text(
                  '↻',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _insight!,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.55,
            ),
          ),
        ],
      );
    }

    return Center(
      child: _loading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppTheme.accentGold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Menyusun makna tahun ini...',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppTheme.accentGold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            )
          : GestureDetector(
              onTap: _generate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.accentGold.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(
                      'Apa arti tahun ${widget.year} untukku?',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppTheme.accentGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
