import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class StarryBackground extends StatelessWidget {
  const StarryBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _StarsPainter(),
    );
  }
}

class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    // Deterministic random generator so the stars don't flicker on repaint
    final random = Random(42);
    for (int i = 0; i < 40; i++) {
      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height;
      final double radius = random.nextDouble() * 1.8 + 0.5;
      
      // Draw glow for some stars
      if (random.nextDouble() > 0.8) {
        final glowPaint = Paint()
          ..color = AppTheme.accentGold.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), radius * 3, glowPaint);
      }
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MandalaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accentGold.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Draw concentric circles
    for (double r = maxRadius * 0.3; r <= maxRadius; r += maxRadius * 0.15) {
      canvas.drawCircle(center, r, paint);
    }

    // Draw geometric rays/lines
    const rayCount = 12;
    for (int i = 0; i < rayCount; i++) {
      final angle = (i * 2 * pi) / rayCount;
      final dx = maxRadius * cos(angle);
      final dy = maxRadius * sin(angle);
      canvas.drawLine(center, center + Offset(dx, dy), paint);
    }

    // Draw overlapping circles (Flower of Life style)
    const petals = 6;
    for (int i = 0; i < petals; i++) {
      final angle = (i * 2 * pi) / petals;
      final offsetRadius = maxRadius * 0.45;
      final petalCenter = center + Offset(offsetRadius * cos(angle), offsetRadius * sin(angle));
      canvas.drawCircle(petalCenter, maxRadius * 0.45, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
