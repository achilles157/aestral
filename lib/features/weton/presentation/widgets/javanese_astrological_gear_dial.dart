import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class JavaneseAstrologicalGearDial extends StatefulWidget {
  final String saptawara;
  final String pancawara;
  final String wuku;
  final int totalNeptu;

  const JavaneseAstrologicalGearDial({
    super.key,
    required this.saptawara,
    required this.pancawara,
    required this.wuku,
    required this.totalNeptu,
  });

  @override
  State<JavaneseAstrologicalGearDial> createState() => _JavaneseAstrologicalGearDialState();
}

class _JavaneseAstrologicalGearDialState extends State<JavaneseAstrologicalGearDial> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(280, 280),
                painter: _JavaneseAstrologicalGearDialPainter(
                  saptawara: widget.saptawara,
                  pancawara: widget.pancawara,
                  wuku: widget.wuku,
                  totalNeptu: widget.totalNeptu,
                  progress: _animation.value,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Keselarasan Kosmis: ${widget.saptawara} ${widget.pancawara} • Wuku ${widget.wuku}',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.accentGold,
          ),
        ),
      ],
    );
  }
}

class _JavaneseAstrologicalGearDialPainter extends CustomPainter {
  final String saptawara;
  final String pancawara;
  final String wuku;
  final int totalNeptu;
  final double progress;

  _JavaneseAstrologicalGearDialPainter({
    required this.saptawara,
    required this.pancawara,
    required this.wuku,
    required this.totalNeptu,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = (size.width / 2) * 0.95;

    final List<String> wukuList = [
      'sinta', 'landep', 'wukir', 'kurantil', 'tolu', 'gumbreg', 'warigalit', 'warigagung',
      'julungwangi', 'sungsang', 'galungan', 'kuningan', 'langkir', 'mandasiya', 'julungpujut',
      'pahang', 'kuruwelut', 'marakeh', 'tambir', 'medangkungan', 'maktal', 'wuye',
      'manahil', 'prangbakat', 'bala', 'wugu', 'wayang', 'kulawu', 'dukut', 'watugunung'
    ];

    final String s = saptawara.toLowerCase();
    int sIdx = 0;
    if (s.contains('minggu') || s.contains('ahad')) {
      sIdx = 0;
    } else if (s.contains('senin')) {
      sIdx = 1;
    } else if (s.contains('selasa')) {
      sIdx = 2;
    } else if (s.contains('rabu')) {
      sIdx = 3;
    } else if (s.contains('kamis')) {
      sIdx = 4;
    } else if (s.contains('jumat')) {
      sIdx = 5;
    } else if (s.contains('sabtu')) {
      sIdx = 6;
    }

    final String p = pancawara.toLowerCase();
    int pIdx = 0;
    if (p.contains('legi')) {
      pIdx = 0;
    } else if (p.contains('pahing')) {
      pIdx = 1;
    } else if (p.contains('pon')) {
      pIdx = 2;
    } else if (p.contains('wage')) {
      pIdx = 3;
    } else if (p.contains('kliwon')) {
      pIdx = 4;
    }

    final String w = wuku.toLowerCase();
    int wIdx = wukuList.indexWhere((element) => w.contains(element));
    if (wIdx == -1) {
      wIdx = 0;
    }

    // Target rotation angles to place active segment at top (12 o'clock / -pi/2)
    final double rot1 = -math.pi / 2 - (sIdx * (2 * math.pi / 7) + (math.pi / 7));
    final double rot2 = -math.pi / 2 - (pIdx * (2 * math.pi / 5) + (math.pi / 5));
    final double rot3 = -math.pi / 2 - (wIdx * (2 * math.pi / 30) + (math.pi / 30));

    // Dynamic interpolated spin
    final double currentRot1 = (1.0 - progress) * (4 * math.pi) + (progress * rot1);
    final double currentRot2 = (1.0 - progress) * (-5 * math.pi) + (progress * rot2);
    final double currentRot3 = (1.0 - progress) * (6 * math.pi) + (progress * rot3);

    final outerBorderPaint = Paint()
      ..color = AppTheme.accentGold.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final segmentPaint = Paint()
      ..color = AppTheme.accentGold.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    // 1. Draw Outer Ring (Saptawara)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(currentRot1);

    canvas.drawCircle(Offset.zero, maxRadius, outerBorderPaint);
    canvas.drawCircle(Offset.zero, maxRadius - 22, outerBorderPaint);

    final List<String> saptawaraDisplay = ['Ahad', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

    for (int i = 0; i < 7; i++) {
      final double angle = i * (2 * math.pi / 7);
      
      canvas.drawLine(
        Offset((maxRadius - 22) * math.cos(angle), (maxRadius - 22) * math.sin(angle)),
        Offset(maxRadius * math.cos(angle), maxRadius * math.sin(angle)),
        segmentPaint,
      );

      final double midAngle = angle + (math.pi / 7);
      canvas.save();
      canvas.rotate(midAngle);
      
      final isCurrent = (i == sIdx);
      
      textPainter.text = TextSpan(
        text: saptawaraDisplay[i],
        style: GoogleFonts.outfit(
          fontSize: 8.5,
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          color: isCurrent ? AppTheme.accentGold : AppTheme.textMuted.withValues(alpha: 0.75),
        ),
      );
      textPainter.layout();
      
      final double textRadius = maxRadius - 11;
      canvas.translate(textRadius, 0);
      canvas.rotate(math.pi / 2);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }
    canvas.restore();

    // 2. Draw Middle Ring (Pancawara)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(currentRot2);

    final double rMidOuter = maxRadius - 26;
    final double rMidInner = rMidOuter - 20;

    canvas.drawCircle(Offset.zero, rMidOuter, outerBorderPaint);
    canvas.drawCircle(Offset.zero, rMidInner, outerBorderPaint);

    final List<String> pancawaraDisplay = ['Legi', 'Pahing', 'Pon', 'Wage', 'Kliwon'];

    for (int i = 0; i < 5; i++) {
      final double angle = i * (2 * math.pi / 5);
      
      canvas.drawLine(
        Offset(rMidInner * math.cos(angle), rMidInner * math.sin(angle)),
        Offset(rMidOuter * math.cos(angle), rMidOuter * math.sin(angle)),
        segmentPaint,
      );

      final double midAngle = angle + (math.pi / 5);
      canvas.save();
      canvas.rotate(midAngle);

      final isCurrent = (i == pIdx);

      textPainter.text = TextSpan(
        text: pancawaraDisplay[i],
        style: GoogleFonts.outfit(
          fontSize: 8.5,
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          color: isCurrent ? AppTheme.accentGold : AppTheme.textMuted.withValues(alpha: 0.75),
        ),
      );
      textPainter.layout();

      final double textRadius = rMidOuter - 10;
      canvas.translate(textRadius, 0);
      canvas.rotate(math.pi / 2);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }
    canvas.restore();

    // 3. Draw Inner Ring (Wuku Gear Wheel)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(currentRot3);

    final double rWukuOuter = rMidInner - 8;
    final double rWukuInner = rWukuOuter - 16;

    final gearPaint = Paint()
      ..color = AppTheme.accentPurple.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final gearStrokePaint = Paint()
      ..color = AppTheme.accentGold.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    _drawGearWheel(canvas, Offset.zero, rWukuOuter, rWukuOuter - 3, 30, gearPaint);
    _drawGearWheel(canvas, Offset.zero, rWukuOuter, rWukuOuter - 3, 30, gearStrokePaint);
    canvas.drawCircle(Offset.zero, rWukuInner, gearStrokePaint);

    for (int i = 0; i < 30; i++) {
      final double angle = i * (2 * math.pi / 30);
      final isCurrent = (i == wIdx);

      final tickPaint = Paint()
        ..color = isCurrent ? AppTheme.accentGold : AppTheme.accentGold.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isCurrent ? 1.5 : 0.8;

      canvas.drawLine(
        Offset(rWukuInner * math.cos(angle), rWukuInner * math.sin(angle)),
        Offset((rWukuOuter - 3) * math.cos(angle), (rWukuOuter - 3) * math.sin(angle)),
        tickPaint,
      );

      if (isCurrent) {
        canvas.drawCircle(
          Offset((rWukuOuter - 2) * math.cos(angle), (rWukuOuter - 2) * math.sin(angle)),
          2.0,
          Paint()..color = AppTheme.accentGold,
        );
      }
    }
    canvas.restore();

    // 4. Draw Neptu Center Hub
    final double rHub = rWukuInner - 3;
    
    final hubFillPaint = Paint()
      ..color = const Color(0xFF130E30).withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, rHub, hubFillPaint);

    final hubStrokePaint = Paint()
      ..color = AppTheme.accentGold.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, rHub, hubStrokePaint);

    final glowPaint = Paint()
      ..color = AppTheme.accentGold.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, rHub * 0.85, glowPaint);

    final neptuLabelPainter = TextPainter(
      text: TextSpan(
        text: 'NEPTU',
        style: GoogleFonts.outfit(
          fontSize: 7.5,
          fontWeight: FontWeight.bold,
          color: AppTheme.accentGold.withValues(alpha: 0.8),
          letterSpacing: 1.0,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    neptuLabelPainter.paint(
      canvas,
      Offset(center.dx - neptuLabelPainter.width / 2, center.dy - rHub * 0.45),
    );

    final neptuValPainter = TextPainter(
      text: TextSpan(
        text: '$totalNeptu',
        style: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppTheme.textLight,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    neptuValPainter.paint(
      canvas,
      Offset(center.dx - neptuValPainter.width / 2, center.dy - neptuValPainter.height / 2 + 1),
    );

    // 5. Draw Vertical Alignment Pointer over everything
    final pointerPaint = Paint()
      ..color = AppTheme.accentGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final pointerGlowPaint = Paint()
      ..color = AppTheme.accentGold.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    final double pStartY = center.dy - maxRadius - 6;
    final double pEndY = center.dy - rHub;

    canvas.drawLine(Offset(center.dx, pStartY), Offset(center.dx, pEndY), pointerGlowPaint);
    canvas.drawLine(Offset(center.dx, pStartY), Offset(center.dx, pEndY), pointerPaint);

    final path = Path()
      ..moveTo(center.dx - 4, pStartY)
      ..lineTo(center.dx + 4, pStartY)
      ..lineTo(center.dx, pStartY + 5)
      ..close();

    canvas.drawPath(path, Paint()..color = AppTheme.accentGold);
  }

  void _drawGearWheel(Canvas canvas, Offset center, double outerRadius, double innerRadius, int numTeeth, Paint paint) {
    final Path path = Path();
    final double anglePerSegment = 2 * math.pi / numTeeth;

    for (int i = 0; i < numTeeth; i++) {
      final double startAngle = i * anglePerSegment;
      final double midAngle1 = startAngle + anglePerSegment * 0.35;
      final double midAngle2 = startAngle + anglePerSegment * 0.65;
      final double endAngle = (i + 1) * anglePerSegment;

      final double ox1 = center.dx + outerRadius * math.cos(startAngle);
      final double oy1 = center.dy + outerRadius * math.sin(startAngle);
      final double ox2 = center.dx + outerRadius * math.cos(midAngle1);
      final double oy2 = center.dy + outerRadius * math.sin(midAngle1);
      final double ix1 = center.dx + innerRadius * math.cos(midAngle2);
      final double iy1 = center.dy + innerRadius * math.sin(midAngle2);
      final double ix2 = center.dx + innerRadius * math.cos(endAngle);
      final double iy2 = center.dy + innerRadius * math.sin(endAngle);

      if (i == 0) {
        path.moveTo(ox1, oy1);
      } else {
        path.lineTo(ox1, oy1);
      }
      path.lineTo(ox2, oy2);
      path.lineTo(ix1, iy1);
      path.lineTo(ix2, iy2);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _JavaneseAstrologicalGearDialPainter oldDelegate) {
    return oldDelegate.saptawara != saptawara ||
        oldDelegate.pancawara != pancawara ||
        oldDelegate.wuku != wuku ||
        oldDelegate.totalNeptu != totalNeptu ||
        oldDelegate.progress != progress;
  }
}
