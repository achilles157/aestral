import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/widgets/starry_background.dart';
import '../../domain/bazi_chart.dart';
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

class _BaziCanvasScreenState extends State<BaziCanvasScreen> {
  late int _selectedHour;
  late int _selectedDecadeIdx;

  @override
  void initState() {
    super.initState();
    _selectedHour = DateTime.now().hour;

    _selectedDecadeIdx = 0;
    if (widget.luckPillars.isNotEmpty) {
      // Compute real age from birthDate — NOT adjustedHour (which is 0–23, not age)
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
  Widget build(BuildContext context) {
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
          const Positioned.fill(child: StarryBackground()),
          Column(
            children: [
              const SizedBox(height: 4),
              WuXingMiniDisplay(
                chart: widget.chart,
                selectedHour: _selectedHour,
              ),
              Expanded(
                child: HourDialWidget(
                  chart: widget.chart,
                  selectedHour: _selectedHour,
                  timetableDay: widget.timetableDay,
                  onHourChanged: (hour) {
                    setState(() => _selectedHour = hour);
                  },
                ),
              ),
              DaYunCanvasWheel(
                pillars: widget.luckPillars,
                selectedIdx: _selectedDecadeIdx,
                onDecadeSelected: (idx) {
                  setState(() => _selectedDecadeIdx = idx);
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
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
