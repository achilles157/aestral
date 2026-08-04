import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/utils/bazi_utils.dart';
import '../../domain/bazi_chart.dart';
import 'bazi_pillar_column.dart' show kBaziElementColors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../../../../features/auth/services/auth_service.dart';
import '../../../../core/providers/birth_profile_provider.dart';

const Map<String, (String, String, String)> _kTenGodInfo = {
  'friend': (
    '比肩',
    'Sahabat / Identitas Diri',
    'Fokus pada pembentukan karakter mandiri, jaringan kawan sebaya, dan pemantapan posisi di lingkungan sosial.',
  ),
  'rob_wealth': (
    '劫財',
    'Penantang / Kemandirian Disiplin',
    'Fokus pada pengerasan mental, persaingan sehat, serta disiplin pengelolaan keuangan agar tidak tergerus konsumerisme.',
  ),
  'eating_god': (
    '食神',
    'Pencipta / Ekspresi Bebas',
    'Fokus pada kebebasan berkreasi, kenikmatan hidup, pengembangan ide mandiri, serta membangun kenyamanan berkarya.',
  ),
  'hurting_officer': (
    '傷官',
    'Visioner / Terobosan Unik',
    'Fokus pada mendobrak batasan konvensional, keberanian membuktikan gagasan baru, dan mengekspresikan bakat otentik.',
  ),
  'indirect_wealth': (
    '偏財',
    'Jaring Peluang / Bisnis Bebas',
    'Fokus pada menangkap peluang finansial dinamis, keberanian mengambil risiko terukur, dan perputaran arus kas.',
  ),
  'direct_wealth': (
    '正財',
    'Pembangun / Akumulasi Realita',
    'Fokus pada membangun penghasilan rutin yang stabil, disiplin finansial, serta akumulasi aset fisik jangka panjang.',
  ),
  'seven_killings': (
    '七殺',
    'Pendobrak / Ujian Keberanian',
    'Fokus pada menghadapi tekanan tinggi, terobosan saat krisis, kepemimpinan tegas, dan pengerasan daya tahan jiwa.',
  ),
  'direct_officer': (
    '正官',
    'Penjaga / Otoritas & Karir',
    'Fokus pada kepatuhan aturan, membangun reputasi profesional, promosi posisi, serta integrasi dalam struktur organisasi.',
  ),
  'indirect_resource': (
    '偏印',
    'Filsuf / Kebijaksanaan Laten',
    'Fokus pada pendalaman keahlian spesifik/unik, riset strategis, intuisi batin, dan keheningan untuk bertumbuh.',
  ),
  'direct_resource': (
    '正印',
    'Pustaka / Penopang Intelektual',
    'Fokus pada penyerapan ilmu pengetahuan, dukungan mentor/keluarga, reputasi bersih, dan penguatan fondasi mental.',
  ),
};

/// Displays the 8 Luck Pillars (大運) as a horizontal scrollable row of cards.
/// The currently active pillar (based on [birthDate]) is highlighted & auto-scrolled into view.
class BaziLuckPillarsWidget extends ConsumerStatefulWidget {
  final List<LuckPillar> pillars;
  final Color elementColor;
  final bool isForward;
  final DateTime birthDate;
  final BaziChart? chart;

  const BaziLuckPillarsWidget({
    super.key,
    required this.pillars,
    required this.elementColor,
    required this.isForward,
    required this.birthDate,
    this.chart,
  });

  @override
  ConsumerState<BaziLuckPillarsWidget> createState() =>
      _BaziLuckPillarsWidgetState();
}

class _BaziLuckPillarsWidgetState extends ConsumerState<BaziLuckPillarsWidget> {
  late final ScrollController _scrollCtrl;

  // Phase 2: Cache AI readings per pillar startAge
  final Map<int, String> _aiReadings = {};
  final Set<int> _loadingAi = {};
  final Set<int> _aiErrors = {}; // error state terpisah dari readings

  static String _aiCacheKey(String dmId, int startAge) =>
      'bazi_dayun_ai_${dmId}_$startAge';

  int _currentAge() {
    final now = DateTime.now();
    int age = now.year - widget.birthDate.year;
    if (now.month < widget.birthDate.month ||
        (now.month == widget.birthDate.month &&
            now.day < widget.birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.pillars.isEmpty) return;
      final age = _currentAge();
      final activeIdx = widget.pillars.indexWhere(
        (lp) => age >= lp.startAge && age <= lp.endAge,
      );
      if (activeIdx > 0 && _scrollCtrl.hasClients) {
        // W10: guard hasContentDimensions before accessing maxScrollExtent
        if (!_scrollCtrl.position.hasContentDimensions) return;
        const double cardWidth = 74.0; // 66px card + 8px margin
        final targetOffset = (activeIdx * cardWidth) - 20.0;
        _scrollCtrl.animateTo(
          targetOffset.clamp(0.0, _scrollCtrl.position.maxScrollExtent),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  // --- Phase 1: Synthesize Deterministic Personalized Narrative ---
  Map<String, dynamic> _synthesizePillarInsight(LuckPillar lp, int age) {
    final chart = widget.chart;
    final int dmIdx = chart?.dayPillar.stemIndex ?? 0;

    // Stem Ten God
    final stemGodId = BaziUtils.getTenGodId(dmIdx, lp.pillar.stemIndex);
    final stemGodInfo =
        _kTenGodInfo[stemGodId] ??
        (
          '十神',
          'Dinamika Energi',
          'Fokus pada pencapaian sosial dan pengembangan karir.',
        );

    // Branch Ten God — via ruling hidden stem (Cang Gan 主氣)
    // First hidden stem is the most influential in the 5-year branch sub-phase
    final branchGodId = BaziUtils.getBranchMainTenGodId(
      dmIdx,
      lp.pillar.branchIndex,
    );
    final branchGodInfo =
        _kTenGodInfo[branchGodId] ??
        (
          '地支',
          'Fondasi Batin & Stabilitas',
          'Fokus pada fondasi internal, kondisi emosional, dan stabilitas fisik.',
        );

    // Yong Shen / Ji Shen
    final stemElem = lp.pillar.element;
    final branchElem = BaziUtils.branchElements[lp.pillar.branchIndex];

    final isStemYongShen =
        chart?.dmStrength.yongShen.contains(stemElem) ?? false;
    final isStemJiShen = chart?.dmStrength.jiShen.contains(stemElem) ?? false;

    final isBranchYongShen =
        chart?.dmStrength.yongShen.contains(branchElem) ?? false;
    final isBranchJiShen =
        chart?.dmStrength.jiShen.contains(branchElem) ?? false;

    // Branch Natal Interactions (Clashes & Harmonies)
    final natalNotes = <String>[];

    if (chart != null) {
      final bIdx = lp.pillar.branchIndex;
      final natalBranches = [
        (
          name: 'Pilar Tahun (Sosial & Leluhur)',
          b: chart.yearPillar.branchIndex,
        ),
        (
          name: 'Pilar Bulan (Karier & Lingkungan)',
          b: chart.monthPillar.branchIndex,
        ),
        (name: 'Pilar Hari (Diri & Pasangan)', b: chart.dayPillar.branchIndex),
        if (chart.hourPillar != null)
          (name: 'Pilar Jam (Karya & Batin)', b: chart.hourPillar!.branchIndex),
      ];

      for (final nb in natalBranches) {
        // Six Clash: branch distance == 6 (simplified — no redundant % 12 needed for range 0-11)
        if ((bIdx - nb.b).abs() == 6) {
          natalNotes.add('⚡ Bentrok (Clash) dengan ${nb.name}');
        } else if ([
          [0, 1],
          [2, 11],
          [3, 10],
          [4, 9],
          [5, 8],
          [6, 7],
        ].any(
          (pair) =>
              (pair[0] == bIdx && pair[1] == nb.b) ||
              (pair[1] == bIdx && pair[0] == nb.b),
        )) {
          natalNotes.add('✦ Harmoni (Liu He) dengan ${nb.name}');
        }
      }
    }

    // Dynamic Chapter Title
    String chapterTitle = 'Babak Transisi & Pembentukan Diri';
    if (stemGodId.contains('resource')) {
      chapterTitle = 'Babak Pembekalan Intelektual & Pendalaman Keahlian';
    } else if (stemGodId.contains('wealth')) {
      chapterTitle = 'Babak Akumulasi Aset & Ekspansi Peluang Realita';
    } else if (stemGodId.contains('officer')) {
      chapterTitle = 'Babak Penataan Reputasi & Struktur Profesional';
    } else if (stemGodId == 'eating_god') {
      chapterTitle = 'Babak Ekspresi Bebas & Kenikmatan Berkarya';
    } else if (stemGodId == 'hurting_officer') {
      chapterTitle = 'Babak Pembuktian Diri & Terobosan Konvensi';
    } else if (stemGodId.contains('killings')) {
      chapterTitle = 'Babak Ujian Keberanian & Terobosan Berisiko';
    } else if (stemGodId.contains('friend') || stemGodId.contains('rob')) {
      chapterTitle = 'Babak Pengerasan Karakter & Kemandirian Jiwa';
    }

    return {
      'stemGodId': stemGodId,
      'stemGodHanzi': stemGodInfo.$1,
      'stemGodName': stemGodInfo.$2,
      'stemGodDesc': stemGodInfo.$3,
      'isStemYongShen': isStemYongShen,
      'isStemJiShen': isStemJiShen,
      'branchElem': branchElem,
      'branchGodId': branchGodId,
      'branchGodHanzi': branchGodInfo.$1,
      'branchGodName': branchGodInfo.$2,
      'branchGodDesc': branchGodInfo.$3,
      'isBranchYongShen': isBranchYongShen,
      'isBranchJiShen': isBranchJiShen,
      'natalNotes': natalNotes,
      'chapterTitle': chapterTitle,
    };
  }

  // --- Phase 2: Real Gemini API via /api/bazi/insight ---
  Future<void> _generateAiReading(
    LuckPillar lp,
    StateSetter setModalState,
  ) async {
    final ageKey = lp.startAge;
    if (_loadingAi.contains(ageKey)) return;

    // Check SharedPreferences cache first
    final chart = widget.chart;
    final dmId = chart?.dayMasterId ?? 'unknown';
    final cacheKey = _aiCacheKey(dmId, ageKey);

    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        try { setModalState(() { _aiReadings[ageKey] = cached; }); } catch (_) {}
        if (mounted) setState(() {});
        return;
      }
    } catch (_) {}

    try { setModalState(() => _loadingAi.add(ageKey)); } catch (_) { return; }

    try {
      final authHeader = await ref.read(authProvider.notifier).getAuthHeader();
      final profile = ref.read(birthProfileProvider).value;
      final age = _currentAge();

      final insight = _synthesizePillarInsight(lp, age);
      final natalList = insight['natalNotes'] as List<String>;
      final interaksi = natalList.isNotEmpty
          ? 'Interaksi natal: ${natalList.join(', ')}. '
          : '';

      final prompt =
          'Bacakan babak Da Yun usia ${lp.startAge}–${lp.endAge} saya secara mendalam. '
          'Pilar Da Yun: ${lp.pillar.stemNameId} ${lp.pillar.branchZodiacId} '
          '(${lp.pillar.stemSymbol}${lp.pillar.branchSymbol}). '
          '$interaksi'
          'Paruh pertama (${lp.startAge}–${lp.startAge + 4}): energi ${insight['stemGodName']}. '
          'Paruh kedua (${lp.startAge + 5}–${lp.endAge}): energi ${insight['branchGodName']}. '
          'Apa yang harus saya sadari, waspadai, dan manfaatkan di babak ini? '
          'Berikan narasi personal, empatik, dan actionable dalam 3 paragraf.';

      final dateStr =
          '${widget.birthDate.year}-'
          '${widget.birthDate.month.toString().padLeft(2, '0')}-'
          '${widget.birthDate.day.toString().padLeft(2, '0')}';

      final result = await ApiService.getBaziInsight(
        birthDate: dateStr,
        birthHour: chart?.adjustedHour,
        latitude: profile?.latitude,
        longitude: profile?.longitude,
        isMale: profile?.gender == 'male',
        currentAge: age,
        prompt: prompt,
        authHeader: authHeader,
      );

      final text = result['response'] as String? ?? '';
      if (mounted) {
        // Persist to SharedPreferences
        try {
          final prefs = await SharedPreferences.getInstance();
          if (text.isNotEmpty) await prefs.setString(cacheKey, text);
        } catch (_) {}

        try {
          setModalState(() {
            _loadingAi.remove(ageKey);
            _aiErrors.remove(ageKey);
            _aiReadings[ageKey] = text.isNotEmpty
                ? text
                : 'Sintesis tidak tersedia saat ini.';
          });
        } catch (_) {}
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('BaziLuckPillarsWidget._generateAiReading error: $e');
      final msg = e.toString();
      final errMsg = (msg.contains('gemini_quota') || msg.contains('RATE_LIMIT') || msg.contains('503'))
          ? 'Oracle sedang istirahat. Coba lagi sebentar.'
          : msg.contains('TimeoutException') || msg.contains('timeout')
          ? 'Koneksi timeout. Coba lagi.'
          : 'Gagal memuat sintesis. Coba lagi.';
      if (mounted) {
        try {
          setModalState(() {
            _loadingAi.remove(ageKey);
            _aiErrors.add(ageKey);
            // Jangan simpan error ke _aiReadings — biarkan null agar retry button tetap muncul
            debugPrint('BaziLuckPillarsWidget error stored: $errMsg');
          });
        } catch (_) {}
        if (mounted) setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int age = _currentAge();
    final bool isChildhood =
        widget.pillars.isNotEmpty && age < widget.pillars.first.startAge;
    // W13: -1 sentinel means user has passed all pillars — avoid showing past age
    final int nextTransitionAge = widget.pillars
        .map((p) => p.startAge)
        .firstWhere(
          (ageVal) => ageVal > age,
          orElse: () => -1,
        );

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Row(
            children: [
              Text(
                '大運 ',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  color: widget.elementColor,
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
            isChildhood
                ? 'Siklus 10 Tahun (Da Yun) • Mulai usia ${widget.pillars.first.startAge} tahun • Saat ini di periode 童限 (Childhood Fortune)'
                : nextTransitionAge == -1
                ? 'Siklus 10 Tahun (Da Yun) • Mulai usia ${widget.pillars.first.startAge} • Semua siklus telah dilalui'
                : 'Siklus 10 Tahun (Da Yun) • Mulai usia ${widget.pillars.first.startAge} • Transisi berikutnya: Usia $nextTransitionAge tahun',
            style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38),
          ),
          const SizedBox(height: 4),
          Text(
            widget.isForward
                ? '顺运 — Da Yun berjalan maju sesuai kalender. Energi terbuka secara progresif dari dekade ke dekade.'
                : '逆运 — Da Yun berjalan mundur melawan kalender. Perkembangan cenderung tidak konvensional; sering lebih kuat di paruh kedua tiap dekade.',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: widget.elementColor.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ketuk kartu pilar untuk melihat analisis persona 10 tahun tersebut.',
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: Colors.white38,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // ── Pillar cards ────────────────────────────────────────────────
          SingleChildScrollView(
            controller: _scrollCtrl,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.pillars.map((lp) {
                final isActive = age >= lp.startAge && age <= lp.endAge;
                final isPast = lp.endAge < age;
                return _LuckPillarCard(
                  lp: lp,
                  isActive: isActive,
                  isPast: isPast,
                  elementColor: widget.elementColor,
                  onTap: () =>
                      _showLuckPillarDetail(context, lp, isActive, isPast),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _directionChip() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: widget.elementColor.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: widget.elementColor.withValues(alpha: 0.3)),
    ),
    child: Text(
      widget.isForward ? '顺运 Maju' : '逆运 Mundur',
      style: GoogleFonts.outfit(
        fontSize: 10,
        color: widget.elementColor,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  void _showLuckPillarDetail(
    BuildContext context,
    LuckPillar lp,
    bool isActive,
    bool isPast,
  ) {
    final stemElem = lp.pillar.element;
    final elemColor = kBaziElementColors[stemElem] ?? AppTheme.accentGold;
    final int age = _currentAge();
    final insight = _synthesizePillarInsight(lp, age);

    final bool isSubPhase1Active = isActive && (age <= lp.startAge + 4);
    final bool isSubPhase2Active = isActive && (age >= lp.startAge + 5);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final String? aiReading = _aiReadings[lp.startAge];
          final bool isLoadingAi = _loadingAi.contains(lp.startAge);
          final bool isAiError = _aiErrors.contains(lp.startAge);

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle indicator
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Badges
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: elemColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: elemColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'Usia ${lp.startAge}–${lp.endAge} Tahun',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: elemColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.elementColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'PERIODE AKTIF SAAT INI',
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              color: Colors.black87,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title & Pillar Symbol
                  Text(
                    '${lp.pillar.stemSymbol} ${lp.pillar.branchSymbol} (${lp.pillar.stemNameId} ${lp.pillar.branchZodiacId})',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Chapter Title
                  Text(
                    insight['chapterTitle'] as String,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withValues(alpha: 0.10)),
                  const SizedBox(height: 12),

                  // ── PARUH PERTAMA (5 Tahun Pertama: Stem) ────────────────
                  _SubPhaseCard(
                    title:
                        '5 Tahun Pertama (Usia ${lp.startAge}–${lp.startAge + 4})',
                    subtitle:
                        'Batang Langit: ${lp.pillar.stemSymbol} ${lp.pillar.stemNameId}',
                    godHanzi: insight['stemGodHanzi'] as String,
                    godName: insight['stemGodName'] as String,
                    description: insight['stemGodDesc'] as String,
                    isYongShen: insight['isStemYongShen'] as bool,
                    isJiShen: insight['isStemJiShen'] as bool,
                    isCurrentSubPhase: isSubPhase1Active,
                    accentColor: elemColor,
                  ),
                  const SizedBox(height: 14),

                  // ── PARUH KEDUA (5 Tahun Kedua: Branch) ──────────────────
                  _SubPhaseCard(
                    title:
                        '5 Tahun Kedua (Usia ${lp.startAge + 5}–${lp.endAge})',
                    subtitle:
                        'Cabang Bumi: ${lp.pillar.branchSymbol} ${lp.pillar.branchZodiacId} (${(insight['branchElem']?.toString() ?? '').toUpperCase()})', // W11
                    godHanzi: insight['branchGodHanzi'] as String,
                    godName: insight['branchGodName'] as String,
                    description: insight['branchGodDesc'] as String,
                    isYongShen: insight['isBranchYongShen'] as bool,
                    isJiShen: insight['isBranchJiShen'] as bool,
                    natalNotes: insight['natalNotes'] as List<String>,
                    isCurrentSubPhase: isSubPhase2Active,
                    accentColor:
                        kBaziElementColors[insight['branchElem']] ??
                        AppTheme.accentPurple,
                  ),
                  const SizedBox(height: 20),

                  // ── PHASE 2: Optional AI Deep-Dive ───────────────────────
                  if (aiReading != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPurple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.accentPurple.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('☯ ', style: TextStyle(fontSize: 14)),
                              Text(
                                'Sintesis Lanjutan Babak Ini',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 12,
                                  color: AppTheme.accentGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            aiReading,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (isLoadingAi) ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.accentGold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Menyusun sintesis babak...',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppTheme.accentGold,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (isAiError) ...[
                    // Error state dengan retry button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: OutlinedButton.icon(
                        onPressed: () => _generateAiReading(lp, setModalState),
                        icon: const Icon(Icons.refresh_rounded,
                            size: 16, color: Color(0xFFF87171)),
                        label: Text(
                          'Gagal memuat — coba lagi',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFFF87171),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                          side: const BorderSide(
                            color: Color(0xFFF87171),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    OutlinedButton.icon(
                      onPressed: () => _generateAiReading(lp, setModalState),
                      icon: const Text('✨', style: TextStyle(fontSize: 14)),
                      label: Text(
                        'Lihat Sintesis Lengkap Babak Ini',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentGold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44),
                        side: BorderSide(
                          color: AppTheme.accentGold.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cardBg,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Tutup'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SubPhaseCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String godHanzi;
  final String godName;
  final String description;
  final bool isYongShen;
  final bool isJiShen;
  final List<String> natalNotes;
  final bool isCurrentSubPhase;
  final Color accentColor;

  const _SubPhaseCard({
    required this.title,
    required this.subtitle,
    required this.godHanzi,
    required this.godName,
    required this.description,
    required this.isYongShen,
    required this.isJiShen,
    this.natalNotes = const [],
    required this.isCurrentSubPhase,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrentSubPhase
            ? accentColor.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrentSubPhase
              ? accentColor.withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.08),
          width: isCurrentSubPhase ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: isCurrentSubPhase ? accentColor : Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (isCurrentSubPhase)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'FASE AKTIF SEKARANG',
                    style: GoogleFonts.outfit(
                      fontSize: 8,
                      color: Colors.black87,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.outfit(fontSize: 11, color: Colors.white54),
          ),
          const SizedBox(height: 10),

          // Badges: Yong Shen / Ji Shen / Natal Notes
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  '$godHanzi · $godName',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isYongShen)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.greenAccent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '✦ Yong Shen (Elemen Penyeimbang)',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: Colors.greenAccent.shade400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (isJiShen)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '⚡ Ji Shen (Elemen Tekanan)',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: Colors.redAccent.shade200,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ...natalNotes.map(
                (note) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppTheme.accentGold.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    note,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _LuckPillarCard extends StatelessWidget {
  final LuckPillar lp;
  final bool isActive;
  final bool isPast;
  final Color elementColor;
  final VoidCallback onTap;

  const _LuckPillarCard({
    required this.lp,
    required this.isActive,
    required this.isPast,
    required this.elementColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color =
        kBaziElementColors[lp.pillar.element] ?? AppTheme.accentGold;
    final Color activeColor = isActive ? elementColor : color;

    return Opacity(
      opacity: isPast ? 0.45 : 1.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 66,
              margin: const EdgeInsets.only(right: 8, top: 2),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? elementColor.withValues(alpha: 0.18)
                    : color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive
                      ? elementColor.withValues(alpha: 0.75)
                      : color.withValues(alpha: 0.25),
                  width: isActive ? 1.8 : 1.0,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: elementColor.withValues(alpha: 0.28),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  // Age range
                  Text(
                    '${lp.startAge}–${lp.endAge}',
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      color: isActive ? elementColor : Colors.white38,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Stem symbol
                  Text(
                    lp.pillar.stemSymbol,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      color: activeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Branch symbol
                  Text(
                    lp.pillar.branchSymbol,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      color: activeColor.withValues(alpha: 0.70),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lp.pillar.branchZodiacId,
                    style: GoogleFonts.outfit(
                      fontSize: 8,
                      color: isActive
                          ? elementColor.withValues(alpha: 0.80)
                          : Colors.white38,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ── "AKTIF" badge ──────────────────────────────────────────────
            if (isActive)
              Positioned(
                top: -2,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: elementColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(0),
                      topRight: Radius.circular(8),
                      bottomLeft: Radius.circular(6),
                      bottomRight: Radius.circular(0),
                    ),
                  ),
                  child: Text(
                    'AKTIF',
                    style: GoogleFonts.outfit(
                      fontSize: 7,
                      color: Colors.black87,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
