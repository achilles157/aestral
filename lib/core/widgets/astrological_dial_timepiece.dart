import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AstrologicalDialTimepiece extends StatefulWidget {
  final DateTime initialDateTime;
  final Function(DateTime) onDateTimeSelected;
  final bool showTime;

  const AstrologicalDialTimepiece({
    super.key,
    required this.initialDateTime,
    required this.onDateTimeSelected,
    this.showTime = false,
  });

  @override
  State<AstrologicalDialTimepiece> createState() => _AstrologicalDialTimepieceState();
}

class _AstrologicalDialTimepieceState extends State<AstrologicalDialTimepiece> {
  late int selectedDay;
  late int selectedMonth;
  late int selectedYear;
  late int selectedHour;
  late int selectedMinute;

  late FixedExtentScrollController dayController;
  late FixedExtentScrollController monthController;
  late FixedExtentScrollController yearController;
  late FixedExtentScrollController hourController;
  late FixedExtentScrollController minuteController;

  final years = List<int>.generate(201, (i) => 1900 + i); // 1900 to 2100
  final months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    final initDate = widget.initialDateTime;
    selectedDay = initDate.day;
    selectedMonth = initDate.month;
    selectedYear = initDate.year;
    selectedHour = initDate.hour;
    selectedMinute = initDate.minute;

    dayController = FixedExtentScrollController(initialItem: selectedDay - 1);
    monthController = FixedExtentScrollController(initialItem: selectedMonth - 1);
    yearController = FixedExtentScrollController(initialItem: years.indexOf(selectedYear));
    hourController = FixedExtentScrollController(initialItem: selectedHour);
    minuteController = FixedExtentScrollController(initialItem: selectedMinute);
  }

  @override
  void dispose() {
    dayController.dispose();
    monthController.dispose();
    yearController.dispose();
    hourController.dispose();
    minuteController.dispose();
    super.dispose();
  }

  int get maxDaysInMonth {
    if (selectedMonth == 2) {
      if ((selectedYear % 4 == 0 && selectedYear % 100 != 0) || selectedYear % 400 == 0) {
        return 29;
      }
      return 28;
    }
    if ([4, 6, 9, 11].contains(selectedMonth)) {
      return 30;
    }
    return 31;
  }

  void _updateDateTime() {
    final maxDays = maxDaysInMonth;
    if (selectedDay > maxDays) {
      selectedDay = maxDays;
      dayController.jumpToItem(selectedDay - 1);
    }
    final dt = DateTime(
      selectedYear,
      selectedMonth,
      selectedDay,
      selectedHour,
      selectedMinute,
    );
    widget.onDateTimeSelected(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wb_sunny_outlined, color: AppTheme.accentGold, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.showTime ? 'PENYELARASAN JAM LAHIR' : 'RITUAL TANGGAL LAHIR',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentGold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: widget.showTime
                ? Row(
                    children: [
                      Expanded(
                        child: _buildDialWheel(
                          controller: hourController,
                          itemCount: 24,
                          labelBuilder: (i) => '${i.toString().padLeft(2, '0')} Jam',
                          onChanged: (i) {
                            setState(() {
                              selectedHour = i;
                              _updateDateTime();
                            });
                          },
                        ),
                      ),
                      const Text(':', style: TextStyle(color: AppTheme.accentPurple, fontSize: 24, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: _buildDialWheel(
                          controller: minuteController,
                          itemCount: 60,
                          labelBuilder: (i) => '${i.toString().padLeft(2, '0')} Menit',
                          onChanged: (i) {
                            setState(() {
                              selectedMinute = i;
                              _updateDateTime();
                            });
                          },
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildDialWheel(
                          controller: dayController,
                          itemCount: maxDaysInMonth,
                          labelBuilder: (i) => '${i + 1} Tgl',
                          onChanged: (i) {
                            setState(() {
                              selectedDay = i + 1;
                              _updateDateTime();
                            });
                          },
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildDialWheel(
                          controller: monthController,
                          itemCount: 12,
                          labelBuilder: (i) => months[i],
                          onChanged: (i) {
                            setState(() {
                              selectedMonth = i + 1;
                              _updateDateTime();
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: _buildDialWheel(
                          controller: yearController,
                          itemCount: years.length,
                          labelBuilder: (i) => years[i].toString(),
                          onChanged: (i) {
                            setState(() {
                              selectedYear = years[i];
                              _updateDateTime();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPurple,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            ),
            child: const Text('Terapkan Keselarasan'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int) labelBuilder,
    required ValueChanged<int> onChanged,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 42,
      perspective: 0.003,
      diameterRatio: 1.2,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) {
          return Center(
            child: Text(
              labelBuilder(index),
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textLight,
              ),
            ),
          );
        },
      ),
    );
  }
}
