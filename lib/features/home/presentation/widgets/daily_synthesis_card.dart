import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/weton_utils.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/daily_synthesis_service.dart';
import '../../../../core/providers/birth_profile_provider.dart';
import '../../../../core/providers/shell_providers.dart';
import '../../../auth/services/auth_service.dart';
import '../../../bazi/providers/bazi_chart_provider.dart';
import '../../../tarot/services/tarot_data.dart';

class DailySynthesisCard extends ConsumerStatefulWidget {
  const DailySynthesisCard({super.key});

  @override
  ConsumerState<DailySynthesisCard> createState() => _DailySynthesisCardState();
}

class _DailySynthesisCardState extends ConsumerState<DailySynthesisCard> {
  String? _synthesis;
  bool _loading = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final profile = ref.read(birthProfileProvider).value;
    if (profile?.dobDate == null) return;

    final todayWeton = WetonUtils.calculateWeton(DateTime.now());

    // 1. Try cache first
    final cached = await DailySynthesisService.getToday(todayWeton.wuku);
    if (cached != null && mounted) {
      setState(() => _synthesis = cached);
      return;
    }

    // 2. Generate fresh
    if (mounted) setState(() => _loading = true);
    try {
      await _generate(profile!.dobDate!, todayWeton);
    } catch (e) {
      debugPrint('DailySynthesisCard._load error: $e');
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generate(DateTime dob, WetonInfo todayWeton) async {
    final authHeader = await ref.read(authProvider.notifier).getAuthHeader();
    final baziChart = ref.read(baziChartProvider).value;
    final drawnCards = ref.read(drawnCardProvider);
    final profile = ref.read(birthProfileProvider).value;

    // Build compact but rich prompt
    final birthWeton = profile?.weton;
    final isBaziYong =
        baziChart?.dmStrength.yongShen.contains(
          WetonUtils.calculateWeton(DateTime.now()).saptawara.toLowerCase(),
        ) ??
        false;

    final baziLine = baziChart != null
        ? 'Day Master Ba Zi: ${baziChart.dayMasterElement} '
              '(${baziChart.dmStrength.label}). '
              'Elemen Yong Shen: ${baziChart.dmStrength.yongShen.join(", ")}.'
        : '';

    final tarotLine = (drawnCards != null && drawnCards.isNotEmpty)
        ? 'Kartu Tarot terpilih: '
              '${drawnCards.map((c) => '${c.card.nameId} (${c.label})').join(", ")}.'
        : '';

    final wetonKarakter = birthWeton?.characterSummary ?? '';

    final prompt =
        'Buatkan briefing kosmis harian personal dalam 3–4 kalimat Bahasa Indonesia.\n'
        'Weton lahir: ${birthWeton?.saptawara ?? ""} ${birthWeton?.pancawara ?? ""}'
        '${wetonKarakter.isNotEmpty ? " — $wetonKarakter" : ""}.\n'
        'Weton hari ini: ${todayWeton.saptawara} ${todayWeton.pancawara}, '
        'neptu ${todayWeton.totalNeptu}, Wuku ${todayWeton.wuku}.\n'
        '${baziLine.isNotEmpty ? "$baziLine\n" : ""}'
        '${tarotLine.isNotEmpty ? "$tarotLine\n" : ""}'
        'Tenun ketiga sistem ini menjadi 1 narasi personal yang kohesif, '
        'empatik, mencerahkan, dan konkret. Bukan ramalan buta.';

    final result = await ApiService.generateAiChat(
      prompt: prompt,
      authHeader: authHeader,
    );
    final text = result['response'] as String? ?? '';
    if (text.isEmpty) throw Exception('Empty response');

    await DailySynthesisService.save(todayWeton.wuku, text);
    if (mounted) setState(() => _synthesis = text);
  }

  Future<void> _refresh() async {
    final profile = ref.read(birthProfileProvider).value;
    if (profile?.dobDate == null) return;
    final todayWeton = WetonUtils.calculateWeton(DateTime.now());
    await DailySynthesisService.invalidateToday(todayWeton.wuku);
    setState(() {
      _synthesis = null;
      _error = false;
    });
    await _load();
  }

  void _openSesepuh() {
    ref.read(activeTabProvider.notifier).setTab(0);
    // Sesepuh is on dashboard — scroll handled by DashboardSesepuhCard itself
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(birthProfileProvider).value;
    if (profile?.dobDate == null) return const SizedBox.shrink();

    final todayWeton = WetonUtils.calculateWeton(DateTime.now());
    final dateFmt = DateFormat('EEEE, d MMM', 'id');
    final baziChart = ref.watch(baziChartProvider).value;
    final drawnCards = ref.watch(drawnCardProvider);

    return GlassCard(
      borderColor: AppTheme.accentPurple.withValues(alpha: 0.25),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Row(
            children: [
              Text(
                '✦ Briefing Kosmis',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: AppTheme.accentPurple,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                dateFmt.format(DateTime.now()),
                style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // ── Context chips ────────────────────────────────────────────
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _Chip(
                '${todayWeton.saptawara} ${todayWeton.pancawara}',
                Colors.white38,
              ),
              _Chip('Wuku ${todayWeton.wuku}', AppTheme.accentGold),
              if (baziChart != null)
                _Chip(
                  baziChart.dmStrength.yongShen.isNotEmpty
                      ? '✦ Yong Shen'
                      : '≈ Ba Zi',
                  baziChart.dmStrength.yongShen.isNotEmpty
                      ? Colors.greenAccent.shade400
                      : Colors.white38,
                ),
              if (drawnCards != null && drawnCards.isNotEmpty)
                _Chip(
                  '🃏 ${drawnCards.first.card.nameId}',
                  AppTheme.accentPurple.withValues(alpha: 0.9),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Content ──────────────────────────────────────────────────
          if (_loading)
            _ShimmerLines()
          else if (_error)
            _ErrorState(onRetry: _refresh)
          else if (_synthesis != null)
            Text(
              _synthesis!,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.88),
                height: 1.55,
              ),
            )
          else
            _InsufficientDataState(hasBazi: baziChart != null),

          // ── Footer actions ───────────────────────────────────────────
          if (_synthesis != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _refresh,
                  child: Text(
                    '↻ Perbarui',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: Colors.white24,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Navigate to Sesepuh Kosmis tab
                    ref.read(activeTabProvider.notifier).setTab(0);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Perdalam dengan Sesepuh →',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: AppTheme.accentPurple.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ShimmerLines extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final width in [0.95, 0.80, 0.65])
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              height: 12,
              width: MediaQuery.of(context).size.width * width,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Gagal memuat briefing.',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.white38,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onRetry,
          child: Text(
            'Coba lagi',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.accentPurple.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _InsufficientDataState extends StatelessWidget {
  final bool hasBazi;
  const _InsufficientDataState({required this.hasBazi});

  @override
  Widget build(BuildContext context) {
    return Text(
      hasBazi
          ? 'Briefing kosmis sedang disiapkan...'
          : 'Lengkapi Ba Zi untuk briefing 3-tradisi yang lebih personal.',
      style: GoogleFonts.outfit(
        fontSize: 12,
        color: Colors.white38,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
