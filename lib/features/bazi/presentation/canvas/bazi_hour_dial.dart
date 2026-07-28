import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _HourDialWidgetState extends State<HourDialWidget>
    with SingleTickerProviderStateMixin {
  double _cumulativeRotation = 0.0;
  double _lastPanAngle = 0.0;
  bool _isPanning = false;

  late final AnimationController _snapCtrl;

  @override
  void initState() {
    super.initState();
    final initialBranchIdx = ((widget.selectedHour + 1) % 24) ~/ 2;
    _cumulativeRotation = -initialBranchIdx * (2 * pi / 12);

    _snapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void didUpdateWidget(HourDialWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync rotation only when parent changes hour programmatically (not during drag)
    if (oldWidget.selectedHour != widget.selectedHour && !_isPanning) {
      final newBranchIdx = ((widget.selectedHour + 1) % 24) ~/ 2;
      setState(() {
        _cumulativeRotation = -newBranchIdx * (2 * pi / 12);
      });
    }
  }

  @override
  void dispose() {
    _snapCtrl.dispose();
    super.dispose();
  }

  /// Returns the branch index currently pointed at by top pointer.
  int get _currentBranchIdx {
    final norm = (_cumulativeRotation % (2 * pi) + (2 * pi)) % (2 * pi);
    return (12 - ((norm / (pi / 6)).floor() % 12)) % 12;
  }

  void _onPanStart(DragStartDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final offset = details.localPosition - center;
    // Dead zone: touches within 15 % of dial radius are ignored.
    // This prevents the atan2 singularity near the origin that causes
    // hypersensitive jumps when the finger is close to the center.
    if (offset.distance < size.width * 0.15) return;
    _snapCtrl.stop();
    _isPanning = true;
    _lastPanAngle = atan2(offset.dy, offset.dx);
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (!_isPanning) return;
    final center = Offset(size.width / 2, size.height / 2);
    final offset = details.localPosition - center;
    if (offset.distance < size.width * 0.15) return;

    final currentPanAngle = atan2(offset.dy, offset.dx);
    var delta = currentPanAngle - _lastPanAngle;
    // Normalise delta to [-pi, pi] to handle the +pi/-pi wrap-around
    if (delta > pi) delta -= 2 * pi;
    if (delta < -pi) delta += 2 * pi;

    setState(() {
      _cumulativeRotation += delta;
      _lastPanAngle = currentPanAngle;
    });

    final calculatedHour = (_currentBranchIdx * 2 + 23) % 24;
    if (calculatedHour != widget.selectedHour) {
      HapticFeedback.selectionClick();
      widget.onHourChanged(calculatedHour);
    }
  }

  void _onPanEnd(DragEndDetails details, Size size) {
    if (!_isPanning) return;
    _isPanning = false;

    // Snap to the nearest branch segment boundary
    const sliceAngle = 2 * pi / 12;
    final targetRotation =
        ((_cumulativeRotation / sliceAngle).round()) * sliceAngle;

    final snapAnim = Tween<double>(
      begin: _cumulativeRotation,
      end: targetRotation,
    ).animate(CurvedAnimation(parent: _snapCtrl, curve: Curves.easeOut));

    void listener() {
      if (mounted) setState(() => _cumulativeRotation = snapAnim.value);
    }

    snapAnim.addListener(listener);
    _snapCtrl.forward(from: 0).then((_) {
      snapAnim.removeListener(listener);
      if (mounted) setState(() => _cumulativeRotation = targetRotation);
    });
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
          onPanEnd: (d) => _onPanEnd(d, size),
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
    final hubRadius = radius * 0.62;
    final hourBranchIdx = ((selectedHour + 1) % 24) ~/ 2;
    final element = BaziUtils.branchElements[hourBranchIdx];
    final elementColor = kBaziElementColors[element] ?? Colors.white;

    // Radial gradient fill — element color bleeds from center outward
    final gradientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          elementColor.withValues(alpha: 0.20),
          AppTheme.cardBg.withValues(alpha: 0.92),
        ],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: hubRadius),
      );
    canvas.drawCircle(center, hubRadius, gradientPaint);

    // Outer gold ring
    canvas.drawCircle(
      center,
      hubRadius,
      Paint()
        ..color = AppTheme.accentGold.withValues(alpha: 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Inner element-colored ring
    canvas.drawCircle(
      center,
      hubRadius - 7,
      Paint()
        ..color = elementColor.withValues(alpha: 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

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
    _drawText(
      canvas,
      'Elemen ${element.toUpperCase()}',
      center.translate(0, 20),
      elementColor,
      10,
    );
  }

  void _drawTopPointer(Canvas canvas, Offset center, double radius) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius - 16)
      ..lineTo(center.dx - 7, center.dy - radius - 28)
      ..lineTo(center.dx + 7, center.dy - radius - 28)
      ..close();
    canvas.drawPath(path, Paint()..color = AppTheme.accentGold);
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
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant HourDialPainter oldDelegate) =>
      oldDelegate.selectedHour != selectedHour ||
      oldDelegate.rotation != rotation;
}
