import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/bazi_chart.dart';
import 'bazi_pillar_column.dart' show kBaziElementColors;
import 'bazi_shared_constants.dart';

/// Wu Xing Pentagon Radar — animated 5-axis CustomPainter chart.
///
/// Axes (clockwise from top) follow the generation cycle:
///   木 Kayu → 火 Api → 土 Tanah → 金 Logam → 水 Air
class BaziWuXingRadar extends StatefulWidget {
  final WuXingBalance balance;

  const BaziWuXingRadar({super.key, required this.balance});

  @override
  State<BaziWuXingRadar> createState() => _BaziWuXingRadarState();
}

class _BaziWuXingRadarState extends State<BaziWuXingRadar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (_, __) {
        final total = widget.balance.total;
        final values = total > 0
            ? {
                'kayu':  widget.balance.kayu  / total,
                'api':   widget.balance.api   / total,
                'tanah': widget.balance.tanah / total,
                'logam': widget.balance.logam / total,
                'air':   widget.balance.air   / total,
              }
            : {'kayu': 0.0, 'api': 0.0, 'tanah': 0.0, 'logam': 0.0, 'air': 0.0};

        return Column(
          children: [
            Center(
              child: SizedBox(
                width: 280,
                height: 280,
                child: CustomPaint(
                  painter: _PentagonPainter(
                    values: values,
                    progress: _progress.value,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildLegend(values, widget.balance),
          ],
        );
      },
    );
  }

  Widget _buildLegend(Map<String, double> values, WuXingBalance bal) {
    final counts = [bal.kayu, bal.api, bal.tanah, bal.logam, bal.air];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        for (int i = 0; i < 5; i++)
          _chip(kBaziElementOrder[i], kBaziElementName[i], counts[i]),
      ],
    );
  }

  Widget _chip(String el, String label, int count) {
    final color = kBaziElementColors[el]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            '$label · $count',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Painter ─────────────────────────────────────────────────────────────────

class _PentagonPainter extends CustomPainter {
  final Map<String, double> values;
  final double progress;

  static const _order   = kBaziElementOrder;
  static const _symbols = kBaziElementSymbol;
  static const _labels  = kBaziElementName;

  const _PentagonPainter({required this.values, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center    = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 * 0.70;

    // ── Grid pentagons (4 rings) ─────────────────────────────────────────────
    final gridPaint = Paint()
      ..color      = AppTheme.accentGold.withValues(alpha: 0.16)
      ..style      = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (int g = 1; g <= 4; g++) {
      canvas.drawPath(
        _pentagon(center, maxRadius * g / 4 * progress), gridPaint);
    }

    // ── Axis lines ───────────────────────────────────────────────────────────
    final axisPaint = Paint()
      ..color      = AppTheme.accentGold.withValues(alpha: 0.10)
      ..strokeWidth = 0.8;
    for (int i = 0; i < 5; i++) {
      final a = _angle(i);
      canvas.drawLine(
        center,
        Offset(center.dx + maxRadius * progress * math.cos(a),
               center.dy + maxRadius * progress * math.sin(a)),
        axisPaint,
      );
    }

    // ── Data polygon ─────────────────────────────────────────────────────────
    final dataPath = Path();
    for (int i = 0; i < 5; i++) {
      final raw    = values[_order[i]] ?? 0.0;
      final mapped = 0.15 + raw * 0.85; // minimum 15% visibility
      final r      = maxRadius * mapped * progress;
      final a      = _angle(i);
      final pt     = Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
      i == 0 ? dataPath.moveTo(pt.dx, pt.dy) : dataPath.lineTo(pt.dx, pt.dy);
    }
    dataPath.close();

    canvas.drawPath(dataPath,
        Paint()
          ..color = AppTheme.accentPurple.withValues(alpha: 0.20)
          ..style = PaintingStyle.fill);
    canvas.drawPath(dataPath,
        Paint()
          ..color      = AppTheme.accentGold.withValues(alpha: 0.75)
          ..style      = PaintingStyle.stroke
          ..strokeWidth = 1.6);

    // ── Labels ───────────────────────────────────────────────────────────────
    for (int i = 0; i < 5; i++) {
      final a     = _angle(i);
      final color = kBaziElementColors[_order[i]]!;
      final lp    = Offset(
        center.dx + (maxRadius + 22) * math.cos(a),
        center.dy + (maxRadius + 22) * math.sin(a),
      );
      _paintText(canvas, _symbols[i], lp.translate(0, -9),
          GoogleFonts.playfairDisplay(
              fontSize: 14, color: color, fontWeight: FontWeight.w600));
      _paintText(canvas, _labels[i], lp.translate(0, 5),
          GoogleFonts.outfit(fontSize: 9, color: color.withValues(alpha: 0.80)));
    }

    // ── Center dot ───────────────────────────────────────────────────────────
    canvas.drawCircle(center, 3 * progress,
        Paint()..color = AppTheme.accentGold);
  }

  double _angle(int i) => -math.pi / 2 + i * 2 * math.pi / 5;

  Path _pentagon(Offset c, double r) {
    final p = Path();
    for (int i = 0; i < 5; i++) {
      final a = _angle(i);
      final pt = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }

  void _paintText(Canvas canvas, String text, Offset center, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center.translate(-tp.width / 2, -tp.height / 2));
  }

  @override
  bool shouldRepaint(_PentagonPainter old) =>
      old.progress != progress || old.values != values;
}
