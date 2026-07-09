import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../components/weton_detail_card.dart';
import '../../services/weton_dictionary_service.dart';
import 'weton_ui_utils.dart';

/// 3 kartu insight (Karier, Asmara, Peringatan) + banner Saran Harian.
class WetonInsightSection extends StatelessWidget {
  final WetonDictionaryEntry entry;

  const WetonInsightSection({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final themeColor = parseWetonHexColor(entry.warnaHarmoni) ?? AppTheme.accentGold;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 3 Main Cards ───────────────────────────────────────────────────
        LayoutBuilder(
          builder: (context, constraints) {
            final useRow = constraints.maxWidth >= 380;
            final cards = [
              WetonDetailCard(
                title: 'Karier & Rezeki',
                content: entry.karirRezeki,
                icon: Icons.work_outline,
                accentColor: AppTheme.accentGold,
                margin: EdgeInsets.zero,
              ),
              WetonDetailCard(
                title: 'Asmara & Hubungan',
                content: entry.asmaraHubungan,
                icon: Icons.favorite_border,
                accentColor: AppTheme.accentPink,
                margin: EdgeInsets.zero,
              ),
              WetonDetailCard(
                title: 'Sisi Gelap & Peringatan',
                content: entry.sisiGelapPeringatan,
                icon: Icons.warning_amber_outlined,
                accentColor: const Color(0xFFF87171),
                margin: EdgeInsets.zero,
              ),
            ];
            if (useRow) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[1]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[2]),
                  ],
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                cards[0],
                const SizedBox(height: 12),
                cards[1],
                const SizedBox(height: 12),
                cards[2],
              ],
            );
          },
        ),
        // ── Saran Harian ───────────────────────────────────────────────────
        if (entry.saranHarian != null && entry.saranHarian!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: themeColor.withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: themeColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.saranHarian!,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      height: 1.4,
                      color: AppTheme.textLight.withValues(alpha: 0.9),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
