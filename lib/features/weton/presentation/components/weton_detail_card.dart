import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';

class WetonDetailCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color accentColor;
  final EdgeInsetsGeometry? margin;

  const WetonDetailCard({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
    required this.accentColor,
    this.margin = const EdgeInsets.only(bottom: 16),
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      margin: margin,
      borderColor: accentColor.withValues(alpha: 0.35),
      borderWidth: 1.5,
      borderRadius: 20,
      padding: EdgeInsets.zero, // Zero padding to allow watermark overflow clip
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accentColor.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.02),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: accentColor.withValues(alpha: 0.12),
          blurRadius: 16,
          spreadRadius: -2,
          offset: const Offset(0, 4),
        ),
      ],
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // Javanese Sacred Geometry Watermark (Kiblat Papat Kalima Pancer)
          Positioned(
            right: -25,
            bottom: -25,
            child: IgnorePointer(
              child: CustomPaint(
                size: const Size(120, 120),
                painter: WatermarkMandalaPainter(color: accentColor),
              ),
            ),
          ),
          // Card Content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Mini badge for the card icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: accentColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: textTheme.titleLarge?.copyWith(
                          color: accentColor,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  content,
                  style: textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WatermarkMandalaPainter extends CustomPainter {
  final Color color;

  WatermarkMandalaPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
          .withValues(alpha: 0.06) // Very subtle Javanese watermark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Draw concentric cosmic circles
    canvas.drawCircle(center, maxRadius, paint);
    canvas.drawCircle(center, maxRadius * 0.7, paint);
    canvas.drawCircle(center, maxRadius * 0.42, paint);

    // Draw 8 compass/constellation lines
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * math.pi / 180;
      final x = center.dx + maxRadius * math.cos(angle);
      final y = center.dy + maxRadius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), paint);
    }

    // Draw Javanese symbolic star nodes
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * math.pi / 180;
      final x = center.dx + (maxRadius * 0.7) * math.cos(angle);
      final y = center.dy + (maxRadius * 0.7) * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WatermarkMandalaPainter oldDelegate) =>
      oldDelegate.color != color;
}
