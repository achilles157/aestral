import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class CircadianRhythmWavePainter extends CustomPainter {
  final List<double> amplitudes;

  CircadianRhythmWavePainter({required this.amplitudes});

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final double width = size.width;
    final double height = size.height;
    final double centerX = width / 2;
    final double slotHeight = height / amplitudes.length;

    final Path wavePath = Path();
    wavePath.moveTo(centerX, 0);

    double prevX = centerX;
    double prevY = 0;

    for (int i = 0; i < amplitudes.length; i++) {
      // Calculate horizontal offset based on amplitude value (range: -1.5 to 1.5)
      final double targetX = centerX + (amplitudes[i] * 10.0);
      final double targetY = (i + 0.5) * slotHeight;

      final double cp1x = prevX;
      final double cp1y = prevY + slotHeight * 0.4;
      final double cp2x = targetX;
      final double cp2y = targetY - slotHeight * 0.4;

      wavePath.cubicTo(cp1x, cp1y, cp2x, cp2y, targetX, targetY);

      prevX = targetX;
      prevY = targetY;
    }

    final double cp1x = prevX;
    final double cp1y = prevY + slotHeight * 0.4;
    final double cp2x = centerX;
    final double cp2y = height;
    wavePath.cubicTo(cp1x, cp1y, cp2x, cp2y, centerX, height);

    final glowPaint = Paint()
      ..color = AppTheme.accentGold.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawPath(wavePath, glowPaint);

    final threadPaint = Paint()
      ..color = AppTheme.accentGold.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawPath(wavePath, threadPaint);
  }

  @override
  bool shouldRepaint(covariant CircadianRhythmWavePainter oldDelegate) {
    return !listEquals(oldDelegate.amplitudes, amplitudes);
  }
}
