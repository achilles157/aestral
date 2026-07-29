import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

const _kElementNarrative = {
  // ── Single dominant ────────────────────────────────────────────────────────
  'geni':
      'Geni (Api) yang dominan dalam wetonmu menandakan jiwa yang penuh semangat dan daya dorong besar. '
      'Kamu cenderung bergerak lebih dulu dari orang lain — inisiatif adalah bahasa alaminya. '
      'Yang perlu dijaga: api yang terlalu besar bisa membakar diri sendiri. Ritme dan istirahat adalah kekuatan tersembunyi yang sering kamu abaikan.',
  'banyu':
      'Banyu (Air) yang dominan menandakan kedalaman perasaan dan kemampuan adaptasi yang luar biasa. '
      'Kamu bisa masuk ke hampir semua situasi dan menemukan caramu sendiri untuk mengalir. '
      'Yang perlu dijaga: air yang mengalir tanpa arah bisa kehilangan kekuatannya. Keberanian untuk membuat keputusan tegas adalah yang paling perlu diasah.',
  'lemah':
      'Lemah (Tanah) yang dominan menandakan fondasi yang kuat dan keandalan yang orang lain rasakan bahkan sebelum kamu berbicara. '
      'Kamu adalah tempat orang berlabuh — stabil, sabar, dan tahan banting. '
      'Yang perlu dijaga: tanah yang terlalu padat bisa menyulitkan pertumbuhan baru. Sesekali izinkan dirimu bereksperimen keluar dari jalur yang sudah terbukti.',
  'angin':
      'Angin (Udara) yang dominan menandakan pikiran yang lincah dan kemampuan menghubungkan hal-hal yang tampak tidak berkaitan. '
      'Kamu bergerak dalam ide dan koneksi sosial dengan sangat natural — inspirasi mengalir deras. '
      'Yang perlu dijaga: angin yang bergerak terlalu cepat kadang melewatkan kedalaman. Melatih konsistensi jangka panjang akan melipatgandakan dampak dari semua ide besarmu.',

  // ── Dual dominant (sorted alphabetically) ─────────────────────────────────
  'banyu_geni':
      'Wetonmu memiliki dua kekuatan yang sama kuatnya: Api yang mendorong dan Air yang merasakan — kombinasi yang sangat jarang. '
      'Kamu bisa bergerak cepat sekaligus merasakan segalanya dengan dalam, memimpin sekaligus berempati. '
      'Tantangannya: keduanya bisa saling meredam. Api ingin bertindak, Air ingin merenung. '
      'Kuncinya adalah tahu kapan harus membakar dan kapan harus mengalir.',
  'geni_lemah':
      'Api yang bersemangat bertemu fondasi Tanah yang kokoh — kamu punya daya dorong besar sekaligus kemampuan untuk konsisten. '
      'Kombinasi yang langka: ambisius tapi tidak terburu-buru, stabil tapi tidak diam. '
      'Yang perlu dijaga: jangan biarkan stabilitas menjadi keengganan untuk berubah ketika perubahan itu memang dibutuhkan.',
  'angin_geni':
      'Api dan Angin dalam dirimu saling memperkuat — inspirasi mengalir deras dan semangat untuk mewujudkannya juga besar. '
      'Kamu adalah tipe yang bisa menggerakkan orang lain dengan energi dan ide. '
      'Yang perlu dijaga: keduanya sama-sama volatile. Tanpa akar yang kuat, api yang ditiup angin bisa menjadi kebakaran.',
  'banyu_lemah':
      'Air yang dalam dan Tanah yang stabil — dua elemen paling nurturing dalam sistem ini hadir bersamaan dalam dirimu. '
      'Kamu adalah tempat orang berlabuh sekaligus merasakan; empati dan kestabilan berjalan berdampingan. '
      'Yang perlu dijaga: kamu bisa terlalu fokus merawat orang lain hingga lupa mengisi kembali dirimu sendiri.',
  'angin_banyu':
      'Air yang mengalir dan Angin yang bergerak membentuk kombinasi yang sangat adaptif dan intuitif. '
      'Kamu membaca situasi dengan cepat dan bergerak sesuai arus tanpa terasa dipaksakan. '
      'Yang perlu dijaga: terlalu mengalir bisa membuat orang lain — dan dirimu sendiri — sulit memprediksi ke mana kamu akan pergi.',
  'angin_lemah':
      'Fondasi Tanah yang kuat diperkaya oleh kreativitas dan fleksibilitas Angin. '
      'Kamu bisa membangun sesuatu yang besar sekaligus beradaptasi saat diperlukan — pembangun yang juga bisa berpikir out-of-the-box. '
      'Yang perlu dijaga: dua kekuatan ini terkadang saling tarik. Kenali kapan kamu butuh konsistensi dan kapan butuh improvisasi.',

  // ── Seimbang (semua elemen setara — Kliwon tanpa offset besar) ────────────
  'balanced':
      'Keempat elemen dalam wetonmu hadir dalam keseimbangan yang sangat langka. '
      'Ini berarti kamu memiliki fleksibilitas luar biasa untuk beradaptasi ke hampir semua situasi dan peran. '
      'Yang perlu dijaga: terlalu seimbang bisa membuat sulit mengidentifikasi kekuatan terkuat yang perlu difokuskan. '
      'Pilih satu arena, kerahkan semua elemen — di situlah potensimu meledak.',
};

class WetonElementMandala extends StatefulWidget {
  final String saptawara;
  final String pancawara;

  const WetonElementMandala({
    super.key,
    required this.saptawara,
    required this.pancawara,
  });

  @override
  State<WetonElementMandala> createState() => _WetonElementMandalaState();
}

class _WetonElementMandalaState extends State<WetonElementMandala>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(WetonElementMandala oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-animate when weton data changes
    if (oldWidget.saptawara != widget.saptawara ||
        oldWidget.pancawara != widget.pancawara) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Map<String, double> get elementValues {
    double geni = 1.0;
    double banyu = 1.0;
    double lemah = 1.0;
    double angin = 1.0;

    final sStr = widget.saptawara.toLowerCase();
    if (sStr.contains('ahad') || sStr.contains('minggu')) {
      geni += 2.0;
      angin += 1.0;
    } else if (sStr.contains('senin')) {
      banyu += 3.0;
    } else if (sStr.contains('selasa')) {
      geni += 3.0;
    } else if (sStr.contains('rabu')) {
      banyu += 2.0;
      lemah += 1.0;
    } else if (sStr.contains('kamis')) {
      angin += 3.0;
    } else if (sStr.contains('jumat')) {
      lemah += 2.0;
      banyu += 1.0;
    } else if (sStr.contains('sabtu')) {
      lemah += 3.0;
      geni += 1.0;
    }

    final pStr = widget.pancawara.toLowerCase();
    if (pStr.contains('legi')) {
      angin += 3.0;
      lemah += 1.0;
    } else if (pStr.contains('pahing')) {
      geni += 3.0;
      angin += 1.0;
    } else if (pStr.contains('pon')) {
      banyu += 3.0;
      geni += 1.0;
    } else if (pStr.contains('wage')) {
      lemah += 3.0;
      banyu += 1.0;
    } else if (pStr.contains('kliwon')) {
      geni += 1.0;
      banyu += 1.0;
      lemah += 1.0;
      angin += 1.0;
    }

    final total = geni + banyu + lemah + angin;
    return {
      'geni': geni / total,
      'banyu': banyu / total,
      'lemah': lemah / total,
      'angin': angin / total,
    };
  }

  @override
  Widget build(BuildContext context) {
    final values = elementValues;

    return Column(
      children: [
        Semantics(
          label:
              'Mandala elemen kosmis weton — radar diagram yang menggambarkan '
              'keseimbangan empat elemen Jawa: Geni, Banyu, Lemah, dan Angin.',
          excludeSemantics: false,
          child: Center(
            child: AnimatedBuilder(
              animation: _progress,
              builder: (context, _) => CustomPaint(
                size: const Size(260, 260),
                painter: _WetonElementMandalaPainter(
                  geni: values['geni']!,
                  banyu: values['banyu']!,
                  lemah: values['lemah']!,
                  angin: values['angin']!,
                  progress: _progress.value,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildElementChip(
              'Geni (Api)',
              values['geni']!,
              AppTheme.elementFire,
            ),
            _buildElementChip(
              'Banyu (Air)',
              values['banyu']!,
              AppTheme.elementWater,
            ),
            _buildElementChip(
              'Lemah (Tanah)',
              values['lemah']!,
              AppTheme.elementEarth,
            ),
            _buildElementChip(
              'Angin (Udara)',
              values['angin']!,
              AppTheme.elementCosmic,
            ),
          ],
        ),
        // ── "So what" narrative per elemen dominan ────────────────────────
        // Rendered inline (bukan ExpansionTile) karena widget ini hidup
        // di dalam Screenshot — animated height widget menyebabkan layout conflict.
        Builder(
          builder: (ctx) {
            final maxVal = values.values.reduce((a, b) => a > b ? a : b);
            // Kumpulkan semua elemen yang tie (selisih < 0.001 untuk float safety)
            final tied = values.entries
                .where((e) => (e.value - maxVal).abs() < 0.001)
                .map((e) => e.key)
                .toList()
              ..sort(); // sort alfabetis → key deterministik

            final String narrativeKey;
            final Color color;
            if (tied.length >= 3) {
              // 3 atau 4 elemen seri → balanced
              narrativeKey = 'balanced';
              color = AppTheme.accentGold;
            } else if (tied.length == 2) {
              // Dual dominant — key: 'elemen1_elemen2' (sorted)
              narrativeKey = '${tied[0]}_${tied[1]}';
              color = AppTheme.accentGold;
            } else {
              // Single dominant
              narrativeKey = tied.first;
              color = switch (narrativeKey) {
                'geni' => AppTheme.elementFire,
                'banyu' => AppTheme.elementWater,
                'lemah' => AppTheme.elementEarth,
                _ => AppTheme.elementCosmic,
              };
            }

            final narrative = _kElementNarrative[narrativeKey];
            if (narrative == null) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.22)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('✦ ', style: GoogleFonts.outfit(fontSize: 11, color: color)),
                    Expanded(
                      child: Text(
                        narrative,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.78),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildElementChip(String label, double value, Color color) {
    final percent = (value * 100).toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $percent%',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}

class _WetonElementMandalaPainter extends CustomPainter {
  final double geni;
  final double banyu;
  final double lemah;
  final double angin;
  final double progress;

  _WetonElementMandalaPainter({
    required this.geni,
    required this.banyu,
    required this.lemah,
    required this.angin,
    this.progress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = (size.width / 2) * 0.75;

    // Background grid — fade in with progress
    final goldPaint = Paint()
      ..color = AppTheme.accentGold.withValues(alpha: 0.25 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final goldDottedPaint = Paint()
      ..color = AppTheme.accentGold.withValues(alpha: 0.12 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(center, maxRadius * (i / 4) * progress, goldPaint);
    }

    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius * progress),
      Offset(center.dx, center.dy + maxRadius * progress),
      goldDottedPaint,
    );
    canvas.drawLine(
      Offset(center.dx - maxRadius * progress, center.dy),
      Offset(center.dx + maxRadius * progress, center.dy),
      goldDottedPaint,
    );

    // Directional labels — fade in
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    void drawLabel(String text, Offset pos, Color color) {
      textPainter.text = TextSpan(
        text: text,
        style: GoogleFonts.playfairDisplay(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color.withValues(alpha: progress),
          height: 1.2,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
      );
    }

    drawLabel(
      'BANYU\n(North)',
      Offset(center.dx, center.dy - maxRadius - 16),
      AppTheme.elementWater,
    );
    drawLabel(
      'ANGIN\n(East)',
      Offset(center.dx + maxRadius + 22, center.dy),
      AppTheme.elementCosmic,
    );
    drawLabel(
      'GENI\n(South)',
      Offset(center.dx, center.dy + maxRadius + 16),
      AppTheme.elementFire,
    );
    drawLabel(
      'LEMAH\n(West)',
      Offset(center.dx - maxRadius - 22, center.dy),
      AppTheme.elementEarth,
    );

    // Radar diamond — expand from center based on progress
    final nVal = 0.2 + (banyu * 0.8);
    final eVal = 0.2 + (angin * 0.8);
    final sVal = 0.2 + (geni * 0.8);
    final wVal = 0.2 + (lemah * 0.8);

    final double nY = center.dy - (nVal.clamp(0.2, 1.0) * maxRadius * progress);
    final double eX = center.dx + (eVal.clamp(0.2, 1.0) * maxRadius * progress);
    final double sY = center.dy + (sVal.clamp(0.2, 1.0) * maxRadius * progress);
    final double wX = center.dx - (wVal.clamp(0.2, 1.0) * maxRadius * progress);

    final path = Path()
      ..moveTo(center.dx, nY)
      ..lineTo(eX, center.dy)
      ..lineTo(center.dx, sY)
      ..lineTo(wX, center.dy)
      ..close();

    final fillPaint = Paint()
      ..color = AppTheme.accentPurple.withValues(alpha: 0.2 * progress)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final strokePaint = Paint()
      ..color = AppTheme.accentGold.withValues(alpha: 0.7 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, strokePaint);

    canvas.drawCircle(
      center,
      3 * progress,
      Paint()..color = AppTheme.accentGold.withValues(alpha: progress),
    );
  }

  @override
  bool shouldRepaint(covariant _WetonElementMandalaPainter oldDelegate) {
    return oldDelegate.geni != geni ||
        oldDelegate.banyu != banyu ||
        oldDelegate.lemah != lemah ||
        oldDelegate.angin != angin ||
        oldDelegate.progress != progress;
  }
}
