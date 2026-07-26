import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';

/// Placeholder card saat Luck Pillars belum ditampilkan karena Jenis Kelamin belum diisi.
class BaziLuckPillarsPlaceholder extends StatelessWidget {
  final Color elementColor;
  final VoidCallback? onSelectGender;

  const BaziLuckPillarsPlaceholder({
    super.key,
    required this.elementColor,
    this.onSelectGender,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: elementColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: elementColor.withValues(alpha: 0.3)),
            ),
            child: Icon(
              Icons.timeline_rounded,
              color: elementColor.withValues(alpha: 0.8),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '大運  Luck Pillars (Siklus 10 Tahun)',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Pilih jenis kelamin di form input untuk menghitung arah siklus Da Yun (Maju / Mundur).',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.white60,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (onSelectGender != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onSelectGender,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Pilih',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: AppTheme.accentGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

