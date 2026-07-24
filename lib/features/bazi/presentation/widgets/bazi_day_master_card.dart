import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/bazi_chart.dart';
import 'bazi_pillar_column.dart';

/// Card that displays the Day Master (日主) profile.
/// Data sourced from assets/bazi/10day-masters.json.
class BaziDayMasterCard extends StatelessWidget {
  final BaziPillar dayPillar;

  /// Entry from 10day-masters.json matching [dayPillar.stemId]
  final Map<String, dynamic>? masterData;

  const BaziDayMasterCard({
    super.key,
    required this.dayPillar,
    required this.masterData,
  });

  @override
  Widget build(BuildContext context) {
    final Color elementColor =
        kBaziElementColors[dayPillar.element] ?? AppTheme.accentGold;
    final String arketipe =
        masterData?['arketipe_modern'] as String? ?? 'Day Master';
    final String metafora =
        masterData?['metafora_alam'] as String? ?? dayPillar.stemNameId;
    final String karakter = masterData?['karakter_dasar'] as String? ?? '';
    final String karier = masterData?['dinamika_karier'] as String? ?? '';
    final String asmara = masterData?['dinamika_asmara'] as String? ?? '';
    final List<String> industri =
        (masterData?['industri_cocok'] as List<dynamic>?)?.cast<String>() ?? [];
    final List<String> tags =
        (masterData?['tags_karakter'] as List<dynamic>?)?.cast<String>() ?? [];
    final String pesanKesadaran =
        masterData?['pesan_kesadaran'] as String? ?? '';

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: elementColor.withValues(alpha: 0.12),
                  border: Border.all(
                    color: elementColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Center(
                  child: Text(
                    dayPillar.stemSymbol,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 26,
                      color: elementColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: elementColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'DAY MASTER 日主',
                            style: GoogleFonts.outfit(
                              fontSize: 8,
                              color: elementColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      arketipe,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${dayPillar.stemNameId} — $metafora',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: elementColor.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (karakter.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              karakter,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.white70,
                height: 1.55,
              ),
            ),
          ],

          if (karier.isNotEmpty) ...[
            const SizedBox(height: 12),
            _sectionLabel('Dinamika Karier', elementColor),
            const SizedBox(height: 4),
            Text(
              karier,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: Colors.white60,
                height: 1.5,
              ),
            ),
          ],

          if (asmara.isNotEmpty) ...[
            const SizedBox(height: 12),
            _sectionLabel('Dinamika Asmara', elementColor),
            const SizedBox(height: 4),
            Text(
              asmara,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: Colors.white60,
                height: 1.5,
              ),
            ),
          ],

          if (industri.isNotEmpty) ...[
            const SizedBox(height: 12),
            _sectionLabel('Industri Cocok', elementColor),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: industri
                  .map((item) => _chip(item, elementColor, filled: true))
                  .toList(),
            ),
          ],

          if (tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags
                  .map((t) => _chip(t, elementColor.withValues(alpha: 0.6)))
                  .toList(),
            ),
          ],

          if (pesanKesadaran.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.accentGold.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('\u2726',
                      style: TextStyle(
                          color: AppTheme.accentGold, fontSize: 14)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PESAN KESADARAN',
                          style: GoogleFonts.outfit(
                            fontSize: 8,
                            color: AppTheme.accentGold.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pesanKesadaran,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.white70,
                            height: 1.55,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) => Text(
    text.toUpperCase(),
    style: GoogleFonts.outfit(
      fontSize: 9,
      color: color.withValues(alpha: 0.7),
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    ),
  );

  Widget _chip(String label, Color color, {bool filled = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: filled ? color.withValues(alpha: 0.15) : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 10,
        color: filled ? color : color.withValues(alpha: 0.8),
        fontWeight: filled ? FontWeight.w600 : FontWeight.w400,
      ),
    ),
  );
}
