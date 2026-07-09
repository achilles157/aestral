import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/glass_card.dart';

/// Placeholder card saat Luck Pillars belum tersedia (gender belum diisi).
class BaziLuckPillarsPlaceholder extends StatelessWidget {
  final Color elementColor;

  const BaziLuckPillarsPlaceholder({super.key, required this.elementColor});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: elementColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: elementColor.withValues(alpha: 0.3)),
            ),
            child: Icon(
              Icons.timeline_rounded,
              color: elementColor.withValues(alpha: 0.7),
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '大運  Luck Pillars',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Siklus 10 tahun nasib segera hadir.',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Segera',
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: Colors.white38,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
