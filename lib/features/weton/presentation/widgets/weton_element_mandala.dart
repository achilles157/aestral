import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class WetonElementMandala extends StatelessWidget {
  final String saptawara;
  final String pancawara;

  const WetonElementMandala({
    super.key,
    required this.saptawara,
    required this.pancawara,
  });

  Map<String, double> get elementValues {
    double geni = 1.0;
    double banyu = 1.0;
    double lemah = 1.0;
    double angin = 1.0;

    final sStr = saptawara.toLowerCase();
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

    final pStr = pancawara.toLowerCase();
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
        Center(
          child: CustomPaint(
            size: const Size(260, 260),
            painter: _WetonElementMandalaPainter(
              geni: values['geni']!,
              banyu: values['banyu']!,
              lemah: values['lemah']!,
              angin: values['angin']!,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildElementChip('Geni (Api)', values['geni']!, const Color(0xFFF87171)),
            _buildElementChip('Banyu (Air)', values['banyu']!, const Color(0xFF60A5FA)),
            _buildElementChip('Lemah (Tanah)', values['lemah']!, AppTheme.accentGold),
            _buildElementChip('Angin (Udara)', values['angin']!, const Color(0xFFC084FC)),
          ],
        )
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
                BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 4, spreadRadius: 1),
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

  _WetonElementMandalaPainter({
    required this.geni,
    required this.banyu,
    required this.lemah,
    required this.angin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = (size.width / 2) * 0.75;

    final goldPaint = Paint()
      ..color = AppTheme.accentGold.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final goldDottedPaint = Paint()
      ..color = AppTheme.accentGold.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(center, maxRadius * (i / 4), goldPaint);
    }

    canvas.drawLine(Offset(center.dx, center.dy - maxRadius), Offset(center.dx, center.dy + maxRadius), goldDottedPaint);
    canvas.drawLine(Offset(center.dx - maxRadius, center.dy), Offset(center.dx + maxRadius, center.dy), goldDottedPaint);

    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );

    void drawLabel(String text, Offset pos, Color color) {
      textPainter.text = TextSpan(
        text: text,
        style: GoogleFonts.playfairDisplay(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
          height: 1.2,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2));
    }

    drawLabel('BANYU\n(North)', Offset(center.dx, center.dy - maxRadius - 16), const Color(0xFF60A5FA));
    drawLabel('ANGIN\n(East)', Offset(center.dx + maxRadius + 22, center.dy), const Color(0xFFC084FC));
    drawLabel('GENI\n(South)', Offset(center.dx, center.dy + maxRadius + 16), const Color(0xFFF87171));
    drawLabel('LEMAH\n(West)', Offset(center.dx - maxRadius - 22, center.dy), AppTheme.accentGold);

    final nVal = 0.2 + (banyu * 0.8);
    final eVal = 0.2 + (angin * 0.8);
    final sVal = 0.2 + (geni * 0.8);
    final wVal = 0.2 + (lemah * 0.8);

    final double nY = center.dy - (nVal.clamp(0.2, 1.0) * maxRadius);
    final double eX = center.dx + (eVal.clamp(0.2, 1.0) * maxRadius);
    final double sY = center.dy + (sVal.clamp(0.2, 1.0) * maxRadius);
    final double wX = center.dx - (wVal.clamp(0.2, 1.0) * maxRadius);

    final path = Path()
      ..moveTo(center.dx, nY)
      ..lineTo(eX, center.dy)
      ..lineTo(center.dx, sY)
      ..lineTo(wX, center.dy)
      ..close();

    final fillPaint = Paint()
      ..color = AppTheme.accentPurple.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final strokePaint = Paint()
      ..color = AppTheme.accentGold.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, strokePaint);

    canvas.drawCircle(center, 3, Paint()..color = AppTheme.accentGold);
  }

  @override
  bool shouldRepaint(covariant _WetonElementMandalaPainter oldDelegate) {
    return oldDelegate.geni != geni ||
        oldDelegate.banyu != banyu ||
        oldDelegate.lemah != lemah ||
        oldDelegate.angin != angin;
  }
}
