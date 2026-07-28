import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../auth/services/auth_service.dart';

/// Banner upsell untuk user tamu — ajak login dengan Google.
class DashboardGuestUpsellCard extends ConsumerWidget {
  const DashboardGuestUpsellCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentPurple.withValues(alpha: 0.12),
            AppTheme.accentGold.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.accentPurple.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_open_rounded,
            color: AppTheme.accentPurple,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profil kosmismu sudah siap — simpan agar tidak hilang',
                  style: GoogleFonts.outfit(
                    color: AppTheme.textLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Profil ini hilang saat sesi berakhir. Simpan sekarang, bawa ke semua perangkatmu.',
                  style: GoogleFonts.outfit(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              AnalyticsService.logGuestUpsellShown(
                'dashboard',
              ).catchError((_) {});
              ref.read(authProvider.notifier).signInWithGoogle();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.accentPurple,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Simpan',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
