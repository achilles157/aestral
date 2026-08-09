import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/shell_providers.dart';
import '../../../../features/legal/presentation/legal_screen.dart';
import '../../../auth/services/auth_service.dart';

/// Footer — tombol logout (jika login) + versi app.
class DashboardFooter extends ConsumerWidget {
  final UserSession? session;

  const DashboardFooter({super.key, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceEffects = ref.watch(reduceEffectsProvider).value ?? false;

    return Column(
      children: [
        if (session != null && !session!.isMock)
          TextButton.icon(
            onPressed: () => ref.read(authProvider.notifier).signOut(),
            icon: const Icon(Icons.logout, size: 16, color: Colors.redAccent),
            label: const Text(
              'Keluar',
              style: TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Kurangi Efek Visual',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: AppTheme.textMuted.withValues(alpha: 0.5),
              ),
            ),
            Transform.scale(
              scale: 0.70,
              child: Switch(
                value: reduceEffects,
                onChanged: (_) =>
                    ref.read(reduceEffectsProvider.notifier).toggle(),
                activeThumbColor: AppTheme.accentGold,
                inactiveTrackColor: Colors.white10,
              ),
            ),
          ],
        ),
        Text(
          'Aestral • Zero-Budget High-Performance',
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: AppTheme.textMuted.withValues(alpha: 0.5),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        // Link dokumen legal — dibuka sebagai layar penuh.
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const LegalScreen(type: LegalDocumentType.privacyPolicy),
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Kebijakan Privasi',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: AppTheme.textMuted.withValues(alpha: 0.7),
                  decoration: TextDecoration.underline,
                  decorationColor: AppTheme.textMuted.withValues(alpha: 0.4),
                ),
              ),
            ),
            Text(
              '•',
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: AppTheme.textMuted.withValues(alpha: 0.4),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const LegalScreen(type: LegalDocumentType.termsOfService),
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Syarat Layanan',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: AppTheme.textMuted.withValues(alpha: 0.7),
                  decoration: TextDecoration.underline,
                  decorationColor: AppTheme.textMuted.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
