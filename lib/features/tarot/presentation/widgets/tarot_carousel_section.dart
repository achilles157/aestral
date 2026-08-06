import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../services/tarot_data.dart';
import 'tarot_reading_detail_panel.dart';

/// Carousel kartu yang sudah di-flip — tab selector + PageView + dot indicator.
/// Tampil ketika semua kartu sudah terungkap. Mendukung N kartu
/// (2 untuk Mangsa energy/guidance, 3 untuk Lahir/Tematik).
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
    if (s.contains('cup')) return AppTheme.elementWater;
    if (s.contains('wand')) return AppTheme.elementFire;
    if (s.contains('pentacle')) return AppTheme.elementEarth;
    if (s.contains('sword')) return AppTheme.elementMetal;
    return AppTheme.elementCosmic;
  }

  static String _elementLabel(String suit, String lang) {
    final s = suit.toLowerCase();
    if (s.contains('cup')) return lang == 'id' ? 'ELEMEN AIR' : 'WATER ELEMENT';
    if (s.contains('wand')) return lang == 'id' ? 'ELEMEN API' : 'FIRE ELEMENT';
    if (s.contains('pentacle'))
      return lang == 'id' ? 'ELEMEN TANAH' : 'EARTH ELEMENT';
    if (s.contains('sword'))
      return lang == 'id' ? 'ELEMEN LOGAM' : 'METAL ELEMENT';
    return lang == 'id' ? 'KOSMIS / SPIRIT' : 'COSMIC / SPIRIT';
  }

  /// Label tab dari label backend kartu — support mangsa (energy/guidance),
  /// lahir (past/present/future), dan tematik (potensi, tantangan, dll).
  String _tabLabel(String backendLabel) {
    switch (backendLabel) {
      case 'energy':
        return currentLang == 'id' ? 'Energi Mangsa' : 'Mangsa Energy';
      case 'guidance':
        return currentLang == 'id' ? 'Panduan Pribadi' : 'Personal Guidance';
      case 'past':
        return currentLang == 'id' ? 'Masa Lalu' : 'Past';
      case 'present':
        return currentLang == 'id' ? 'Masa Kini' : 'Present';
      case 'future':
        return currentLang == 'id' ? 'Masa Depan' : 'Future';
      case 'potensi':
        return currentLang == 'id' ? 'Potensi' : 'Potential';
      case 'tantangan':
        return currentLang == 'id' ? 'Tantangan' : 'Challenge';
      case 'arah':
        return currentLang == 'id' ? 'Arah' : 'Direction';
      case 'daya_tarik':
        return currentLang == 'id' ? 'Daya Tarik' : 'Attraction';
      case 'bayangan':
        return currentLang == 'id' ? 'Bayangan' : 'Shadow';
      case 'langkah':
        return currentLang == 'id' ? 'Langkah' : 'Next Step';
      case 'sumber':
        return currentLang == 'id' ? 'Sumber' : 'Source';
      case 'kebocoran':
        return currentLang == 'id' ? 'Kebocoran' : 'Leak';
      case 'strategi':
        return currentLang == 'id' ? 'Strategi' : 'Strategy';
      case 'panggilan':
        return currentLang == 'id' ? 'Panggilan' : 'Calling';
      case 'rintangan':
        return currentLang == 'id' ? 'Rintangan' : 'Obstacle';
      case 'pesan':
        return currentLang == 'id' ? 'Pesan' : 'Message';
      case 'vitalitas':
        return currentLang == 'id' ? 'Vitalitas' : 'Vitality';
      case 'kelemahan':
        return currentLang == 'id' ? 'Kelemahan' : 'Weakness';
      case 'ritme':
        return currentLang == 'id' ? 'Ritme' : 'Rhythm';
      default:
        return backendLabel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardCount = drawnCards.length;
    return Column(
      children: [
        // ── Tab row ──────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(cardCount, (index) {
            final isActive = activeIndex == index;
            return GestureDetector(
              onTap: () => pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.accentPurple : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? Colors.transparent : Colors.white24,
                  ),
                ),
                child: Text(
                  _tabLabel(drawnCards[index].label),
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
            itemCount: cardCount,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final cardInfo = drawnCards[index];
              final suit = cardInfo.card.suit;
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
          children: List.generate(cardCount, (i) {
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
