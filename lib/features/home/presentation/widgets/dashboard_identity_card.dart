import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/weton_utils.dart';
import '../../../../core/providers/birth_profile_provider.dart';
import '../../../../core/models/birth_profile.dart';

/// Card "Identitas Kosmis" — tampilkan tanggal lahir, weton, wuku, pranata mangsa.
class DashboardIdentityCard extends ConsumerWidget {
  /// Dipanggil saat user tap tombol edit atau "Isi Identitas Kosmis".
  final VoidCallback onEditTap;

  const DashboardIdentityCard({super.key, required this.onEditTap});

  String get _pranataMangsaName {
    final id = WetonUtils.calculatePranataMangsaId(DateTime.now());
    const names = [
      'Kasa',
      'Karo',
      'Katiga',
      'Kapat',
      'Kalima',
      'Kanem',
      'Kapitu',
      'Kawolu',
      'Kasanga',
      'Kadasa',
      'Desta',
      'Saddha',
    ];
    if (id < 1 || id > 12) return 'Pergantian Mangsa';
    return names[id - 1];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(birthProfileProvider);
    final profile = profileAsync.value ?? const BirthProfile();
    final dob = profile.dobDate;
    final weton = profile.weton;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.30),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentGold.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row ────────────────────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: AppTheme.accentGold,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Identitas Kosmis',
                style: GoogleFonts.playfairDisplay(
                  color: AppTheme.accentGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              if (dob != null)
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: AppTheme.accentGold,
                    size: 16,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onEditTap,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Content ───────────────────────────────────────────────────────
          if (!profileAsync.hasValue && profileAsync.isLoading)
            const Center(
              child: SizedBox(
                height: 32,
                width: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.accentGold,
                ),
              ),
            )
          else if (dob == null)
            _NoIdentityPrompt(onTap: onEditTap)
          else ...[
            _IdentityRow(
              Icons.cake_outlined,
              'Tanggal Lahir',
              '${dob.day} / ${dob.month} / ${dob.year}',
            ),
            const SizedBox(height: 12),
            _IdentityRow(
              Icons.brightness_medium_rounded,
              'Weton',
              weton != null ? '${weton.saptawara} ${weton.pancawara}' : '—',
              badge: weton != null ? 'Neptu ${weton.totalNeptu}' : null,
            ),
            const SizedBox(height: 12),
            _IdentityRow(
              Icons.rotate_right_rounded,
              'Wuku',
              weton?.wuku ?? '—',
            ),
            const SizedBox(height: 12),
            _IdentityRow(
              Icons.eco_outlined,
              'Pranata Mangsa',
              _pranataMangsaName,
              subtitle: 'Musim saat ini',
            ),
            if (profile.cityName != null && profile.cityName!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _IdentityRow(
                Icons.location_on_outlined,
                'Tempat Lahir',
                profile.cityName!,
              ),
            ],
            if (profile.birthHour != null) ...[
              const SizedBox(height: 12),
              _IdentityRow(
                Icons.access_time_outlined,
                'Jam Lahir',
                '${profile.birthHour!.toString().padLeft(2, '0')}:00 WIB',
              ),
            ],
            if (profile.gender != null) ...[
              const SizedBox(height: 12),
              _IdentityRow(
                Icons.person_outline,
                'Jenis Kelamin',
                profile.gender == 'male' ? 'Laki-laki' : 'Perempuan',
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ─── Helper widgets ──────────────────────────────────────────────────────────

class _NoIdentityPrompt extends StatelessWidget {
  final VoidCallback onTap;
  const _NoIdentityPrompt({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_outline_rounded,
              color: AppTheme.accentGold.withValues(alpha: 0.35),
              size: 13,
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.auto_awesome,
              color: AppTheme.accentGold.withValues(alpha: 0.65),
              size: 18,
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.star_outline_rounded,
              color: AppTheme.accentGold.withValues(alpha: 0.35),
              size: 13,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Identitas Kosmis Belum Terisi',
          style: GoogleFonts.playfairDisplay(
            color: AppTheme.textLight,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Masukkan tanggal lahir untuk membuka\nweton, Ba Zi, dan wawasan kosmis Anda.',
          style: GoogleFonts.outfit(
            color: AppTheme.textMuted,
            fontSize: 12,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.add_circle_outline, size: 16),
            label: const Text('Isi Identitas Kosmis'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGold.withValues(alpha: 0.15),
              foregroundColor: AppTheme.accentGold,
              side: const BorderSide(color: AppTheme.accentGold, width: 1),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _IdentityRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? badge;
  final String? subtitle;

  const _IdentityRow(
    this.icon,
    this.label,
    this.value, {
    this.badge,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.accentGold.withValues(alpha: 0.7), size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 1),
              Row(
                children: [
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      color: AppTheme.textLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.accentGold.withValues(alpha: 0.40),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        badge!,
                        style: GoogleFonts.outfit(
                          color: AppTheme.accentGold,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: GoogleFonts.outfit(
                    color: AppTheme.textMuted.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
