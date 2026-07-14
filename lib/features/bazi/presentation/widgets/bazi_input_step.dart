import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/city_search_sheet.dart';

/// Step 1 — jam lahir, kota kelahiran, jenis kelamin.
class BaziInputStep extends StatelessWidget {
  final int step;
  final bool includeHour;
  final int? birthHour;
  final CityPreset selectedCity;
  final List<CityPreset> allCities;
  final bool? isMale;
  final ValueChanged<bool> onToggleHour;
  final ValueChanged<int> onHourPicked;
  final ValueChanged<CityPreset> onCityPicked;
  final ValueChanged<bool?> onGenderChanged;
  final VoidCallback onNext;

  const BaziInputStep({
    super.key,
    required this.step,
    required this.includeHour,
    required this.birthHour,
    required this.selectedCity,
    required this.allCities,
    required this.isMale,
    required this.onToggleHour,
    required this.onHourPicked,
    required this.onCityPicked,
    required this.onGenderChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepIndicator(active: step),
          const SizedBox(height: 32),

          // ── Jam Lahir ─────────────────────────────────────────────────
          Text(
            'Jam Lahir (Opsional)',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Menambah Pilar Jam meningkatkan akurasi peta kosmis. Jika tidak tahu, lewati.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.white60,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Switch(
                  value: includeHour,
                  onChanged: onToggleHour,
                  activeThumbColor: AppTheme.accentPurple,
                ),
                const SizedBox(width: 8),
                Text(
                  includeHour
                      ? 'Sertakan jam lahir'
                      : 'Lewati — jam tidak diketahui',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          if (includeHour) ...[
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jam lahir (waktu lokal setempat)',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.white54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: AppTheme.accentPurple,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        birthHour == null
                            ? '--:--'
                            : '${birthHour.toString().padLeft(2, '0')}:00',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                              hour: birthHour ?? 12,
                              minute: 0,
                            ),
                            builder: (ctx, child) => Theme(
                              data: Theme.of(ctx).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppTheme.accentPurple,
                                  onPrimary: Colors.white,
                                  surface: AppTheme.cardBg,
                                  onSurface: Colors.white,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) onHourPicked(picked.hour);
                        },
                        child: Text(
                          'Pilih',
                          style: GoogleFonts.outfit(
                            color: AppTheme.accentPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          // ── Kota ──────────────────────────────────────────────────────
          Text(
            'Kota Kelahiran (Opsional)',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Digunakan untuk mengoreksi jam lahir ke True Solar Time (TST) agar akurasi pilar jam meningkat.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.white60,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final picked = await showModalBottomSheet<CityPreset>(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppTheme.cardBg,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => CitySearchSheet(cityPresets: allCities),
              );
              if (picked != null) onCityPicked(picked);
            },
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppTheme.accentGold,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedCity.name,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.search_rounded,
                    color: Colors.white38,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ── Gender ────────────────────────────────────────────────────
          Text(
            'Jenis Kelamin (Opsional)',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Diperlukan untuk menghitung siklus 10 tahun Luck Pillars (大運).',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.white60,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _GenderChip(
                label: 'Pria',
                isMaleChip: true,
                selected: isMale,
                onChanged: onGenderChanged,
              ),
              const SizedBox(width: 10),
              _GenderChip(
                label: 'Wanita',
                isMaleChip: false,
                selected: isMale,
                onChanged: onGenderChanged,
              ),
            ],
          ),

          const SizedBox(height: 40),
          _BaziPrimaryButton(label: 'Hitung Peta Ba Zi ✦', onTap: onNext),
        ],
      ),
    );
  }
}

// ── Private helpers ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int active;
  const _StepIndicator({required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final done = i < active;
        final current = i == active;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: done
                  ? AppTheme.accentGold
                  : current
                  ? AppTheme.accentPurple
                  : Colors.white12,
            ),
          ),
        );
      }),
    );
  }
}

class _BaziPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _BaziPrimaryButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    const btnColor = AppTheme.accentPurple;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: onTap != null
              ? btnColor.withValues(alpha: 0.85)
              : Colors.white12,
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: btnColor.withValues(alpha: 0.35),
                    blurRadius: 16,
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: onTap != null ? Colors.white : Colors.white30,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final bool isMaleChip;
  final bool? selected;
  final ValueChanged<bool?> onChanged;

  const _GenderChip({
    required this.label,
    required this.isMaleChip,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = selected == isMaleChip;
    final color = isMaleChip ? AppTheme.accentPurple : const Color(0xFFF472B6);
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(isMaleChip),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? color.withValues(alpha: 0.6) : Colors.white12,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isMaleChip ? Icons.male_rounded : Icons.female_rounded,
                color: isActive ? color : Colors.white38,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: isActive ? Colors.white : Colors.white38,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
