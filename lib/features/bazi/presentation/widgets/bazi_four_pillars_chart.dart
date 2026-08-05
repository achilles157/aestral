import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../features/auth/services/auth_service.dart';
import '../../domain/bazi_chart.dart';
import 'bazi_pillar_column.dart';

/// Horizontal chart displaying all 4 Ba Zi pillars.
/// Traditional order: Year → Month → Day → Hour (left to right).
/// The Day Pillar is highlighted as it contains the Day Master.
class BaziFourPillarsChart extends StatelessWidget {
  final BaziChart chart;

  const BaziFourPillarsChart({super.key, required this.chart});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Text(
                '四柱',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  color: AppTheme.accentGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Empat Pilar Nasib',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _showChartGuideSheet(context),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: AppTheme.accentGold.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Day Master: ${chart.dayPillar.stemSymbol} ${chart.dayPillar.stemNameId}',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color:
                  kBaziElementColors[chart.dayMasterElement]?.withValues(
                    alpha: 0.9,
                  ) ??
                  AppTheme.accentGold,
            ),
          ),
          const SizedBox(height: 16),

          // Pillar row
          Row(
            children: [
              Expanded(
                child: BaziPillarColumn(
                  label: 'TAHUN',
                  pillar: chart.yearPillar,
                  dayMasterStemIndex: chart.dayPillar.stemIndex,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BaziPillarColumn(
                  label: 'BULAN',
                  pillar: chart.monthPillar,
                  dayMasterStemIndex: chart.dayPillar.stemIndex,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BaziPillarColumn(
                  label: 'HARI',
                  pillar: chart.dayPillar,
                  isHighlighted: true,
                  dayMasterStemIndex: chart.dayPillar.stemIndex,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BaziPillarColumn(
                  label: 'JAM',
                  pillar: chart.hourPillar,
                  dayMasterStemIndex: chart.dayPillar.stemIndex,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Domain labels per pillar
          Row(
            children: [
              _domainLabel(
                context,
                title: 'Sosial\n& Leluhur',
                pillarName: 'Pilar Tahun',
                explanation:
                    'Melambangkan citra publik, hubungan sosial luar, lingkungan tumbuh kembang awal, serta energi keluarga besar & leluhur.',
              ),
              const SizedBox(width: 8),
              _domainLabel(
                context,
                title: 'Karier\n& Ambisi',
                pillarName: 'Pilar Bulan',
                explanation:
                    'Melambangkan fokus utama karier, lingkungan kerja, ambisi pencapaian diri, serta dinamika usia muda (15–30 tahun) dan orang tua.',
              ),
              const SizedBox(width: 8),
              _domainLabel(
                context,
                title: 'Diri\n& Pasangan',
                pillarName: 'Pilar Hari (Day Master)',
                explanation:
                    'Melambangkan inti kepribadianmu (Day Master), jiwa terdalam, pola pikir dasar, serta hubungan asmara & pasangan hidup.',
              ),
              const SizedBox(width: 8),
              _domainLabel(
                context,
                title: 'Warisan\n& Bawah Sadar',
                pillarName: 'Pilar Jam',
                explanation:
                    'Melambangkan dorongan bawah sadar, cita-cita masa tua (46+ tahun), karya/legacy yang kamu ciptakan, serta hubungan dengan anak atau junior.',
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Cang Gan note
          Text(
            '藏干 (Hidden Stems) — elemen tersembunyi di dalam setiap zodiak, mewakili motivasi dan karakter laten yang beroperasi di bawah permukaan.',
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: Colors.white38,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),

          // TST note
          if (chart.trueSolarTimeNote != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF60A5FA).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF60A5FA).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 12,
                    color: Color(0xFF60A5FA),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      chart.trueSolarTimeNote!,
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        color: const Color(0xFF60A5FA).withValues(alpha: 0.8),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── AI Grand Synthesis ──────────────────────────────────────────
          const SizedBox(height: 14),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 14),
          _FourPillarsAiSection(chart: chart),
        ],
      ),
    );
  }

  Widget _domainLabel(
    BuildContext context, {
    required String title,
    required String pillarName,
    required String explanation,
  }) {
    return Expanded(
      child: Tooltip(
        message: '$pillarName:\n$explanation',
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1638),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppTheme.accentPurple.withValues(alpha: 0.5),
          ),
        ),
        textStyle: GoogleFonts.outfit(
          fontSize: 11,
          color: Colors.white,
          height: 1.4,
        ),
        child: InkWell(
          onTap: () => _showPillarDetailSheet(
            context,
            pillarName,
            title.replaceAll('\n', ' '),
            explanation,
          ),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 9,
                color: Colors.white60,
                height: 1.3,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showChartGuideSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.accentGold,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Panduan Membaca Empat Pilar',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Peta Ba Zi kamu terdiri dari 4 pilar waktu kelahiran (Tahun, Bulan, Hari, dan Jam). '
              'Setiap pilar memiliki Batang Langit (elemen utama) dan Cabang Bumi (zodiak hewan).\n\n'
              '• Pilar Hari (Day Master): Inti kepribadian dan energi jiwa utama kamu.\n'
              '• Pilar Bulan: Potensi karier, ambisi, dan lingkungan profesional.\n'
              '• Pilar Tahun: Relasi sosial luar dan citra diri di mata publik.\n'
              '• Pilar Jam: Cita-Cita bawah sadar, karya, dan masa depan.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.white70,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Mengerti'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPillarDetailSheet(
    BuildContext context,
    String pillarName,
    String domainTitle,
    String explanation,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pillarName,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppTheme.accentGold,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              domainTitle,
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              explanation,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.white70,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentPurple,
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
  }
}

// ─── Four Pillars AI Grand Synthesis ──────────────────────────────────────────

class _FourPillarsAiSection extends ConsumerStatefulWidget {
  const _FourPillarsAiSection({required this.chart});

  final BaziChart chart;

  @override
  ConsumerState<_FourPillarsAiSection> createState() =>
      _FourPillarsAiSectionState();
}

class _FourPillarsAiSectionState extends ConsumerState<_FourPillarsAiSection> {
  String? _insight;
  bool _loading = false;
  String? _error;

  static String _cacheKey(BaziChart c) {
    final h = c.hourPillar;
    return 'bazi_pillars_ai_'
        '${c.yearPillar.stemIndex}-${c.yearPillar.branchIndex}_'
        '${c.monthPillar.stemIndex}-${c.monthPillar.branchIndex}_'
        '${c.dayPillar.stemIndex}-${c.dayPillar.branchIndex}_'
        '${h != null ? "${h.stemIndex}-${h.branchIndex}" : "xx"}';
  }

  String _buildPrompt() {
    final c = widget.chart;
    final h = c.hourPillar;
    final p = [
      'Tahun: ${c.yearPillar.stemNameId} ${c.yearPillar.branchZodiacId}',
      'Bulan: ${c.monthPillar.stemNameId} ${c.monthPillar.branchZodiacId}',
      'Hari: ${c.dayPillar.stemNameId} ${c.dayPillar.branchZodiacId}',
      if (h != null) 'Jam: ${h.stemNameId} ${h.branchZodiacId}',
    ].join(', ');

    return 'Ba Zi 4 Pilar: $p. '
        'Day Master: ${c.dayMasterElement} (${c.dmStrength.label}). '
        'Yong Shen: ${c.dmStrength.yongShen.join(", ")}. '
        'Tulis 4 kalimat grand story: temukan tema besar yang '
        'menghubungkan keempat pilar — pola hidup, kekuatan tersembunyi, '
        'tantangan utama. Jangan rangkum per pilar. '
        'Nada empatik, psikologi modern.';
  }

  Future<void> _generate() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _cacheKey(widget.chart);
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
      final result = await ApiService.generateAiChat(
        prompt: _buildPrompt(),
        authHeader: authHeader,
      );
      final text = result['response'] as String? ?? '';
      if (text.isNotEmpty) {
        await prefs.setString(key, text);
        if (mounted) setState(() => _insight = text);
      } else {
        if (mounted) setState(() => _error = 'Tidak ada respons. Coba lagi.');
      }
    } catch (e) {
      debugPrint('_FourPillarsAiSection error: $e');
      if (mounted) setState(() => _error = 'Gagal memuat — coba lagi.');
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
                '☯ Blueprint Kosmis Chart-mu',
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
                  await prefs.remove(_cacheKey(widget.chart));
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
                  'Membaca blueprint kosmis chart-mu...',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppTheme.accentGold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            )
          : _error != null
          ? GestureDetector(
              onTap: _generate,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.refresh_rounded,
                    size: 14,
                    color: Color(0xFFF87171),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _error!,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: const Color(0xFFF87171),
                    ),
                  ),
                ],
              ),
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
                      'Baca narasi lengkap chart-mu',
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
