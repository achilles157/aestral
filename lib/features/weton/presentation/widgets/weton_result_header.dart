import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'weton_ui_utils.dart';

/// Header hasil kalkulasi: label "WETON LAHIR", nama weton besar,
/// titik warna harmoni, dan kutipan headline.
class WetonResultHeader extends StatelessWidget {
  final String wetonName;
  final String? warnaHarmoni;
  final String? headline;

  const WetonResultHeader({
    super.key,
    required this.wetonName,
    this.warnaHarmoni,
    this.headline,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final harmoniColor = parseWetonHexColor(warnaHarmoni);

    return Center(
      child: Column(
        children: [
          Text(
            'WETON LAHIR',
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: AppTheme.accentGold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                wetonName,
                style: textTheme.displayLarge?.copyWith(color: AppTheme.textLight),
              ),
              if (harmoniColor != null) ...[
                const SizedBox(width: 12),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: harmoniColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: harmoniColor.withValues(alpha: 0.8),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (headline != null && headline!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '"$headline"',
              style: textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
                color: AppTheme.accentGold.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
