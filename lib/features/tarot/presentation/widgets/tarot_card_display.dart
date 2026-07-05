import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/tarot_language_provider.dart';
import '../../services/tarot_data.dart';

class CardBack extends StatelessWidget {
  final double width;
  final double height;

  const CardBack({
    super.key,
    this.width = 250,
    this.height = 400,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.accentGold,
          width: 3.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentGold.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Image.asset(
          'assets/images/tarot_card_back.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class CardFront extends ConsumerWidget {
  final DrawnCardInfo? drawnCard;
  final double width;
  final double height;

  const CardFront({
    super.key,
    required this.drawnCard,
    this.width = 250,
    this.height = 400,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final currentLang = ref.watch(tarotLanguageProvider);
    final card = drawnCard?.card;
    final isReversed = drawnCard?.isReversed ?? false;

    if (card == null) return CardBack(width: width, height: height);

    // Map tarot suit to elements & visual styles
    final suit = card.suit.toLowerCase();
    List<Color> gradientColors;
    IconData suitIcon;
    Color suitColor;
    String elementLabel;

    if (suit.contains('cup')) {
      // Cups = Water (Air/Water)
      gradientColors = [const Color(0xFF091E3A), const Color(0xFF1E3A8A)];
      suitIcon = Icons.water_drop_outlined;
      suitColor = const Color(0xFF60A5FA);
      elementLabel = currentLang == 'id' ? 'ELEMEN AIR' : 'WATER ELEMENT';
    } else if (suit.contains('wand')) {
      // Wands = Fire
      gradientColors = [const Color(0xFF450A0A), const Color(0xFF7F1D1D)];
      suitIcon = Icons.local_fire_department_outlined;
      suitColor = const Color(0xFFF87171);
      elementLabel = currentLang == 'id' ? 'ELEMEN API' : 'FIRE ELEMENT';
    } else if (suit.contains('pentacle')) {
      // Pentacles = Earth
      gradientColors = [const Color(0xFF064E3B), const Color(0xFF065F46)];
      suitIcon = Icons.monetization_on_outlined;
      suitColor = AppTheme.accentGold;
      elementLabel = currentLang == 'id' ? 'ELEMEN TANAH' : 'EARTH ELEMENT';
    } else if (suit.contains('sword')) {
      // Swords = Metal
      gradientColors = [const Color(0xFF374151), const Color(0xFF4B5563)];
      suitIcon = Icons.shield_outlined;
      suitColor = const Color(0xFFE5E7EB);
      elementLabel = currentLang == 'id' ? 'ELEMEN LOGAM' : 'METAL ELEMENT';
    } else {
      // Major Arcana = Spirit / Wood
      gradientColors = [const Color(0xFF1E1548), const Color(0xFF3B0764)];
      suitIcon = Icons.auto_awesome;
      suitColor = const Color(0xFFC084FC);
      elementLabel = currentLang == 'id' ? 'KOSMIS / SPIRIT' : 'COSMIC / SPIRIT';
    }

    final themeBorderColor = isReversed ? AppTheme.accentPink : AppTheme.accentGold;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.cardBg.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: themeBorderColor,
          width: 3.0,
        ),
        boxShadow: [
          BoxShadow(
            color: themeBorderColor.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Card title & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(suitIcon, color: suitColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      elementLabel,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: suitColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  currentLang == 'id' 
                      ? (isReversed ? 'TERBALIK ↺' : 'TEGAK ☼') 
                      : (isReversed ? 'REVERSED ↺' : 'UPRIGHT ☼'),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isReversed ? AppTheme.accentPink : AppTheme.accentGold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Full card illustration area
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: suitColor.withValues(alpha: 0.25),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: RotatedBox(
                    quarterTurns: isReversed ? 2 : 0,
                    child: Image.asset(
                      'assets/tarot/cards/${card.img}',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: gradientColors,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              suitIcon,
                              color: suitColor,
                              size: 40,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
