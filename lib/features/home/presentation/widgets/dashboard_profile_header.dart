import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/services/auth_service.dart';

/// Avatar + nama + email + status badge (Akun Aktif / Mode Tamu).
class DashboardProfileHeader extends StatelessWidget {
  final UserSession? session;

  const DashboardProfileHeader({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final name = session?.displayName ?? 'Penjelajah';
    final email = session?.email ?? '';
    final isGuest = session == null || session!.isMock;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.accentGold, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentGold.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
            color: AppTheme.cardBg,
          ),
          child: session?.photoUrl != null
              ? ClipOval(
                  child: Image.network(
                    session!.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarInitial(initial),
                  ),
                )
              : _avatarInitial(initial),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.playfairDisplay(
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  email,
                  style: GoogleFonts.outfit(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isGuest
                      ? AppTheme.textMuted.withValues(alpha: 0.15)
                      : AppTheme.accentPurple.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isGuest
                        ? AppTheme.textMuted.withValues(alpha: 0.3)
                        : AppTheme.accentPurple.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  isGuest ? 'Mode Tamu' : 'Akun Aktif',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isGuest ? AppTheme.textMuted : AppTheme.accentPurple,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatarInitial(String initial) => Center(
    child: Text(
      initial,
      style: GoogleFonts.playfairDisplay(
        color: AppTheme.accentGold,
        fontSize: 26,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
