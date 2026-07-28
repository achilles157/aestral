import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/bazi_utils.dart';
import '../../../domain/bazi_chart.dart';
import '../../widgets/bazi_pillar_column.dart';
import '../../widgets/bazi_shared_constants.dart';

class WuXingMiniDisplay extends StatelessWidget {
  const WuXingMiniDisplay({
    super.key,
    required this.chart,
    required this.selectedHour,
  });

  final BaziChart chart;
  final int selectedHour;

  int _getElementCount(WuXingBalance b, String element) {
    switch (element) {
      case 'kayu':
        return b.kayu;
      case 'api':
        return b.api;
      case 'tanah':
        return b.tanah;
      case 'logam':
        return b.logam;
      case 'air':
        return b.air;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = chart.wuXingBalance;

    // Compute current hour pillar element — makes display truly real-time
    final now = DateTime.now();
    final todayDayPillar = BaziUtils.getDayPillar(now.year, now.month, now.day);
    final hourPillar = BaziUtils.getHourPillar(
      selectedHour,
      todayDayPillar.stemIndex,
    );
    final hourElement = hourPillar.element;

    // Natal balance + 1 bonus for current hour element
    final total = balance.total + 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: kBaziElementOrder.map((element) {
          final natalCount = _getElementCount(balance, element);
          final hourBonus = element == hourElement ? 1 : 0;
          final count = natalCount + hourBonus;
          final pct = ((count / total) * 100).round();
          final color = kBaziElementColors[element] ?? Colors.white;
          final isDmElement = element == chart.dayMasterElement;
          final isHourElement = element == hourElement;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    kBaziElementEmoji[element] ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$pct%',
                    style: TextStyle(
                      color: color,
                      fontWeight: isDmElement
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 3,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDmElement ? 1.0 : 0.4),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: isDmElement
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.6),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  // Glowing dot = current hour element
                  if (isHourElement)
                    Positioned(
                      right: 0,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.85),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
