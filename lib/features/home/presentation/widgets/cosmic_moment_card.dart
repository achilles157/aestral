import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/weton_utils.dart';
import '../../../../core/utils/bazi_utils.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/providers/birth_profile_provider.dart';
import '../../../auth/services/auth_service.dart';
import '../../../bazi/providers/bazi_chart_provider.dart';
import '../../../ai/presentation/oracle_chat_screen.dart';
import '../../../tarot/services/tarot_data.dart';
import '../../../tarot/models/tarot_card.dart';

/// Detected cosmic event for today.
class CosmicMomentEvent {
  final String type; // 'hari_weton' | 'dino_was' | 'bazi_clash' | 'yong_shen'
  final String label;
  final String description;
  final IconData icon;

  const CosmicMomentEvent({
    required this.type,
    required this.label,
    required this.description,
    required this.icon,
  });
}

/// Dashboard card yang muncul HANYA saat ada Momen Kosmis aktif (event-driven).
/// Deteksi lokal: Hari Weton, Dino Was, Ba Zi Clash, Yong Shen Day.
/// Draw 1 kartu via `/api/tarot/moment` + CTA ke Oracle Chat.
class CosmicMomentCard extends ConsumerStatefulWidget {
  const CosmicMomentCard({super.key});

  @override
  ConsumerState<CosmicMomentCard> createState() => _CosmicMomentCardState();
}

class _CosmicMomentCardState extends ConsumerState<CosmicMomentCard> {
  CosmicMomentEvent? _event;
  bool _drawing = false;
  TarotCard? _drawnCard;
  bool _isReversed = false;
  List<String> _reasoning = [];
  bool _drawnToday = false;

  static const String _drawnPrefKey = 'moment_tarot_drawn_';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _detectEvent());
  }

  Future<void> _detectEvent() async {
    final profile = ref.read(birthProfileProvider).value;
    if (profile == null || profile.dobDate == null) return;

    final birth = profile.dobDate!;
    final now = DateTime.now();
    final birthWeton = WetonUtils.calculateWeton(birth);
    final todayWeton = WetonUtils.calculateWeton(now);

    CosmicMomentEvent? detected;

    // 1. Hari Weton — saptawara + pancawara sama dengan kelahiran
    final isHariWeton =
        birthWeton.saptawara == todayWeton.saptawara &&
        birthWeton.pancawara == todayWeton.pancawara;
    if (isHariWeton) {
      detected = CosmicMomentEvent(
        type: 'hari_weton',
        label: 'Hari Weton',
        description:
            'Hari ini adalah Hari Weton Anda — ${birthWeton.saptawara} ${birthWeton.pancawara}. '
            'Energi kelahiran kembali bersinar penuh.',
        icon: Icons.wb_sunny_rounded,
      );
    }

    // 2. Dino Was — hari naas (refleksi batin)
    if (detected == null && WetonUtils.checkIsDinoWas(birth, now)) {
      detected = CosmicMomentEvent(
        type: 'dino_was',
        label: 'Dino Was',
        description:
            'Hari refleksi batin tiba. Energi mengajak Anda melambat, '
            'merenung, dan menjaga kedamaian.',
        icon: Icons.nightlight_round,
      );
    }

    // 3. Ba Zi Clash / Yong Shen — butuh chart Ba Zi (jam lahir tersedia)
    if (detected == null) {
      try {
        final chart = await ref.read(baziChartProvider.future);
        if (chart != null) {
          final dayPillar = BaziUtils.getDayPillar(
            now.year,
            now.month,
            now.day,
          );
          final todayElem = BaziUtils.branchElements[dayPillar.branchIndex];
          final dmElem = chart.dayMasterElement;

          // Kontrol: Kayu→Tanah→Air→Api→Logam→Kayu
          const controls = {
            'kayu': 'tanah',
            'tanah': 'air',
            'air': 'api',
            'api': 'logam',
            'logam': 'kayu',
          };

          if (chart.dmStrength.yongShen.contains(todayElem)) {
            detected = CosmicMomentEvent(
              type: 'yong_shen',
              label: 'Yong Shen Day',
              description:
                  'Hari ini elemen ${todayElem.toUpperCase()} — penyeimbang '
                  'Anda — sedang berkuasa. Harmoni maksimal.',
              icon: Icons.auto_awesome_rounded,
            );
          } else if (controls[dmElem] == todayElem) {
            detected = CosmicMomentEvent(
              type: 'bazi_clash',
              label: 'Ba Zi Clash',
              description:
                  'Elemen hari ini (${todayElem.toUpperCase()}) menekan Day Master '
                  '${dmElem.toUpperCase()}. Hati-hati, kelola energi ekstra.',
              icon: Icons.bolt_rounded,
            );
          }
        }
      } catch (_) {
        // Ba Zi tidak tersedia (jam lahir kosong) — abaikan, event lain sudah cukup
      }
    }

    // Cek apakah sudah draw hari ini
    final prefs = await SharedPreferences.getInstance();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final hasDrawn = prefs.getBool('$_drawnPrefKey$todayStr') ?? false;

    if (!mounted) return;
    setState(() {
      _event = detected;
      _drawnToday = hasDrawn;
    });
  }

  Future<void> _drawCard() async {
    final event = _event;
    final profile = ref.read(birthProfileProvider).value;
    if (event == null || profile == null || profile.dobDate == null) return;

    setState(() => _drawing = true);

    try {
      final authHeader = await ref.read(authProvider.notifier).getAuthHeader();
      final birth = profile.dobDate!;
      final dobStr =
          '${birth.year}-${birth.month.toString().padLeft(2, '0')}-${birth.day.toString().padLeft(2, '0')}';

      // Ambil konteks Ba Zi untuk weighting (opsional)
      String? dmElement;
      String? dmPolarity;
      List<String>? yongShen;
      String? wuXingDominant;
      try {
        final chart = await ref.read(baziChartProvider.future);
        if (chart != null) {
          dmElement = chart.dayMasterElement;
          dmPolarity = chart.dayPillar.stemIndex % 2 == 0 ? 'yang' : 'yin';
          yongShen = chart.dmStrength.yongShen;
          wuXingDominant = chart.wuXingBalance.dominant;
        }
      } catch (_) {}

      final response = await ApiService.drawTarotMoment(
        birthDate: dobStr,
        eventType: event.type,
        authHeader: authHeader,
        dayMasterElement: dmElement,
        dayMasterPolarity: dmPolarity,
        yongShen: yongShen,
        wuXingDominant: wuXingDominant,
      );

      final cardJson = response['card'] as Map<String, dynamic>?;
      if (cardJson == null) throw Exception('Kartu kosong dari backend');

      final cardIndex = cardJson['cardIndex'] as int? ?? 0;
      final isReversed = cardJson['isReversed'] as bool? ?? false;
      final reasoning =
          (response['reasoning'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      final deck = await ref.read(tarotDeckProvider.future);
      final card = deck.firstWhere(
        (c) => c.id == cardIndex,
        orElse: () => deck.first,
      );

      // Tandai sudah draw hari ini
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await prefs.setBool('$_drawnPrefKey$todayStr', true);

      if (!mounted) return;
      setState(() {
        _drawnCard = card;
        _isReversed = isReversed;
        _reasoning = reasoning;
        _drawnToday = true;
      });
    } catch (e) {
      debugPrint('CosmicMomentCard: draw error — $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menarik kartu. Periksa koneksi Anda.',
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: AppTheme.accentPink,
        ),
      );
    } finally {
      if (mounted) setState(() => _drawing = false);
    }
  }

  void _openOracleChat() async {
    final authHeader = await ref.read(authProvider.notifier).getAuthHeader();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            OracleChatScreen(oracleType: 'synthesis', authHeader: authHeader),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    if (event == null) return const SizedBox.shrink();

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(event.icon, color: AppTheme.accentGold, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Momen Kosmis',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          letterSpacing: 1.5,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        event.label,
                        style: GoogleFonts.cinzel(
                          fontSize: 18,
                          color: AppTheme.accentGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              event.description,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.textLight,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            if (_drawnCard != null)
              _buildCardResult(event)
            else if (_drawnToday)
              _buildAlreadyDrawn()
            else
              _buildDrawButton(event),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawButton(CosmicMomentEvent event) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _drawing ? null : _drawCard,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentGold,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 0,
        ),
        icon: _drawing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : const Icon(Icons.style_rounded, size: 18),
        label: Text(
          _drawing ? 'Menarik kartu...' : 'Tarik Kartu Momen Kosmis',
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAlreadyDrawn() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.textLight.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppTheme.accentGold,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Kartu Momen Kosmis hari ini sudah ditarik. Kembali besok.',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppTheme.textLight,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardResult(CosmicMomentEvent event) {
    final card = _drawnCard!;
    final meaning = _isReversed
        ? card.reversedMeaningId
        : card.uprightMeaningId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isReversed
                  ? [
                      AppTheme.accentPink.withValues(alpha: 0.18),
                      AppTheme.background.withValues(alpha: 0.6),
                    ]
                  : [
                      AppTheme.accentGold.withValues(alpha: 0.18),
                      AppTheme.background.withValues(alpha: 0.6),
                    ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (_isReversed ? AppTheme.accentPink : AppTheme.accentGold)
                  .withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _isReversed ? Icons.flip_rounded : Icons.wb_sunny_rounded,
                    color: _isReversed
                        ? AppTheme.accentPink
                        : AppTheme.accentGold,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      card.nameId,
                      style: GoogleFonts.cinzel(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ),
                  Text(
                    _isReversed ? 'TERBALIK' : 'TEGAK',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      letterSpacing: 1,
                      color: _isReversed
                          ? AppTheme.accentPink
                          : AppTheme.accentGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                meaning,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppTheme.textLight,
                  height: 1.5,
                ),
              ),
              if (_reasoning.isNotEmpty) ...[
                const SizedBox(height: 8),
                ..._reasoning.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            r,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _openOracleChat,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accentGold,
              side: BorderSide(
                color: AppTheme.accentGold.withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: Text(
              'Tanya lebih lanjut ke Oracle',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
