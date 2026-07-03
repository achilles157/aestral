import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class CircadianRhythmWavePainter extends CustomPainter {
  final List<String> slots;

  CircadianRhythmWavePainter({required this.slots});

  @override
  void paint(Canvas canvas, Size size) {
    if (slots.isEmpty) return;

    final double width = size.width;
    final double height = size.height;
    final double centerX = width / 2;
    final double slotHeight = height / slots.length;

    final Path wavePath = Path();
    wavePath.moveTo(centerX, 0);

    double prevX = centerX;
    double prevY = 0;

    for (int i = 0; i < slots.length; i++) {
      final isBaik = slots[i] == 'baik';
      final double targetX = centerX + (isBaik ? 8.0 : -8.0);
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
    return oldDelegate.slots != slots;
  }
}
