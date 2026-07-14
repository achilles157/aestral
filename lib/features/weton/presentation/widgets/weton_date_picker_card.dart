import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';

/// Kartu pemilih tanggal lahir untuk WetonCalculatorScreen.
class WetonDatePickerCard extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onPickDate;
  final VoidCallback onCalculate;

  const WetonDatePickerCard({
    super.key,
    required this.selectedDate,
    required this.onPickDate,
    required this.onCalculate,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      borderColor: AppTheme.accentPurple.withValues(alpha: 0.25),
      borderWidth: 1.2,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star_outline,
                color: AppTheme.accentGold,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'TANGGAL LAHIR KOSMIS',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppTheme.accentGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pilih tanggal lahir untuk menyelaraskan energi Weton Anda.',
            style: textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onPickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.accentPurple.withValues(alpha: 0.35),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month,
                    color: AppTheme.accentGold,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedDate == null
                          ? 'Tentukan Tanggal Lahir...'
                          : DateFormat('dd MMMM yyyy').format(selectedDate!),
                      style: GoogleFonts.outfit(
                        color: selectedDate == null
                            ? Colors.white38
                            : AppTheme.textLight,
                        fontSize: 15,
                        fontWeight: selectedDate == null
                            ? FontWeight.w400
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.edit,
                    color: AppTheme.accentPurple,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onCalculate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPurple,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Hitung Primbon Weton',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.auto_awesome, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
