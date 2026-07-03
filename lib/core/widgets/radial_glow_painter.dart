import 'dart:math' as math;
import 'package:flutter/material.dart';

class RadialGlowPainter extends CustomPainter {
  final Color glowColor;
  final double radiusMultiplier;
  final double opacity;

  RadialGlowPainter({
    required this.glowColor,
    this.radiusMultiplier = 0.8,
    this.opacity = 0.15,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * radiusMultiplier;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          glowColor.withValues(alpha: opacity),
          glowColor.withValues(alpha: opacity * 0.5),
          glowColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant RadialGlowPainter oldDelegate) {
    return oldDelegate.glowColor != glowColor ||
        oldDelegate.radiusMultiplier != radiusMultiplier ||
        oldDelegate.opacity != opacity;
  }
}
