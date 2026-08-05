import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/radial_glow_painter.dart';

class AstrologicalPlannerCalendarGrid extends StatelessWidget {
  final Map<String, dynamic> calendarData;
  final DateTime currentMonth;
  final ValueChanged<Map<String, dynamic>> onDayTapped;

  /// Format "Saptawara Pancawara" (e.g. "Senin Pon") — untuk highlight Hari Weton.
  /// Null jika birth date tidak tersedia.
  final String? birthWetonStr;

  const AstrologicalPlannerCalendarGrid({
    super.key,
    required this.calendarData,
    required this.currentMonth,
    required this.onDayTapped,
    this.birthWetonStr,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        // Scale fonts and cell proportions based on available width
        final cellWidth =
            (constraints.maxWidth - 24) / 7; // 24 = padding + spacing
        final dateFontSize = (cellWidth * 0.22).clamp(11.0, 18.0);
        final pasaranFontSize = (cellWidth * 0.13).clamp(8.0, 12.0);
        final dotRadius = (cellWidth * 0.06).clamp(3.0, 5.5);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: GlassCard(
              borderColor: AppTheme.accentPurple.withValues(alpha: 0.25),
              borderWidth: 1.0,
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: weekdays
                        .map(
                          (day) => Expanded(
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
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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

                      final dayData =
                          days[index - prefixBlankCells]
                              as Map<String, dynamic>;
                      final date = DateTime.tryParse(
                        dayData['date'] as String? ?? '',
                      );
                      if (date == null) return const SizedBox.shrink();
                      final wetonStr =
                          dayData['weton_hari_ini'] as String? ?? '';
                      final pasaran = wetonStr.split(' ').last;
                      final bool isHariWeton =
                          birthWetonStr != null && wetonStr == birthWetonStr;

                      final pancasudaRaw = dayData['pancasuda'];
                      final pancasuda = pancasudaRaw is Map<String, dynamic>
                          ? pancasudaRaw
                          : <String, dynamic>{};
                      final vibe =
                          pancasuda['vibe_warna'] as String? ?? 'putih';
                      final isMangsaRawan =
                          dayData['is_mangsa_rawan'] as bool? ?? false;
                      final statusColor = isMangsaRawan
                          ? AppTheme.accentGold
                          : _getPancasudaColor(vibe);

                      final isToday = DateUtils.isSameDay(date, DateTime.now());
                      // Dino Was: personal naas day — shown as red indicator dot
                      final bool isDinoWas =
                          dayData['is_dino_was'] as bool? ?? false;
                      final bool isWukuRawan =
                          dayData['is_wuku_rawan'] as bool? ?? false;
                      final bool isBaziClash =
                          dayData['is_bazi_clash'] as bool? ?? false;
                      final bool isBaziHarmony =
                          dayData['is_bazi_harmony'] as bool? ?? false;
                      final bool isBaziYongShen =
                          dayData['is_bazi_yong_shen'] as bool? ?? false;

                      return InkWell(
                        onTap: () => onDayTapped(dayData),
                        borderRadius: BorderRadius.circular(12),
                        child: GlassCard(
                          borderRadius: 12,
                          borderColor: isHariWeton
                              ? AppTheme.accentGold.withValues(alpha: 0.80)
                              : isToday
                              ? AppTheme.accentPurple.withValues(alpha: 0.6)
                              : isMangsaRawan
                              ? AppTheme.accentGold.withValues(alpha: 0.55)
                              : Colors.white.withValues(alpha: 0.08),
                          borderWidth: isHariWeton
                              ? 1.8
                              : isToday
                              ? 1.5
                              : (isMangsaRawan ? 1.2 : 0.8),
                          color: isHariWeton
                              ? AppTheme.accentGold.withValues(alpha: 0.13)
                              : isToday
                              ? AppTheme.accentPurple.withValues(alpha: 0.12)
                              : isMangsaRawan
                              ? AppTheme.accentGold.withValues(alpha: 0.09)
                              : Colors.white.withValues(alpha: 0.03),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: RadialGlowPainter(
                                    glowColor: statusColor,
                                    radiusMultiplier: 0.8,
                                    opacity: 0.2,
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: Text(
                                      date.day.toString(),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(
                                        fontSize: dateFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: isMangsaRawan
                                            ? AppTheme.accentGold
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  SizedBox(
                                    width: double.infinity,
                                    child: Text(
                                      pasaran,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(
                                        fontSize: pasaranFontSize,
                                        color: isMangsaRawan
                                            ? AppTheme.accentGold.withValues(
                                                alpha: 0.8,
                                              )
                                            : AppTheme.textLight.withValues(
                                                alpha: 0.6,
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Dino Was indicator — small red dot in top-right corner
                              if (isDinoWas)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: CircleAvatar(
                                    radius: dotRadius,
                                    backgroundColor: const Color(0xFFF87171),
                                  ),
                                ),
                              // Hari Weton indicator — gold sparkle dot in top-left corner
                              if (isHariWeton)
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: CircleAvatar(
                                    radius: dotRadius,
                                    backgroundColor: AppTheme.accentGold,
                                  ),
                                ),
                              // Row of dots for multiple indicators
                              if (isWukuRawan ||
                                  isBaziClash ||
                                  isBaziHarmony ||
                                  isBaziYongShen)
                                Positioned(
                                  bottom: 4,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (isWukuRawan)
                                        Container(
                                          width: dotRadius * 1.5,
                                          height: dotRadius * 1.5,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(
                                              0xFFFB923C,
                                            ), // Amber for Wuku
                                          ),
                                        ),
                                      if (isBaziClash) ...[
                                        if (isWukuRawan)
                                          const SizedBox(width: 4),
                                        Container(
                                          width: dotRadius * 1.5,
                                          height: dotRadius * 1.5,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(
                                              0xFFF87171,
                                            ), // Red for Ba Zi Clash
                                          ),
                                        ),
                                      ],
                                      if (isBaziHarmony) ...[
                                        if (isWukuRawan || isBaziClash)
                                          const SizedBox(width: 4),
                                        Container(
                                          width: dotRadius * 1.5,
                                          height: dotRadius * 1.5,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(
                                              0xFF34D399,
                                            ), // Emerald Green for Ba Zi Harmony
                                          ),
                                        ),
                                      ],
                                      if (isBaziYongShen) ...[
                                        if (isWukuRawan ||
                                            isBaziClash ||
                                            isBaziHarmony)
                                          const SizedBox(width: 4),
                                        Container(
                                          width: dotRadius * 1.5,
                                          height: dotRadius * 1.5,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(
                                              0xFFFFD700,
                                            ), // Gold for Ba Zi Yong Shen
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildLegendItem(
                          color: const Color(0xFFF87171),
                          label: 'Hari Naas (Dino Was)',
                          isDot: true,
                        ),
                        _buildLegendItem(
                          color: const Color(0xFFFB923C),
                          label: 'Pekan Rawan (Wuku)',
                          isDot: true,
                        ),
                        _buildLegendItem(
                          color: const Color(0xFFD4AF37),
                          label: 'Musim Rawan (Mangsa)',
                          isDot: false,
                        ),
                        _buildLegendItem(
                          color: const Color(0xFFF87171),
                          label: 'Hari Clash (Ba Zi)',
                          isDot: true,
                        ),
                        _buildLegendItem(
                          color: const Color(0xFF34D399),
                          label: 'Hari Harmoni (Ba Zi)',
                          isDot: true,
                        ),
                        _buildLegendItem(
                          color: const Color(0xFFFFD700),
                          label: 'Hari Yong Shen (Ba Zi)',
                          isDot: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required bool isDot,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDot ? color : color.withValues(alpha: 0.15),
            border: isDot
                ? null
                : Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 11, color: Colors.white60),
        ),
      ],
    );
  }
}
