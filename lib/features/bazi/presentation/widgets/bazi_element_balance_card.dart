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
import 'bazi_wu_xing_radar.dart';

const _kDominantDesc = {
  'kayu': 'Kayu dominan: tendensi kuat untuk terus tumbuh dan berinovasi.',
  'api': 'Api dominan: semangat dan kepemimpinan ekspresif yang menonjol.',
  'tanah': 'Tanah dominan: stabilitas dan kemampuan memelihara yang kuat.',
  'logam': 'Logam dominan: ketegasan dan presisi dalam mengambil keputusan.',
  'air': 'Air dominan: intuisi yang dalam dan kemampuan beradaptasi tinggi.',
};

const _kDeficientDesc = {
  'kayu': 'Fleksibilitas dan kreativitas adalah area untuk lebih diaktivasi.',
  'api': 'Antusiasme dan semangat bisa lebih dikembangkan secara sadar.',
  'tanah':
      'Koneksi dengan hal-hal praktis dan fondasi perlu lebih diperhatikan.',
  'logam': 'Disiplin dan struktur adalah area untuk terus ditingkatkan.',
  'air': 'Kemampuan beradaptasi dan intuisi perlu lebih diasah.',
};

/// Narasi psikologis mendalam per kombinasi dominan+defisien (offline, no API).
const Map<String, String> _kWuXingNarrative = {
  'kayu_api':
      'Ide-idemu besar dan visioner, namun momentum eksekusi sering terasa berat. '
      'Energi tumbuhmu (Kayu) mengalir deras tapi sulit meledak menjadi aksi nyata tanpa api semangat yang stabil. '
      'Kelilingi diri dengan orang yang bersemangat — mereka menyalakan api yang sesungguhnya sudah ada dalam dirimu.',
  'kayu_tanah':
      'Kamu hebat dalam memulai tapi bisa kesulitan memelihara konsistensi jangka panjang. '
      'Kemampuan tumbuh cepatmu (Kayu) kadang mengabaikan fondasi praktis yang perlu dirawat. '
      'Investasi rutin dalam kebiasaan sederhana akan mengubah potensi besarmu menjadi hasil nyata.',
  'kayu_logam':
      'Ekspansimu yang terus-menerus tanpa filter ketegasan bisa menyebar terlalu luas. '
      'Belajar berkata tidak dan memilih pertempuran dengan bijak adalah kekuatan terbesar yang bisa kamu kembangkan.',
  'kayu_air':
      'Pertumbuhanmu yang agresif tanpa kedalaman refleksi bisa membawa kelelahan tak terduga. '
      'Sisihkan waktu sunyi untuk merenung — di situlah strategi terbaikmu lahir.',
  'api_kayu':
      'Semangatmu besar (Api) tapi sumber energi baru perlu terus diisi. '
      'Tanpa pertumbuhan konsisten, api bisa redup. Belajar hal baru secara rutin adalah bahan bakar terbaikmu.',
  'api_tanah':
      'Ekspresif dan bersemangat, namun fondasi praktis kadang terabaikan. '
      'Keuangan, kesehatan, dan rutinitas harian perlu perhatian ekstra — bukan hambatan, tapi landasan pacu untuk semangatmu.',
  'api_logam':
      'Banyak proyek setengah jadi bisa menjadi pola yang berulang tanpa disiplin eksekusi. '
      'Sistem dan struktur kerja yang ketat adalah investasi terbaik untuk energi besar yang kamu miliki.',
  'api_air':
      'Antusiasme yang kuat kadang mendahului kehati-hatian dan intuisi mendalam. '
      'Melatih kemampuan membaca situasi sebelum bertindak akan melipatgandakan hasil dari semangatmu.',
  'tanah_kayu':
      'Stabilitas dan keandalanmu sudah kuat, tapi inovasi dan pertumbuhan baru perlu lebih didorong. '
      'Zona nyaman bisa menjadi jebakan halus — satu langkah kecil ke wilayah baru setiap minggu sudah mengubah segalanya.',
  'tanah_api':
      'Kamu orang yang bisa diandalkan, tapi semangat dan antusiasme perlu lebih diaktifkan. '
      'Jangan takut tampil dan berbicara — dunia perlu melihat stabilitas yang kamu miliki.',
  'tanah_logam':
      'Pemeliharaan hubungan sudah baik, tapi pengambilan keputusan tegas kadang terasa berat. '
      'Latih diri untuk lebih cepat memutus hal yang tidak produktif — itu bentuk cinta tertinggi untuk dirimu sendiri.',
  'tanah_air':
      'Kestabilan praktismu sudah kuat, tapi kedalaman emosi dan intuisi perlu lebih dieksplorasi. '
      'Journaling atau meditasi singkat setiap hari membuka dimensi dirimu yang belum tergali.',
  'logam_kayu':
      'Ketegasan dan presisimu adalah kekuatan, tapi fleksibilitas dan kreativitas perlu dilatih. '
      'Sesekali tinggalkan rencana dan biarkan diri berimprovisasi — di situlah terobosan tak terduga muncul.',
  'logam_api':
      'Analisis dan strukturmu kuat, tapi koneksi emosional dan antusiasme perlu lebih dihangatkan. '
      'Ekspresi spontan — berbagi cerita, merayakan hal kecil — mengisi energi yang sering kamu abaikan.',
  'logam_tanah':
      'Disiplin tinggi tapi kadang terlalu kritis pada diri sendiri. '
      'Merawat diri bukan pemborosan waktu — itu pengisian bahan bakar untuk standar tinggi yang kamu jaga.',
  'logam_air':
      'Keputusanmu akurat secara logika — tambahkan momen diam sebelum memutuskan hal besar untuk membiarkan nurani bicara. '
      'Ketegasan dan intuisi yang seimbang adalah kombinasi yang sangat langka.',
  'air_kayu':
      'Intuisimu tajam dan dalam, tapi tindakan nyata perlu lebih didorong. '
      'Idemu luar biasa — yang perlu dilatih adalah keberanian memulai meski belum sempurna.',
  'air_api':
      'Kedalaman reflektifmu luar biasa, tapi semangat dan visibilitas eksternal perlu diaktifkan. '
      'Berbagi ide dan pemikiranmu — dunia perlu mendengar kedalaman yang kamu miliki.',
  'air_tanah':
      'Fleksibilitas tinggi tapi fondasi dan konsistensi adalah area yang perlu dibangun. '
      'Rutinitas sederhana yang dijaga setiap hari mengubah potensi besarmu menjadi pencapaian nyata.',
  'air_logam':
      'Intuisi dan adaptabilitasmu kuat, tapi ketegasan dan keberanian memotong yang tidak perlu perlu ditingkatkan. '
      'Batas yang sehat bukan penolakan — itu perlindungan untuk energi berhargamu.',
};

String? _wuXingNarrative(String dominant, String deficient) =>
    _kWuXingNarrative['${dominant}_$deficient'];

/// Wu Xing (五行) element balance — pentagon radar chart with dominant/deficient badges.
class BaziElementBalanceCard extends StatelessWidget {
  final WuXingBalance balance;
  final BaziChart chart;

  const BaziElementBalanceCard({
    super.key,
    required this.balance,
    required this.chart,
  });

  @override
  Widget build(BuildContext context) {
    final total = balance.total;
    final totalLabel = total == 18
        ? '18 karakter penuh'
        : total == 15 || total == 16
        ? '$total karakter (jam diketahui)'
        : '$total karakter — jam tidak diketahui';

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Row(
            children: [
              Text(
                '五行',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  color: AppTheme.accentGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Keseimbangan Lima Elemen',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            'Dari $totalLabel',
            style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38),
          ),
          const SizedBox(height: 16),

          // ── Pentagon Radar ──────────────────────────────────────────────
          BaziWuXingRadar(balance: balance),

          // ── Dominant / Deficient badges ─────────────────────────────────
          const SizedBox(height: 14),
          Row(
            children: [
              _badge(
                '↑ ${balance.dominant.toUpperCase()}',
                kBaziElementColors[balance.dominant] ?? AppTheme.accentGold,
              ),
              const SizedBox(width: 8),
              _badge(
                '↓ ${balance.deficient.toUpperCase()}',
                (kBaziElementColors[balance.deficient] ?? Colors.white38)
                    .withValues(alpha: 0.55),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${_kDominantDesc[balance.dominant] ?? ''} ${_kDeficientDesc[balance.deficient] ?? ''}',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: Colors.white38,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          // ── Wu Xing Narrative ExpansionTile ─────────────────────────────
          const SizedBox(height: 8),
          Builder(
            builder: (ctx) {
              final narrative = _wuXingNarrative(
                balance.dominant,
                balance.deficient,
              );
              if (narrative == null) return const SizedBox.shrink();
              final color =
                  kBaziElementColors[balance.dominant] ?? AppTheme.accentGold;
              return Theme(
                data: Theme.of(ctx).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  title: Text(
                    '✦ Apa Artinya Untukmu?',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: color.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  iconColor: color.withValues(alpha: 0.6),
                  collapsedIconColor: color.withValues(alpha: 0.4),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 4),
                      child: Text(
                        narrative,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.80),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ── AI Deep Synthesis ────────────────────────────────────────────
          const SizedBox(height: 14),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 14),
          _WuXingAiSection(balance: balance, chart: chart),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.30)),
    ),
    child: Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 9,
        color: color,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    ),
  );
}

// ─── Wu Xing AI Synthesis ──────────────────────────────────────────────────────

class _WuXingAiSection extends ConsumerStatefulWidget {
  const _WuXingAiSection({required this.balance, required this.chart});

  final WuXingBalance balance;
  final BaziChart chart;

  @override
  ConsumerState<_WuXingAiSection> createState() => _WuXingAiSectionState();
}

class _WuXingAiSectionState extends ConsumerState<_WuXingAiSection> {
  String? _insight;
  bool _loading = false;
  String? _error; // W16: track error state for user-visible feedback

  static String _cacheKey(String dmId, String dominant, String deficient) =>
      'bazi_wuxing_ai_${dmId}_${dominant}_$deficient';

  String _buildPrompt() {
    final b = widget.balance;
    final pct = [
      'Kayu ${b.kayu}',
      'Api ${b.api}',
      'Tanah ${b.tanah}',
      'Logam ${b.logam}',
      'Air ${b.air}',
    ].join(', ');

    return 'Ba Zi Wu Xing: $pct (total ${b.total} karakter). '
        'Dominan: ${b.dominant}, Defisien: ${b.deficient}. '
        'Day Master: ${widget.chart.dayMasterElement} (${widget.chart.dmStrength.label}). '
        'Tulis 3–4 kalimat yang menjelaskan apa artinya komposisi elemen ini '
        'secara konkret untuk kehidupan sehari-hari, karier, dan pola relasi orang ini. '
        'Hubungkan dengan Day Master-nya — jangan hanya mendeskripsikan elemen secara umum. '
        'Nada empatik, psikologi modern, bukan ramalan buta.';
  }

  Future<void> _generate() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _cacheKey(
        widget.chart.dayMasterId,
        widget.balance.dominant,
        widget.balance.deficient,
      );
      final cached = prefs.getString(key);
      if (cached != null) {
        if (mounted) setState(() { _insight = cached; _loading = false; });
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
        if (mounted) setState(() { _insight = text; _error = null; });
      }
    } catch (e) {
      debugPrint('_WuXingAiSection error: $e');
      // W16: surface error to user with retry — consistent with other AI sections
      if (mounted) setState(() => _error = 'Gagal memuat narasi. Coba lagi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color =
        kBaziElementColors[widget.balance.dominant] ?? AppTheme.accentGold;

    if (_insight != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '☯ Implikasi Keseimbangan Elemenmu',
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
                  await prefs.remove(_cacheKey(
                    widget.chart.dayMasterId,
                    widget.balance.dominant,
                    widget.balance.deficient,
                  ));
                  if (mounted) setState(() => _insight = null);
                },
                child: Text(
                  '↻',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.white24),
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
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Menganalisis komposisi elemenmu...',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: color,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            )
          : _error != null
          // W16: show error with retry instead of silently reverting to CTA
          ? GestureDetector(
              onTap: _generate,
              child: Text(
                '$_error Ketuk untuk coba lagi.',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Colors.red.shade300,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
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
                      'Pelajari implikasi keseimbangan elemenmu',
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
