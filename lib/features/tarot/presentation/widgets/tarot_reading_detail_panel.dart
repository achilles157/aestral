import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/tarot_card.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';

class TarotReadingDetailPanel extends StatelessWidget {
  final TarotCard card;
  final bool isReversed;
  final String currentLang;
  final Color suitColor;
  final String elementLabel;

  const TarotReadingDetailPanel({
    super.key,
    required this.card,
    required this.isReversed,
    required this.currentLang,
    required this.suitColor,
    required this.elementLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      borderColor: suitColor.withValues(alpha: 0.35),
      borderWidth: 1.5,
      borderRadius: 24,
      color: AppTheme.cardBg.withValues(alpha: 0.7),
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome,
              color: AppTheme.accentGold,
              size: 24,
            ),
            const SizedBox(height: 12),
            Text(
              card.getName(currentLang),
              style: GoogleFonts.playfairDisplay(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              '${card.suit.toUpperCase()} • $elementLabel',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: suitColor,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Badges Row for Archetype & Astrology
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (card.getArchetype(currentLang).isNotEmpty)
                  _buildBadge(
                    context,
                    currentLang == 'id'
                        ? 'Arketipe: ${card.getArchetype(currentLang)}'
                        : 'Archetype: ${card.getArchetype(currentLang)}',
                    AppTheme.accentGold,
                  ),
                if (card.getElemental(currentLang).isNotEmpty)
                  _buildBadge(
                    context,
                    currentLang == 'id'
                        ? 'Asosiasi: ${card.getElemental(currentLang)}'
                        : 'Astro: ${card.getElemental(currentLang)}',
                    suitColor,
                  ),
              ],
            ),
            const Divider(color: Color(0xFF2E2452), height: 32, thickness: 1),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: card.getKeywords(currentLang).map((kw) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.background.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: suitColor.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    kw,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textLight.withValues(alpha: 0.95),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // Upright / Reversed Interpretation Label
            Text(
              isReversed
                  ? (currentLang == 'id'
                        ? 'Makna Terbalik ↺'
                        : 'Reversed Meaning ↺')
                  : (currentLang == 'id'
                        ? 'Makna Tegak ☼'
                        : 'Upright Meaning ☼'),
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isReversed ? AppTheme.accentPink : AppTheme.accentGold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isReversed
                  ? card.getReversedMeaning(currentLang)
                  : card.getUprightMeaning(currentLang),
              style: GoogleFonts.outfit(
                fontSize: 14.5,
                color: AppTheme.textLight.withValues(alpha: 0.95),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),

            // 1. Quick Reading / Fortune Pointers
            if (card.getFortuneTelling(currentLang).isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSectionTitle(
                context,
                currentLang == 'id' ? 'Ramalan Singkat' : 'Quick Reading',
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: card.getFortuneTelling(currentLang).map((line) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '✦ ',
                          style: TextStyle(color: AppTheme.accentGold),
                        ),
                        Expanded(
                          child: Text(
                            line,
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              color: AppTheme.textLight.withValues(alpha: 0.9),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],

            // 2. Reflection Box
            if (card.getQuestionsToAsk(currentLang).isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSectionTitle(
                context,
                currentLang == 'id' ? 'Pertanyaan Refleksi' : 'Self-Reflection',
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.background.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.accentPurple.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: card.getQuestionsToAsk(currentLang).map((q) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.help_outline,
                            color: AppTheme.accentPurple,
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              q,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: AppTheme.textLight.withValues(
                                  alpha: 0.9,
                                ),
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            // 3. Mythology Tab
            if (card.getMythical(currentLang).isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSectionTitle(
                context,
                currentLang == 'id'
                    ? 'Mitologi & Simbol'
                    : 'Spiritual & Mythology',
              ),
              const SizedBox(height: 12),
              Text(
                card.getMythical(currentLang),
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  color: AppTheme.textLight.withValues(alpha: 0.85),
                  height: 1.55,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: Color(0xFF2E2452), thickness: 0.8),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentGold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: Color(0xFF2E2452), thickness: 0.8),
        ),
      ],
    );
  }
}
