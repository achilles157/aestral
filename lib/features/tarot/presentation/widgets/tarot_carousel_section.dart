import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../services/tarot_data.dart';
import 'tarot_reading_detail_panel.dart';

/// Carousel kartu yang sudah di-flip — tab selector + PageView + dot indicator.
/// Tampil hanya ketika semua 3 kartu sudah terungkap.
class TarotCarouselSection extends StatelessWidget {
  final List<DrawnCardInfo> drawnCards;
  final int activeIndex;
  final String currentLang;
  final PageController pageController;
  final void Function(int index) onPageChanged;

  const TarotCarouselSection({
    super.key,
    required this.drawnCards,
    required this.activeIndex,
    required this.currentLang,
    required this.pageController,
    required this.onPageChanged,
  });

  static Color _suitColor(String suit) {
    final s = suit.toLowerCase();
    if (s.contains('cup'))      return AppTheme.elementWater;
    if (s.contains('wand'))     return AppTheme.elementFire;
    if (s.contains('pentacle')) return AppTheme.elementEarth;
    if (s.contains('sword'))    return AppTheme.elementMetal;
    return AppTheme.elementCosmic;
  }

  static String _elementLabel(String suit, String lang) {
    final s = suit.toLowerCase();
    if (s.contains('cup'))      return lang == 'id' ? 'ELEMEN AIR'   : 'WATER ELEMENT';
    if (s.contains('wand'))     return lang == 'id' ? 'ELEMEN API'   : 'FIRE ELEMENT';
    if (s.contains('pentacle')) return lang == 'id' ? 'ELEMEN TANAH' : 'EARTH ELEMENT';
    if (s.contains('sword'))    return lang == 'id' ? 'ELEMEN LOGAM' : 'METAL ELEMENT';
    return lang == 'id' ? 'KOSMIS / SPIRIT' : 'COSMIC / SPIRIT';
  }

  String _tabLabel(int index) {
    if (index == 0) return currentLang == 'id' ? 'Masa Lalu'  : 'Past';
    if (index == 1) return currentLang == 'id' ? 'Masa Kini'  : 'Present';
    return              currentLang == 'id' ? 'Masa Depan' : 'Future';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Tab row ──────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final isActive = activeIndex == index;
            return GestureDetector(
              onTap: () => pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.accentPurple : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? Colors.transparent : Colors.white24,
                  ),
                ),
                child: Text(
                  _tabLabel(index),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : Colors.white70,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),

        // ── PageView ─────────────────────────────────────────────────────
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: PageView.builder(
            controller: pageController,
            itemCount: 3,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final cardInfo = drawnCards[index];
              final suit     = cardInfo.card.suit;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TarotReadingDetailPanel(
                  card: cardInfo.card,
                  isReversed: cardInfo.isReversed,
                  currentLang: currentLang,
                  suitColor: _suitColor(suit),
                  elementLabel: _elementLabel(suit, currentLang),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // ── Dot indicators ───────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final isActive = i == activeIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: isActive
                    ? AppTheme.accentGold
                    : Colors.white.withValues(alpha: 0.25),
              ),
            );
          }),
        ),
      ],
    );
  }
}
