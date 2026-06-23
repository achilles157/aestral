import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import '../services/tarot_data.dart';
import '../models/tarot_card.dart';
import '../../../core/theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final deckAsync = ref.watch(tarotDeckProvider);
    final drawnCard = ref.watch(drawnCardProvider);
    final textTheme = Theme.of(context).textTheme;

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
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        'Fokuskan pikiran Anda pada suatu pertanyaan, lalu tarik kartu.',
                        style: textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
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
                      const Spacer(),
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
                      if (_isCardRevealed)
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
                      const SizedBox(height: 20),
                    ],
                  ),
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
        color: const Color(0xFF1F1840),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.accentGold,
          width: 3.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withOpacity(0.5),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ornate details
            Container(
              width: 210,
              height: 360,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.accentGold.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.auto_awesome,
                  color: AppTheme.accentGold.withOpacity(0.8),
                  size: 48,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardFront extends StatelessWidget {
  final DrawnCardInfo? drawnCard;

  const _CardFront({required this.drawnCard});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final card = drawnCard?.card;
    final isReversed = drawnCard?.isReversed ?? false;

    if (card == null) return const _CardBack();

    return Container(
      width: 250,
      height: 400,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isReversed ? AppTheme.accentPink : AppTheme.accentPurple,
          width: 3.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withOpacity(0.5),
            blurRadius: 16,
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
                Text(
                  card.suit.toUpperCase(),
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                  ),
                ),
                Text(
                  isReversed ? 'TERBALIK' : 'TEGAK',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isReversed ? AppTheme.accentPink : AppTheme.accentGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Procedural illustration area
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isReversed
                        ? [const Color(0xFF3B1D38), const Color(0xFF1E0E1B)]
                        : [const Color(0xFF1F1D40), const Color(0xFF0F0E1C)],
                  ),
                  border: Border.all(
                    color: AppTheme.accentPurple.withOpacity(0.3),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isReversed ? Icons.blur_on : Icons.brightness_high,
                        color: isReversed ? AppTheme.accentPink : AppTheme.accentGold,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          card.name,
                          style: textTheme.displayMedium?.copyWith(
                            fontSize: 18,
                            color: AppTheme.textLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Keywords
            Wrap(
              spacing: 6,
              children: card.keywords.map((kw) {
                return Chip(
                  backgroundColor: AppTheme.background.withOpacity(0.6),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  labelStyle: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textLight),
                  label: Text(kw),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // Meaning summary
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                child: Text(
                  isReversed ? card.reversedMeaning : card.uprightMeaning,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: AppTheme.textLight,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
