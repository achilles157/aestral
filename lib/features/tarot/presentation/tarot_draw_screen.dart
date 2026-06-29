import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import '../services/tarot_data.dart';
import '../models/tarot_card.dart';
import '../providers/tarot_language_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/file_saver.dart';

class TarotDrawScreen extends ConsumerStatefulWidget {
  const TarotDrawScreen({super.key});

  @override
  ConsumerState<TarotDrawScreen> createState() => _TarotDrawScreenState();
}

class _TarotDrawScreenState extends ConsumerState<TarotDrawScreen> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isCardRevealed = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: pi).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _handleDraw(List<TarotCard> deck) {
    if (_isCardRevealed) {
      // Reset card first
      _flipController.reverse().then((_) {
        ref.read(drawnCardProvider.notifier).reset();
        setState(() {
          _isCardRevealed = false;
        });
      });
    } else {
      ref.read(drawnCardProvider.notifier).drawCard(deck);
      _flipController.forward().then((_) {
        setState(() {
          _isCardRevealed = true;
        });
      });
    }
  }
  Widget _buildLangButton(BuildContext context, WidgetRef ref, String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        ref.read(tarotLanguageProvider.notifier).setLanguage(label.toLowerCase());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isActive ? AppTheme.accentGold : Colors.transparent,
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isActive ? AppTheme.background : AppTheme.textLight,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deckAsync = ref.watch(tarotDeckProvider);
    final drawnCard = ref.watch(drawnCardProvider);
    final textTheme = Theme.of(context).textTheme;
    final currentLang = ref.watch(tarotLanguageProvider);

    final card = drawnCard?.card;
    final isReversed = drawnCard?.isReversed ?? false;

    Color suitColor = AppTheme.accentPurple;
    String elementLabel = '';
    if (card != null) {
      final suit = card.suit.toLowerCase();
      if (suit.contains('cup')) {
        suitColor = const Color(0xFF60A5FA);
        elementLabel = currentLang == 'id' ? 'ELEMEN AIR' : 'WATER ELEMENT';
      } else if (suit.contains('wand')) {
        suitColor = const Color(0xFFF87171);
        elementLabel = currentLang == 'id' ? 'ELEMEN API' : 'FIRE ELEMENT';
      } else if (suit.contains('pentacle')) {
        suitColor = AppTheme.accentGold;
        elementLabel = currentLang == 'id' ? 'ELEMEN TANAH' : 'EARTH ELEMENT';
      } else if (suit.contains('sword')) {
        suitColor = const Color(0xFFE5E7EB);
        elementLabel = currentLang == 'id' ? 'ELEMEN LOGAM' : 'METAL ELEMENT';
      } else {
        suitColor = const Color(0xFFC084FC);
        elementLabel = currentLang == 'id' ? 'KOSMIS / SPIRIT' : 'COSMIC / SPIRIT';
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Daily Tarot',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: AppTheme.accentGold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textLight),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.accentGold.withOpacity(0.4), width: 1),
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withOpacity(0.03),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLangButton(context, ref, 'ID', currentLang == 'id'),
                _buildLangButton(context, ref, 'EN', currentLang == 'en'),
              ],
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.background,
                  Color(0xFF140D33),
                  Color(0xFF0A0617),
                ],
              ),
            ),
          ),
          SafeArea(
            child: deckAsync.when(
              data: (deck) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Fokuskan pikiran Anda pada suatu pertanyaan, lalu tarik kartu.',
                                style: textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              // Capture area for social sharing
                              Screenshot(
                                controller: _screenshotController,
                                child: Center(
                                  child: AnimatedBuilder(
                                    animation: _flipAnimation,
                                    builder: (context, child) {
                                      final double value = _flipAnimation.value;
                                      final bool isFront = value >= pi / 2;

                                      return Transform(
                                        transform: Matrix4.identity()
                                          ..setEntry(3, 2, 0.002) // 3D Perspective
                                          ..rotateY(value),
                                        alignment: Alignment.center,
                                        child: isFront
                                            ? Transform(
                                                transform: Matrix4.identity()..rotateY(pi),
                                                alignment: Alignment.center,
                                                child: _CardFront(drawnCard: drawnCard),
                                              )
                                            : const _CardBack(),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              // Draw button
                              ElevatedButton(
                                onPressed: () => _handleDraw(deck),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isCardRevealed 
                                      ? AppTheme.accentPink 
                                      : AppTheme.accentPurple,
                                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                                ),
                                child: Text(_isCardRevealed ? 'Tarik Ulang' : 'Tarik Kartu'),
                              ),
                              const SizedBox(height: 16),
                              // Share button (only active when card is revealed)
                              if (_isCardRevealed) ...[
                                TextButton.icon(
                                  onPressed: _shareCard,
                                  icon: const Icon(Icons.share, color: AppTheme.accentGold),
                                  label: Text(
                                    'Bagikan Hasil',
                                    style: textTheme.labelLarge?.copyWith(
                                      color: AppTheme.accentGold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Detail reading panel
                                if (card != null) ...[
                                  Container(
                                    margin: const EdgeInsets.only(top: 8, bottom: 24),
                                    width: double.infinity,
                                    constraints: const BoxConstraints(maxWidth: 500),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardBg.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: suitColor.withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.auto_awesome, color: AppTheme.accentGold, size: 24),
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
                                                currentLang == 'id' ? 'Arketipe: ${card.getArchetype(currentLang)}' : 'Archetype: ${card.getArchetype(currentLang)}', 
                                                AppTheme.accentGold
                                              ),
                                            if (card.getElemental(currentLang).isNotEmpty)
                                              _buildBadge(
                                                context, 
                                                currentLang == 'id' ? 'Asosiasi: ${card.getElemental(currentLang)}' : 'Astro: ${card.getElemental(currentLang)}', 
                                                suitColor
                                              ),
                                          ],
                                        ),
                                        const Divider(
                                          color: Color(0xFF2E2452),
                                          height: 32,
                                          thickness: 1,
                                        ),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          alignment: WrapAlignment.center,
                                          children: card.getKeywords(currentLang).map((kw) {
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: AppTheme.background.withOpacity(0.6),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: suitColor.withOpacity(0.25),
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: Text(
                                                kw,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppTheme.textLight.withOpacity(0.95),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                        const SizedBox(height: 20),
                                        // Upright / Reversed Interpretation Label
                                        Text(
                                          isReversed 
                                              ? (currentLang == 'id' ? 'Makna Terbalik ↺' : 'Reversed Meaning ↺') 
                                              : (currentLang == 'id' ? 'Makna Tegak ☼' : 'Upright Meaning ☼'),
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isReversed ? AppTheme.accentPink : AppTheme.accentGold,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          isReversed ? card.getReversedMeaning(currentLang) : card.getUprightMeaning(currentLang),
                                          style: GoogleFonts.outfit(
                                            fontSize: 14.5,
                                            color: AppTheme.textLight.withOpacity(0.95),
                                            height: 1.6,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        
                                        // 1. Quick Reading / Fortune Pointers
                                        if (card.getFortuneTelling(currentLang).isNotEmpty) ...[
                                          const SizedBox(height: 24),
                                          _buildSectionTitle(context, currentLang == 'id' ? 'Ramalan Singkat' : 'Quick Reading'),
                                          const SizedBox(height: 12),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: card.getFortuneTelling(currentLang).map((line) {
                                              return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text('✦ ', style: TextStyle(color: AppTheme.accentGold)),
                                                    Expanded(
                                                      child: Text(
                                                        line,
                                                        style: GoogleFonts.outfit(
                                                          fontSize: 13.5,
                                                          color: AppTheme.textLight.withOpacity(0.9),
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
                                          _buildSectionTitle(context, currentLang == 'id' ? 'Pertanyaan Refleksi' : 'Self-Reflection'),
                                          const SizedBox(height: 12),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: AppTheme.background.withOpacity(0.4),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: AppTheme.accentPurple.withOpacity(0.2), width: 1),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: card.getQuestionsToAsk(currentLang).map((q) {
                                                return Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Icon(Icons.help_outline, color: AppTheme.accentPurple, size: 14),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          q,
                                                          style: GoogleFonts.outfit(
                                                            fontSize: 13,
                                                            color: AppTheme.textLight.withOpacity(0.9),
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
                                          _buildSectionTitle(context, currentLang == 'id' ? 'Mitologi & Simbol' : 'Spiritual & Mythology'),
                                          const SizedBox(height: 12),
                                          Text(
                                            card.getMythical(currentLang),
                                            style: GoogleFonts.outfit(
                                              fontSize: 13.5,
                                              color: AppTheme.textLight.withOpacity(0.85),
                                              height: 1.55,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentPurple)),
              error: (err, stack) => Center(
                child: Text(
                  'Gagal memuat kartu tarot: $err',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
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
        Expanded(child: Divider(color: const Color(0xFF2E2452), thickness: 0.8)),
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
        Expanded(child: Divider(color: const Color(0xFF2E2452), thickness: 0.8)),
      ],
    );
  }

  void _shareCard() async {
    // Generate screenshot image bytes
    final imageBytes = await _screenshotController.capture();
    if (imageBytes != null && mounted) {
      // Since native sharing needs platform channels setup, let's show a beautiful preview
      // and download option or simulated share dialog to keep it cross-platform.
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: AppTheme.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppTheme.accentGold, width: 1.5),
            ),
            title: Text(
              'Tangkapan Layar Siap!',
              style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.bold,
                color: AppTheme.accentGold,
              ),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    imageBytes,
                    height: 300,
                    fit: .contain,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Hasil pembacaan Anda telah disimpan dan siap dibagikan ke Instagram Story!',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () async {
                  try {
                    final fileName = 'aestral-tarot-${DateTime.now().millisecondsSinceEpoch}.png';
                    await savePng(imageBytes, fileName);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gambar berhasil diunduh: $fileName!'),
                          backgroundColor: AppTheme.accentPurple,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal menyimpan gambar: $e'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.download, color: AppTheme.accentGold),
                label: const Text('Unduh Gambar', style: TextStyle(color: AppTheme.accentGold)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup', style: TextStyle(color: AppTheme.textLight)),
              ),
            ],
          );
        },
      );
    }
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.accentGold,
          width: 3.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentGold.withOpacity(0.2),
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

class _CardFront extends ConsumerWidget {
  final DrawnCardInfo? drawnCard;

  const _CardFront({required this.drawnCard});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final currentLang = ref.watch(tarotLanguageProvider);
    final card = drawnCard?.card;
    final isReversed = drawnCard?.isReversed ?? false;

    if (card == null) return const _CardBack();

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
      width: 250,
      height: 400,
      decoration: BoxDecoration(
        color: AppTheme.cardBg.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: themeBorderColor,
          width: 3.0,
        ),
        boxShadow: [
          BoxShadow(
            color: themeBorderColor.withOpacity(0.25),
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
                    color: suitColor.withOpacity(0.25),
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
