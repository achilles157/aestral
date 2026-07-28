import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/weton_utils.dart';
import '../../../../core/utils/bazi_utils.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/daily_synthesis_service.dart';
import '../../../../core/providers/birth_profile_provider.dart';
import '../../../../core/models/birth_profile.dart';
import '../../../../core/providers/shell_providers.dart';
import '../../../auth/services/auth_service.dart';
import '../../../bazi/providers/bazi_chart_provider.dart';
import '../../../bazi/domain/bazi_chart.dart';
import '../../../tarot/services/tarot_data.dart';
import '../../../weton/data/pranata_mangsa_repository.dart';

class SeasonalSynthesisCard extends ConsumerStatefulWidget {
  const SeasonalSynthesisCard({super.key});

  @override
  ConsumerState<SeasonalSynthesisCard> createState() =>
      _SeasonalSynthesisCardState();
}

class _SeasonalSynthesisCardState extends ConsumerState<SeasonalSynthesisCard> {
  String? _synthesis;
  bool _loading = false;
  bool _error = false;
  bool _isKosmisMode = false;

  // Ba Zi season elemen for current month
  String _baziSeasonElement = '';
  String _baziSeasonStatus = 'netral'; // 'yong' | 'ji' | 'netral'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String _getBaziSeasonElement() {
    final now = DateTime.now();
    final yearPillar = BaziUtils.getYearPillar(now.year, 3, 1);
    final monthPillar = BaziUtils.getMonthPillar(
      now.month,
      now.day,
      yearPillar.stemIndex,
      now.year,
    );
    return BaziUtils.branchElements[monthPillar.branchIndex];
  }

  String _getBaziSeasonStatus(BaziChart chart) {
    final elem = _getBaziSeasonElement();
    if (chart.dmStrength.yongShen.contains(elem)) return 'yong';
    if (chart.dmStrength.jiShen.contains(elem)) return 'ji';
    return 'netral';
  }

  String _getBaziSeasonLabel() {
    switch (_baziSeasonElement) {
      case 'kayu':
        return 'Musim Kayu 木';
      case 'api':
        return 'Musim Api 火';
      case 'logam':
        return 'Musim Logam 金';
      case 'air':
        return 'Musim Air 水';
      default:
        return 'Musim Tanah 土';
    }
  }

  LuckPillar? _getActiveLuckPillar(
    BaziChart chart,
    DateTime dob,
    String? gender,
  ) {
    final isMale = gender == 'male';
    final luckPillars = BaziUtils.calculateLuckPillars(
      birthDate: dob,
      monthPillar: chart.monthPillar,
      yearStemIndex: chart.yearPillar.stemIndex,
      isMale: isMale,
    );
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    try {
      return luckPillars.firstWhere(
        (lp) => age >= lp.startAge && age <= lp.endAge,
      );
    } catch (_) {
      return luckPillars.isNotEmpty ? luckPillars.first : null;
    }
  }

  Future<void> _load() async {
    final profile = ref.read(birthProfileProvider).value;
    if (profile?.dobDate == null) return;

    final now = DateTime.now();
    final mangsaId = WetonUtils.calculatePranataMangsaId(now);
    final isKosmis = await DailySynthesisService.isLastDrawKosmis();
    if (mounted) setState(() => _isKosmisMode = isKosmis);

    // Try cache
    final cached = await DailySynthesisService.getToday(
      mangsaId,
      now.year,
      withTarot: isKosmis,
    );
    if (cached != null && mounted) {
      setState(() => _synthesis = cached);
      return;
    }

    // Generate fresh
    if (mounted) setState(() => _loading = true);
    try {
      await _generate(profile!, mangsaId, isKosmis);
    } catch (e) {
      debugPrint('SeasonalSynthesisCard._load error: $e');
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generate(
    BirthProfile profile,
    int mangsaId,
    bool isKosmis,
  ) async {
    final authHeader = await ref.read(authProvider.notifier).getAuthHeader();
    final baziChart = ref.read(baziChartProvider).value;
    final drawnCards = ref.read(drawnCardProvider);
    final now = DateTime.now();

    // Pranata Mangsa data
    final mangsaList = await ref.read(pranataMangsaListProvider.future);
    final mangsa = mangsaList.firstWhere(
      (m) => m.id == mangsaId,
      orElse: () => mangsaList.first,
    );

    // Ba Zi season
    final seasonElem = _getBaziSeasonElement();
    final seasonLabel = _getBaziSeasonLabel();
    if (mounted) setState(() => _baziSeasonElement = seasonElem);
    final seasonStatus = baziChart != null
        ? _getBaziSeasonStatus(baziChart)
        : 'netral';
    if (mounted) setState(() => _baziSeasonStatus = seasonStatus);

    // Da Yun aktif (offline, zero API)
    String daYunLine = '';
    if (baziChart != null && profile.dobDate != null) {
      final activeLuck = _getActiveLuckPillar(
        baziChart,
        profile.dobDate!,
        profile.gender,
      );
      if (activeLuck != null) {
        final tenGodId = BaziUtils.getTenGodId(
          baziChart.dayPillar.stemIndex,
          activeLuck.pillar.stemIndex,
        );
        daYunLine =
            'Da Yun aktif: ${activeLuck.pillar.stemNameId} '
            '${activeLuck.pillar.branchZodiacId} '
            '(usia ${activeLuck.startAge}–${activeLuck.endAge}), '
            'Ten God: $tenGodId.';
      }
    }

    // Annual Pillar
    final annualPillar = BaziUtils.getCurrentAnnualPillar();
    final annualLine =
        'Pilar Tahunan ${now.year}: ${annualPillar.stemNameId} '
        '${annualPillar.branchZodiacId} (${annualPillar.element}).';

    // Tarot Kosmis (only if mangsa-mode draw)
    final tarotLine = (isKosmis && drawnCards != null && drawnCards.isNotEmpty)
        ? 'Kartu Tarot Kosmis: '
              '${drawnCards.map((c) => '${c.card.nameId} [${c.label}] — '
                  '${c.card.archetypeId}, elemen ${c.card.elementalId}').join('; ')}.'
        : '';

    // Ba Zi Day Master
    final dmLine = baziChart != null
        ? 'Day Master Ba Zi: ${baziChart.dayMasterElement} '
              '(${baziChart.dmStrength.label}). '
              'Musim ${seasonElem.toUpperCase()} = '
              '${seasonStatus == 'yong'
                  ? 'Yong Shen (menguntungkan)'
                  : seasonStatus == 'ji'
                  ? 'Ji Shen (tantangan)'
                  : 'Netral'}.'
        : '';

    final prompt =
        'Tulis sintesis kosmis musiman dalam 4–5 kalimat Bahasa Indonesia.\n\n'
        '## Babak Besar: $seasonLabel\n'
        '$dmLine\n'
        '$annualLine\n'
        '$daYunLine\n\n'
        '## Pranata Mangsa ${mangsa.id}: ${mangsa.namaMangsa}\n'
        'Candra: ${mangsa.candraMangsa}\n'
        'Arketipe: ${mangsa.arketipeModern}\n'
        'Karakter Energi: ${mangsa.karakterEnergi}\n\n'
        '${tarotLine.isNotEmpty ? '## Tarot Kosmis\n$tarotLine\n\n' : ''}'
        'Tenun ketiga sistem (Ba Zi musim + Pranata Mangsa'
        '${tarotLine.isNotEmpty ? ' + Tarot Kosmis' : ''}) '
        'menjadi 1 narasi kohesif yang personal, konkret, dan memberdayakan. '
        'Berikan gambaran kondisi makro musim ini dan apa yang perlu '
        'difokuskan user. Bukan ramalan buta — gaya psikologi modern.';

    final result = await ApiService.generateAiChat(
      prompt: prompt,
      authHeader: authHeader,
    );
    final text = result['response'] as String? ?? '';
    if (text.isEmpty) throw Exception('Empty response');

    await DailySynthesisService.save(
      mangsaId,
      now.year,
      text,
      withTarot: isKosmis,
    );
    if (mounted) setState(() => _synthesis = text);
  }

  Future<void> _refresh() async {
    final now = DateTime.now();
    final mangsaId = WetonUtils.calculatePranataMangsaId(now);
    await DailySynthesisService.invalidate(mangsaId, now.year);
    if (mounted) {
      setState(() {
        _synthesis = null;
        _error = false;
      });
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(birthProfileProvider).value;
    if (profile?.dobDate == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final mangsaId = WetonUtils.calculatePranataMangsaId(now);
    final baziChart = ref.watch(baziChartProvider).value;
    final drawnCards = ref.watch(drawnCardProvider);
    final seasonLabel = _getBaziSeasonLabel();
    final statusColor = _baziSeasonStatus == 'yong'
        ? Colors.greenAccent.shade400
        : _baziSeasonStatus == 'ji'
        ? const Color(0xFFF87171)
        : Colors.white38;

    return GlassCard(
      borderColor: AppTheme.accentPurple.withValues(alpha: 0.25),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────
          Row(
            children: [
              Text(
                '🌙 Kondisi Kosmis',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: AppTheme.accentPurple,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                'Pranata $mangsaId',
                style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 7),

          // ── Context chips ──────────────────────────────────────────
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _Chip(seasonLabel, AppTheme.accentGold),
              if (_baziSeasonStatus != 'netral')
                _Chip(
                  _baziSeasonStatus == 'yong' ? '✦ Yong Shen' : '⚡ Ji Shen',
                  statusColor,
                ),
              if (baziChart != null)
                _Chip(
                  '${baziChart.dayMasterElement.toUpperCase()} · '
                  '${baziChart.dmStrength.label}',
                  Colors.white38,
                ),
              if (_isKosmisMode && drawnCards != null && drawnCards.isNotEmpty)
                _Chip(
                  '🃏 ${drawnCards.first.card.nameId}',
                  AppTheme.accentPurple.withValues(alpha: 0.9),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Content ────────────────────────────────────────────────
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
          else if (!_isKosmisMode)
            _TarotCta(onRefresh: _refresh)
          else
            _LoadingPlaceholder(),

          // ── Footer ─────────────────────────────────────────────────
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
                  onTap: () => ref.read(activeTabProvider.notifier).setTab(0),
                  child: Text(
                    'Perdalam dengan Sesepuh →',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: AppTheme.accentPurple.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                    ),
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
      children: [0.95, 0.85, 0.70, 0.55].map((w) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Container(
            height: 12,
            width: MediaQuery.of(context).size.width * w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }).toList(),
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
          'Gagal memuat kondisi kosmis.',
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

class _TarotCta extends StatelessWidget {
  final VoidCallback onRefresh;
  const _TarotCta({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sintesis musiman siap dibuat dari Ba Zi + Pranata Mangsa.',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.white54,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onRefresh,
          child: Text(
            '✨ Draw Tarot Kosmis untuk sintesis yang lebih personal →',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: AppTheme.accentPurple.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'Memuat kondisi kosmis musim ini...',
      style: GoogleFonts.outfit(
        fontSize: 12,
        color: Colors.white38,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
