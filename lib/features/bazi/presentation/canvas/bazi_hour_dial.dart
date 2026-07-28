import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bazi_utils.dart';
import '../../domain/bazi_chart.dart';
import '../widgets/bazi_pillar_column.dart';
import '../widgets/bazi_shared_constants.dart';

class HourDialWidget extends StatefulWidget {
  const HourDialWidget({
    super.key,
    required this.chart,
    required this.selectedHour,
    this.timetableDay,
    required this.onHourChanged,
  });

  final BaziChart chart;
  final int selectedHour;
  final Map<String, dynamic>? timetableDay;
  final ValueChanged<int> onHourChanged;

  @override
  State<HourDialWidget> createState() => _HourDialWidgetState();
}

class _HourDialWidgetState extends State<HourDialWidget> {
  double _cumulativeRotation = 0.0;
  double _lastPanAngle = 0.0;

  @override
  void initState() {
    super.initState();
    final initialBranchIdx = ((widget.selectedHour + 1) % 24) ~/ 2;
    _cumulativeRotation = -initialBranchIdx * (2 * pi / 12);
  }

  @override
  void didUpdateWidget(HourDialWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync rotation if parent programmatically changes selectedHour
    if (oldWidget.selectedHour != widget.selectedHour) {
      final newBranchIdx = ((widget.selectedHour + 1) % 24) ~/ 2;
      setState(() {
        _cumulativeRotation = -newBranchIdx * (2 * pi / 12);
      });
    }
  }

  void _onPanStart(DragStartDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final offset = details.localPosition - center;
    _lastPanAngle = atan2(offset.dy, offset.dx);
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final offset = details.localPosition - center;
    final currentPanAngle = atan2(offset.dy, offset.dx);
    final delta = currentPanAngle - _lastPanAngle;

    setState(() {
      _cumulativeRotation += delta;
      _lastPanAngle = currentPanAngle;
    });

    final normalisedAngle =
        (_cumulativeRotation % (2 * pi) + (2 * pi)) % (2 * pi);

    final branchIndex = (12 - ((normalisedAngle / (pi / 6)).floor() % 12)) % 12;

    final calculatedHour = (branchIndex * 2 + 23) % 24;
    if (calculatedHour != widget.selectedHour) {
      widget.onHourChanged(calculatedHour);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dimension = min(constraints.maxWidth, constraints.maxHeight);
        final size = Size(dimension, dimension);

        return GestureDetector(
          onPanStart: (d) => _onPanStart(d, size),
          onPanUpdate: (d) => _onPanUpdate(d, size),
          child: RepaintBoundary(
            child: CustomPaint(
              size: size,
              painter: HourDialPainter(
                selectedHour: widget.selectedHour,
                rotation: _cumulativeRotation,
                chart: widget.chart,
                timetableDay: widget.timetableDay,
              ),
            ),
          ),
        );
      },
    );
  }
}

class HourDialPainter extends CustomPainter {
  const HourDialPainter({
    required this.selectedHour,
    required this.rotation,
    required this.chart,
    this.timetableDay,
  });

  final int selectedHour;
  final double rotation;
  final BaziChart chart;
  final Map<String, dynamic>? timetableDay;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width * 0.38;
    const sliceAngle = (2 * pi) / 12;
    const gapAngle = 0.04;

    final selectedBranchIdx = ((selectedHour + 1) % 24) ~/ 2;

    for (int i = 0; i < 12; i++) {
      final startAngle = sliceAngle * i + rotation - (pi / 2);
      final isSelected = (i == selectedBranchIdx);
      final element = BaziUtils.branchElements[i];
      final color = kBaziElementColors[element] ?? Colors.white;

      final arcPaint = Paint()
        ..color = color.withValues(alpha: isSelected ? 0.90 : 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 32.0 : 20.0
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        sliceAngle - gapAngle,
        false,
        arcPaint,
      );

      if (isSelected) {
        final glowPaint = Paint()
          ..color = color.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 46.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: outerRadius),
          startAngle,
          sliceAngle - gapAngle,
          false,
          glowPaint,
        );
      }

      final midAngle = startAngle + (sliceAngle / 2);
      final labelOffset = Offset(
        center.dx + (outerRadius + 24) * cos(midAngle),
        center.dy + (outerRadius + 24) * sin(midAngle),
      );
      _drawText(
        canvas,
        kBaziBranchSymbol[i],
        labelOffset,
        color.withValues(alpha: isSelected ? 1.0 : 0.6),
        isSelected ? 15.0 : 11.0,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      );
    }

    _drawCenterDisplay(canvas, center, outerRadius);
    _drawTopPointer(canvas, center, outerRadius);
  }

  void _drawCenterDisplay(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius * 0.62,
      Paint()..color = AppTheme.cardBg.withValues(alpha: 0.85),
    );
    canvas.drawCircle(
      center,
      radius * 0.62,
      Paint()
        ..color = AppTheme.accentGold.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final hourBranchIdx = ((selectedHour + 1) % 24) ~/ 2;
    final branchSymbol = kBaziBranchSymbol[hourBranchIdx];
    final branchName = kBaziBranchName[hourBranchIdx];

    _drawText(
      canvas,
      '$selectedHour:00',
      center.translate(0, -22),
      Colors.white,
      18,
      fontWeight: FontWeight.bold,
    );

    _drawText(
      canvas,
      'Jam $branchName ($branchSymbol)',
      center.translate(0, 2),
      AppTheme.accentGold,
      11,
      fontWeight: FontWeight.w600,
    );

    final element = BaziUtils.branchElements[hourBranchIdx];
    final color = kBaziElementColors[element] ?? Colors.white;
    _drawText(
      canvas,
      'Elemen ${element.toUpperCase()}',
      center.translate(0, 20),
      color,
      10,
    );
  }

  void _drawTopPointer(Canvas canvas, Offset center, double radius) {
    final pointerPaint = Paint()
      ..color = AppTheme.accentGold
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(center.dx, center.dy - radius - 16)
      ..lineTo(center.dx - 7, center.dy - radius - 28)
      ..lineTo(center.dx + 7, center.dy - radius - 28)
      ..close();

    canvas.drawPath(path, pointerPaint);
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
  bool shouldRepaint(covariant HourDialPainter oldDelegate) {
    return oldDelegate.selectedHour != selectedHour ||
        oldDelegate.rotation != rotation;
  }
}
