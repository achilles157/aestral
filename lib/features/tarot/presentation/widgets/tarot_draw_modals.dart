import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/file_saver.dart';
import '../../../../core/utils/weton_utils.dart';
import '../../../auth/services/profile_service.dart';

Future<DateTime?> showOnboardingBirthdayModal(BuildContext context, WidgetRef ref) async {
  DateTime? tempDate;
  return showDialog<DateTime>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: AppTheme.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: AppTheme.accentGold, width: 1.5),
            ),
            title: Column(
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.accentGold, size: 36),
                const SizedBox(height: 12),
                Text(
                  'Pintu Gerbang Takdir',
                  style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGold,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sebelum dapat menarik kartu tarot dan melihat weton harianmu, selaraskan energi kosmikmu dengan memasukkan tanggal lahir.',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppTheme.textLight.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime(2000, 1, 1),
                      firstDate: DateTime(1900),
                      lastDate: now,
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppTheme.accentPurple,
                              onPrimary: AppTheme.textLight,
                              surface: AppTheme.cardBg,
                              onSurface: AppTheme.textLight,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setModalState(() {
                        tempDate = picked;
                      });
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.accentPurple, width: 1.2),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  icon: const Icon(Icons.cake, color: AppTheme.accentPurple),
                  label: Text(
                    tempDate == null
                        ? 'Pilih Tanggal Lahir'
                        : DateFormat('dd MMMM yyyy').format(tempDate!),
                    style: const TextStyle(color: AppTheme.textLight),
                  ),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text(
                  'Batal',
                  style: TextStyle(color: AppTheme.textLight.withValues(alpha: 0.6)),
                ),
              ),
              ElevatedButton(
                onPressed: tempDate == null
                    ? null
                    : () async {
                        final dob = tempDate!;
                        final weton = WetonUtils.calculateWeton(dob);
                        final success = await ref.read(profileProvider).saveProfile(
                          dob: dob,
                          latitude: 0.0,
                          longitude: 0.0,
                          weton: weton,
                        );
                        if (context.mounted) {
                          if (success) {
                            Navigator.pop(context, dob);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Gagal menyimpan profil, coba lagi.'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  foregroundColor: AppTheme.background,
                ),
                child: const Text('Selaraskan Energi'),
              ),
            ],
          );
        },
      );
    },
  );
}

void shareCardResult({
  required BuildContext context,
  required ScreenshotController screenshotController,
}) async {
  final imageBytes = await screenshotController.capture();
  if (imageBytes != null && context.mounted) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.accentGold, width: 1.5),
          ),
          title: Text(
            'Tangkapan Layar Siap!',
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold,
              color: AppTheme.accentGold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  imageBytes,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Hasil pembacaan Anda telah disimpan dan siap dibagikan ke Instagram Story!',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                try {
                  final fileName = 'aestral-tarot-${DateTime.now().millisecondsSinceEpoch}.png';
                  await savePng(imageBytes, fileName);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gambar berhasil diunduh: $fileName!'),
                        backgroundColor: AppTheme.accentPurple,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menyimpan gambar: $e'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.download, color: AppTheme.accentGold),
              label: const Text('Unduh Gambar', style: TextStyle(color: AppTheme.accentGold)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup', style: TextStyle(color: AppTheme.textLight)),
            ),
          ],
        );
      },
    );
  }
}
