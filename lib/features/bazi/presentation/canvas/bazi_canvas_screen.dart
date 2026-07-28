import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bazi_utils.dart';
import '../../../home/presentation/widgets/starry_background.dart';
import '../../domain/bazi_chart.dart';
import '../widgets/bazi_pillar_column.dart';
import 'bazi_canvas_detail_panel.dart';
import 'bazi_dayun_canvas_wheel.dart';
import 'bazi_hour_dial.dart';
import 'widgets/wuxing_mini_display.dart';

class BaziCanvasScreen extends StatefulWidget {
  const BaziCanvasScreen({
    super.key,
    required this.chart,
    required this.luckPillars,
    required this.birthDate,
    this.timetableDay,
  });

  final BaziChart chart;
  final List<LuckPillar> luckPillars;
  final DateTime birthDate;
  final Map<String, dynamic>? timetableDay;

  @override
  State<BaziCanvasScreen> createState() => _BaziCanvasScreenState();
}

class _BaziCanvasScreenState extends State<BaziCanvasScreen>
    with TickerProviderStateMixin {
  late int _selectedHour;
  late int _selectedDecadeIdx;

  // Ambient glow — follows current hour element color
  late AnimationController _glowCtrl;
  late Color _glowColor;
  late Color _prevGlowColor;

  Color _elementColorForHour(int hour) {
    final branchIdx = ((hour + 1) % 24) ~/ 2;
    final element = BaziUtils.branchElements[branchIdx];
    return kBaziElementColors[element] ?? Colors.white;
  }

  @override
  void initState() {
    super.initState();
    _selectedHour = DateTime.now().hour;
    _glowColor = _elementColorForHour(_selectedHour);
    _prevGlowColor = _glowColor;

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _selectedDecadeIdx = 0;
    if (widget.luckPillars.isNotEmpty) {
      final now = DateTime.now();
      int currentAge = now.year - widget.birthDate.year;
      if (now.month < widget.birthDate.month ||
          (now.month == widget.birthDate.month &&
              now.day < widget.birthDate.day)) {
        currentAge--;
      }
      final activeIdx = widget.luckPillars.indexWhere(
        (lp) => currentAge >= lp.startAge && currentAge <= lp.endAge,
      );
      _selectedDecadeIdx = activeIdx != -1 ? activeIdx : 0;
    }
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  void _onHourChanged(int hour) {
    final newColor = _elementColorForHour(hour);
    setState(() {
      _prevGlowColor = _glowColor;
      _glowColor = newColor;
      _selectedHour = hour;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialSize = min(screenWidth * 0.85, 420.0);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white70,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Roda Kosmis',
          style: GoogleFonts.cinzel(
            color: AppTheme.accentGold,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // ── Starry background ──────────────────────────────────────────
          const Positioned.fill(child: StarryBackground()),

          // ── Ambient glow — transitions smoothly per hour element ───────
          TweenAnimationBuilder<Color?>(
            tween: ColorTween(begin: _prevGlowColor, end: _glowColor),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeInOut,
            builder: (_, animColor, _) {
              return AnimatedBuilder(
                animation: _glowCtrl,
                builder: (_, _) {
                  final pulse =
                      Curves.easeInOut.transform(_glowCtrl.value);
                  final c = animColor ?? _glowColor;
                  return Positioned(
                    top: -100,
                    left: -80,
                    child: Container(
                      width: 360,
                      height: 360,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            c.withValues(alpha: 0.10 + pulse * 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // ── Main content ───────────────────────────────────────────────
          Column(
            children: [
              const SizedBox(height: 4),
              WuXingMiniDisplay(
                chart: widget.chart,
                selectedHour: _selectedHour,
              ),
              const SizedBox(height: 8),
              // Dial: fixed size proportional to screen width, not Expanded
              SizedBox(
                width: dialSize,
                height: dialSize,
                child: HourDialWidget(
                  chart: widget.chart,
                  selectedHour: _selectedHour,
                  timetableDay: widget.timetableDay,
                  onHourChanged: _onHourChanged,
                ),
              ),
              const SizedBox(height: 12),
              // Da Yun horizontal strip — linear timeline
              DaYunStripWidget(
                pillars: widget.luckPillars,
                selectedIdx: _selectedDecadeIdx,
                onDecadeSelected: (idx) {
                  setState(() => _selectedDecadeIdx = idx);
                },
              ),
              const SizedBox(height: 90),
            ],
          ),

          // ── Detail panel (floating bottom sheet) ──────────────────────
          CanvasDetailPanel(
            selectedHour: _selectedHour,
            selectedDecadeIdx: _selectedDecadeIdx,
            chart: widget.chart,
            luckPillars: widget.luckPillars,
            timetableDay: widget.timetableDay,
          ),
        ],
      ),
    );
  }
}
