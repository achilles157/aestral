import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/glass_card.dart';
import 'city_search_sheet.dart';

class WaktuKosmisStepCard extends StatelessWidget {
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final VoidCallback onPresentDatePicker;
  final VoidCallback onPresentTimePicker;
  final VoidCallback onNextStep;

  const WaktuKosmisStepCard({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.onPresentDatePicker,
    required this.onPresentTimePicker,
    required this.onNextStep,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      key: const ValueKey('step_waktu_kosmis'),
      borderColor: AppTheme.accentPurple.withValues(alpha: 0.25),
      borderWidth: 1.2,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_outline, color: AppTheme.accentGold, size: 18),
              const SizedBox(width: 8),
              Text(
                'LANGKAH 1: WAKTU KOSMIS',
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
            'Tentukan tanggal dan jam penyejajaran jiwa Anda.',
            style: textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GlassButton(
            onPressed: onPresentDatePicker,
            glowColor: AppTheme.accentPurple,
            icon: const Icon(Icons.calendar_month, color: AppTheme.accentPurple),
            label: Text(
              selectedDate == null
                  ? 'Tentukan Tanggal Lahir'
                  : DateFormat('dd MMMM yyyy').format(selectedDate!),
            ),
          ),
          const SizedBox(height: 12),
          GlassButton(
            onPressed: onPresentTimePicker,
            glowColor: AppTheme.accentPurple,
            icon: const Icon(Icons.access_time, color: AppTheme.accentPurple),
            label: Text(
              selectedTime == null
                  ? 'Pilih Jam Lahir (Opsional)'
                  : 'Jam ${selectedTime!.format(context)}',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onNextStep,
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
                  'Lanjut ke Koordinat Bumi',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class KoordinatBumiStepCard extends StatelessWidget {
  final CityPreset selectedCity;
  final TextEditingController latController;
  final TextEditingController lngController;
  final VoidCallback onSelectCity;
  final VoidCallback onBackPressed;
  final VoidCallback onCalculate;

  const KoordinatBumiStepCard({
    super.key,
    required this.selectedCity,
    required this.latController,
    required this.lngController,
    required this.onSelectCity,
    required this.onBackPressed,
    required this.onCalculate,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      key: const ValueKey('step_koordinat_bumi'),
      borderColor: AppTheme.accentPurple.withValues(alpha: 0.25),
      borderWidth: 1.2,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.public, color: AppTheme.accentGold, size: 18),
              const SizedBox(width: 8),
              Text(
                'LANGKAH 2: KOORDINAT BUMI',
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
            'Pilih tempat penyatuan roh Anda dengan gaya gravitasi bumi.',
            style: textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: onSelectCity,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kota Kelahiran',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppTheme.accentGold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedCity.name,
                          style: const TextStyle(color: AppTheme.textLight, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: AppTheme.accentPurple),
                ],
              ),
            ),
          ),
          // Manual coordinates inputs if Custom Coordinate selected
          if (selectedCity.name == 'Koordinat Kustom') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: latController,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      prefixIcon: Icon(Icons.north, color: AppTheme.accentPurple, size: 20),
                    ),
                    style: const TextStyle(color: AppTheme.textLight),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: lngController,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      prefixIcon: Icon(Icons.east, color: AppTheme.accentPurple, size: 20),
                    ),
                    style: const TextStyle(color: AppTheme.textLight),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBackPressed,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.accentPurple, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_back, size: 16, color: AppTheme.accentPurple),
                      const SizedBox(width: 8),
                      Text(
                        'Kembali',
                        style: GoogleFonts.outfit(color: AppTheme.textLight),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onCalculate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Hitung Primbon Weton',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
