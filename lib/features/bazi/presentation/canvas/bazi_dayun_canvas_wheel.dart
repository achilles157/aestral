import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/bazi_chart.dart';
import '../widgets/bazi_pillar_column.dart';

class DaYunCanvasWheel extends StatelessWidget {
  const DaYunCanvasWheel({
    super.key,
    required this.pillars,
    required this.selectedIdx,
    required this.onDecadeSelected,
  });

  final List<LuckPillar> pillars;
  final int selectedIdx;
  final ValueChanged<int> onDecadeSelected;

  void _handleTapUp(TapUpDetails details, Size size) {
    if (pillars.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final touchOffset = details.localPosition - center;
    final outerRadius = size.width * 0.36;
    final innerRadius = size.width * 0.12;

    final distance = touchOffset.distance;
    if (distance < innerRadius || distance > outerRadius) return;

    double angle = atan2(touchOffset.dy, touchOffset.dx) + (pi / 2);
    if (angle < 0) angle += (2 * pi);

    final sliceAngle = (2 * pi) / pillars.length.clamp(1, 8);
    final tappedIndex = (angle / sliceAngle).floor() % pillars.length;

    onDecadeSelected(tappedIndex);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dimension = min(constraints.maxWidth, 240.0);
        final size = Size(dimension, dimension);

        return SizedBox(
          width: dimension,
          height: dimension,
          child: GestureDetector(
            onTapUp: (details) => _handleTapUp(details, size),
            child: RepaintBoundary(
              child: CustomPaint(
                size: size,
                painter: DaYunWheelPainter(
                  pillars: pillars,
                  selectedIdx: selectedIdx,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class DaYunWheelPainter extends CustomPainter {
  const DaYunWheelPainter({required this.pillars, required this.selectedIdx});

  final List<LuckPillar> pillars;
  final int selectedIdx;

  @override
  void paint(Canvas canvas, Size size) {
    if (pillars.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width * 0.36;
    final innerRadius = size.width * 0.12;
    final count = pillars.length.clamp(1, 8);
    final sliceAngle = (2 * pi) / count;

    for (int i = 0; i < count; i++) {
      final lp = pillars[i];
      final startAngle = sliceAngle * i - (pi / 2);
      final isActive = (i == selectedIdx);
      final color = kBaziElementColors[lp.pillar.element] ?? Colors.white;

      final path = Path()
        ..moveTo(
          center.dx + innerRadius * cos(startAngle),
          center.dy + innerRadius * sin(startAngle),
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: outerRadius),
          startAngle,
          sliceAngle - 0.04,
          false,
        )
        ..lineTo(
          center.dx + innerRadius * cos(startAngle + sliceAngle - 0.04),
          center.dy + innerRadius * sin(startAngle + sliceAngle - 0.04),
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: innerRadius),
          startAngle + sliceAngle - 0.04,
          -(sliceAngle - 0.04),
          false,
        )
        ..close();

      canvas.drawPath(
        path,
        Paint()..color = color.withValues(alpha: isActive ? 0.25 : 0.08),
      );

      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: isActive ? 0.90 : 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isActive ? 2.5 : 1.0,
      );

      final midAngle = startAngle + (sliceAngle / 2);
      final labelRadius = (innerRadius + outerRadius) / 2;
      final labelPos = Offset(
        center.dx + labelRadius * cos(midAngle),
        center.dy + labelRadius * sin(midAngle),
      );

      _drawText(
        canvas,
        lp.pillar.stemSymbol,
        labelPos.translate(0, -6),
        color,
        isActive ? 15 : 11,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      );
      _drawText(
        canvas,
        '${lp.startAge}-${lp.endAge}',
        labelPos.translate(0, 10),
        color.withValues(alpha: 0.7),
        9,
      );

      if (isActive) {
        canvas.drawCircle(
          Offset(
            center.dx + outerRadius * 0.92 * cos(midAngle),
            center.dy + outerRadius * 0.92 * sin(midAngle),
          ),
          4,
          Paint()..color = color,
        );
      }
    }

    _drawCenterHub(canvas, center, innerRadius);
  }

  void _drawCenterHub(Canvas canvas, Offset center, double innerRadius) {
    canvas.drawCircle(
      center,
      innerRadius * 0.85,
      Paint()..color = AppTheme.cardBg.withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      center,
      innerRadius * 0.85,
      Paint()
        ..color = AppTheme.accentGold.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    _drawText(
      canvas,
      '大運',
      center,
      AppTheme.accentGold,
      11,
      fontWeight: FontWeight.bold,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position,
    Color color,
    double fontSize, {
    FontWeight fontWeight = FontWeight.normal,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant DaYunWheelPainter oldDelegate) {
    return oldDelegate.selectedIdx != selectedIdx ||
        oldDelegate.pillars != pillars;
  }
}
