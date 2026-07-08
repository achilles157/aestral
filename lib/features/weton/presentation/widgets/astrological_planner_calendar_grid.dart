import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/radial_glow_painter.dart';

class AstrologicalPlannerCalendarGrid extends StatelessWidget {
  final Map<String, dynamic> calendarData;
  final DateTime currentMonth;
  final ValueChanged<Map<String, dynamic>> onDayTapped;

  const AstrologicalPlannerCalendarGrid({
    super.key,
    required this.calendarData,
    required this.currentMonth,
    required this.onDayTapped,
  });

  Color _getPancasudaColor(String vibe) {
    switch (vibe) {
      case 'green':
        return const Color(0xFF10B981);
      case 'gold':
        return AppTheme.accentGold;
      case 'blue':
        return const Color(0xFF3B82F6);
      case 'orange':
        return const Color(0xFFFB923C);
      case 'purple':
        return AppTheme.accentPurple;
      default:
        return AppTheme.textLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = calendarData['days'] as List<dynamic>? ?? [];
    if (days.isEmpty) return const SizedBox.shrink();

    final weekdays = ['Ming', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    final firstDayStr = days[0]['date'] as String;
    final firstDate = DateTime.parse(firstDayStr);
    final prefixBlankCells = firstDate.weekday == 7 ? 0 : firstDate.weekday;

    return GlassCard(
      borderColor: AppTheme.accentPurple.withValues(alpha: 0.25),
      borderWidth: 1.0,
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppTheme.accentGold,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 0.95,
            ),
            itemCount: prefixBlankCells + days.length,
            itemBuilder: (context, index) {
              if (index < prefixBlankCells) {
                return const SizedBox.shrink();
              }

              final dayData = days[index - prefixBlankCells] as Map<String, dynamic>;
              final date = DateTime.parse(dayData['date'] as String);
              final wetonStr = dayData['weton_hari_ini'] as String;
              final pasaran = wetonStr.split(' ').last;
              
              final pancasuda = dayData['pancasuda'] as Map<String, dynamic>;
              final vibe = pancasuda['vibe_warna'] as String;
              final statusColor = _getPancasudaColor(vibe);

              final isToday = DateUtils.isSameDay(date, DateTime.now());
              // Dino Was: personal naas day — shown as red indicator dot
              final bool isDinoWas = dayData['is_dino_was'] as bool? ?? false;

              return InkWell(
                onTap: () => onDayTapped(dayData),
                borderRadius: BorderRadius.circular(12),
                child: GlassCard(
                  borderRadius: 12,
                  borderColor: isToday
                      ? AppTheme.accentPurple.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.08),
                  borderWidth: isToday ? 1.5 : 0.8,
                  color: isToday
                      ? AppTheme.accentPurple.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.03),
                  child: Stack(
                    children: [
                      CustomPaint(
                        painter: RadialGlowPainter(
                          glowColor: statusColor,
                          radiusMultiplier: 0.8,
                          opacity: 0.2,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              date.day.toString(),
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              pasaran,
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                color: AppTheme.textLight.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Dino Was indicator — small red dot in top-right corner
                      if (isDinoWas)
                        const Positioned(
                          top: 4,
                          right: 4,
                          child: CircleAvatar(
                            radius: 3.5,
                            backgroundColor: Color(0xFFF87171),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
