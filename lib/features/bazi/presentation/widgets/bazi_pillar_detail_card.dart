import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/glass_card.dart';

/// Card "日柱" — karakter summary, career tendency, dan tag dari bazi-pillars.json.
class BaziPillarDetailCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color elementColor;

  const BaziPillarDetailCard({
    super.key,
    required this.data,
    required this.elementColor,
  });

  @override
  Widget build(BuildContext context) {
    final String summary = data['character_summary'] as String? ?? '';
    final List<String> career =
        (data['career_tendency'] as List<dynamic>?)?.cast<String>() ?? [];
    final List<String> tags =
        (data['tags'] as List<dynamic>?)?.cast<String>() ?? [];

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '日柱 ',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  color: elementColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                data['pillar_name'] as String? ?? '',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (summary.isNotEmpty)
            Text(
              summary,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.white60,
                height: 1.5,
              ),
            ),
          if (career.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: career.map((c) => _chip(c, elementColor)).toList(),
            ),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags.map((t) => _chip(t, Colors.white38)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 10,
        color: color,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
