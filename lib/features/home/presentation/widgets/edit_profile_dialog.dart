import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/birth_profile_provider.dart';
import '../../../../core/models/birth_profile.dart';
import '../../../../core/widgets/city_search_sheet.dart';

/// Dialog "Identitas Kosmis" — set tanggal lahir, jam, gender, dan kota.
/// Dipanggil dari DashboardIdentityCard dan DashboardScreen.
Future<void> showEditProfileDialog(
  BuildContext context,
  WidgetRef ref,
  List<CityPreset> allCities,
) async {
  final currentProfile =
      ref.read(birthProfileProvider).value ?? const BirthProfile();

  DateTime? selectedDate   = currentProfile.dobDate;
  int?      selectedHour   = currentProfile.birthHour;
  String?   selectedGender = currentProfile.gender;

  CityPreset selectedCity = allCities.firstWhere(
    (c) =>
        (c.latitude  - (currentProfile.latitude  ?? -6.2088)).abs() < 0.0001 &&
        (c.longitude - (currentProfile.longitude ?? 106.8456)).abs() < 0.0001,
    orElse: () => allCities.isNotEmpty
        ? allCities.firstWhere(
            (c) => c.name == 'Jakarta',
            orElse: () => allCities.first,
          )
        : const CityPreset(
            name: 'Jakarta', latitude: -6.2088, longitude: 106.8456),
  );

  await showDialog(
    context: context,
    barrierDismissible: currentProfile.dobDate != null,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.accentGold, width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.wb_sunny_outlined, color: AppTheme.accentGold),
            const SizedBox(width: 8),
            Text(
              'Identitas Kosmis',
              style: GoogleFonts.playfairDisplay(
                color: AppTheme.accentGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Sesuaikan data kelahiran Anda untuk menyelaraskan Weton, Ba Zi, dan Tarot.',
                style: TextStyle(color: AppTheme.textLight, height: 1.4),
              ),
              const SizedBox(height: 20),

              // ── Tanggal Lahir ───────────────────────────────────────────
              Text('Tanggal Lahir',
                  style: GoogleFonts.outfit(
                      color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.background,
                  foregroundColor: AppTheme.textLight,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: AppTheme.accentPurple.withValues(alpha: 0.3)),
                  ),
                ),
                icon: const Icon(Icons.calendar_month,
                    color: AppTheme.accentGold),
                label: Text(
                  selectedDate == null
                      ? 'Pilih Tanggal'
                      : '${selectedDate!.day} / ${selectedDate!.month} / ${selectedDate!.year}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime(2000),
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppTheme.accentPurple,
                          onPrimary: AppTheme.textLight,
                          surface: AppTheme.cardBg,
                          onSurface: AppTheme.textLight,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
              ),
              const SizedBox(height: 16),

              // ── Jam Lahir ───────────────────────────────────────────────
              Text('Jam Lahir',
                  style: GoogleFonts.outfit(
                      color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.accentPurple.withValues(alpha: 0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    dropdownColor: AppTheme.cardBg,
                    value: selectedHour,
                    hint: const Text('Pilih Jam Lahir (Opsional)',
                        style: TextStyle(color: AppTheme.textMuted)),
                    icon: const Icon(Icons.arrow_drop_down,
                        color: AppTheme.accentGold),
                    style: const TextStyle(
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.bold),
                    items: [
                      const DropdownMenuItem<int?>(
                          value: null, child: Text('Tidak Tahu')),
                      ...List.generate(24, (i) => DropdownMenuItem<int?>(
                            value: i,
                            child:
                                Text('${i.toString().padLeft(2, '0')}:00'),
                          )),
                    ],
                    onChanged: (val) =>
                        setDialogState(() => selectedHour = val),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Gender ──────────────────────────────────────────────────
              Text('Jenis Kelamin (Gender)',
                  style: GoogleFonts.outfit(
                      color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.accentPurple.withValues(alpha: 0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    dropdownColor: AppTheme.cardBg,
                    value: selectedGender,
                    hint: const Text('Pilih Jenis Kelamin (Opsional)',
                        style: TextStyle(color: AppTheme.textMuted)),
                    icon: const Icon(Icons.arrow_drop_down,
                        color: AppTheme.accentGold),
                    style: const TextStyle(
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.bold),
                    items: const [
                      DropdownMenuItem<String?>(
                          value: null, child: Text('Pilih...')),
                      DropdownMenuItem<String?>(
                          value: 'male', child: Text('Laki-laki')),
                      DropdownMenuItem<String?>(
                          value: 'female', child: Text('Perempuan')),
                    ],
                    onChanged: (val) =>
                        setDialogState(() => selectedGender = val),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Kota ────────────────────────────────────────────────────
              Text('Kota Tempat Lahir',
                  style: GoogleFonts.outfit(
                      color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.background,
                  foregroundColor: AppTheme.textLight,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: AppTheme.accentPurple.withValues(alpha: 0.3)),
                  ),
                ),
                icon: const Icon(Icons.location_on,
                    color: AppTheme.accentGold),
                label: Text(
                  selectedCity.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final picked =
                      await showModalBottomSheet<CityPreset>(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => CitySearchSheet(
                      cityPresets: allCities.isEmpty
                          ? [
                              const CityPreset(
                                name: 'Jakarta',
                                latitude: -6.2088,
                                longitude: 106.8456,
                              )
                            ]
                          : allCities,
                    ),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedCity = picked);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          if (currentProfile.dobDate != null)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal',
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
          TextButton(
            onPressed: selectedDate == null
                ? null
                : () async {
                    await ref
                        .read(birthProfileProvider.notifier)
                        .saveAll(
                          dob: selectedDate!,
                          birthHour: selectedHour,
                          latitude: selectedCity.latitude,
                          longitude: selectedCity.longitude,
                          cityName: selectedCity.name,
                          gender: selectedGender,
                        );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Identitas kosmis berhasil diselaraskan!'),
                          backgroundColor: AppTheme.accentPurple,
                        ),
                      );
                    }
                  },
            child: Text(
              'Simpan',
              style: TextStyle(
                color: selectedDate == null
                    ? AppTheme.textMuted
                    : AppTheme.accentGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
