import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/tarot_data.dart';
import '../models/tarot_card.dart';
import '../providers/tarot_language_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/tarot_card_display.dart';
import 'widgets/tiltable_tarot_card.dart';
import 'widgets/tarot_draw_modals.dart';
import 'widgets/tarot_reading_detail_panel.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/services/profile_service.dart';
import '../../../core/utils/weton_utils.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/radial_glow_painter.dart';

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
  bool _isLoading = false;
  String _selectedDrawType = 'weekly';

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



  Future<void> _handleDraw(List<TarotCard> deck) async {
    final messenger = ScaffoldMessenger.of(context);
    if (_isCardRevealed) {
      // Reset card first
      _flipController.reverse().then((_) {
        ref.read(drawnCardProvider.notifier).reset();
        setState(() {
          _isCardRevealed = false;
        });
      });
      return;
    }

    final session = ref.read(authProvider);
    if (session == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Sesi tidak valid. Silakan login kembali.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic>? profile = await ref.read(profileProvider).loadProfile();
      int? dobUtcMs = profile?['biometric_anchor']?['dob_utc_ms'] as int?;

      if (dobUtcMs == null) {
        if (!mounted) return;
        // Show onboarding modal
        final pickedDob = await showOnboardingBirthdayModal(context, ref);
        if (pickedDob == null) {
          // User cancelled
          setState(() => _isLoading = false);
          return;
        }
        profile = await ref.read(profileProvider).loadProfile();
        dobUtcMs = profile?['biometric_anchor']?['dob_utc_ms'] as int?;
      }

      if (dobUtcMs == null) {
        setState(() => _isLoading = false);
        return;
      }

      final birthDateTime = DateTime.fromMillisecondsSinceEpoch(dobUtcMs);
      final birthDateStr = "${birthDateTime.year}-${birthDateTime.month.toString().padLeft(2, '0')}-${birthDateTime.day.toString().padLeft(2, '0')}";

      final birthWeton = WetonUtils.calculateWeton(birthDateTime);
      final currentWeton = WetonUtils.calculateWeton(DateTime.now());

      String authHeader = 'Guest ${session.uid}';
      if (!session.isMock) {
        try {
          final token = await FirebaseAuth.instance.currentUser?.getIdToken();
          if (token != null) {
            authHeader = 'Bearer $token';
          }
        } catch (e) {
          debugPrint('Error getting ID token: $e');
        }
      }

      final response = await ApiService.drawTarot(
        birthDate: birthDateStr,
        pangarasan: birthWeton.pangarasan,
        wuku: currentWeton.wuku,
        drawType: session.isMock ? 'birth' : _selectedDrawType,
        authHeader: authHeader,
      );

      final cardIndex = response['cardIndex'] as int;
      final card = deck.firstWhere((c) => c.id == cardIndex, orElse: () => deck.first);
      final isReversed = response['isReversed'] as bool? ?? false;

      ref.read(drawnCardProvider.notifier).setCard(card, isReversed);

      _flipController.forward().then((_) {
        setState(() {
          _isCardRevealed = true;
          _isLoading = false;
        });
      });
    } catch (e) {
      debugPrint('Error calling backend, falling back to local draw: $e');
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Koneksi terganggu. Menggunakan penarikan lokal offline.'),
          backgroundColor: AppTheme.accentPink,
        ),
      );
      
      // Fallback to local RNG
      ref.read(drawnCardProvider.notifier).drawCard(deck);
      _flipController.forward().then((_) {
        setState(() {
          _isCardRevealed = true;
          _isLoading = false;
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
    final session = ref.watch(authProvider);

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
          session == null || session.isMock
              ? (currentLang == 'id' ? 'Tarot Lahir (Soul Card)' : 'Birth Tarot (Soul Card)')
              : (_selectedDrawType == 'birth'
                  ? (currentLang == 'id' ? 'Tarot Lahir (Soul Card)' : 'Birth Tarot (Soul Card)')
                  : (currentLang == 'id' ? 'Tarot Mingguan' : 'Weekly Tarot')),
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: AppTheme.accentGold,
            fontSize: 20,
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
              border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.4), width: 1),
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withValues(alpha: 0.03),
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
                              if (session != null && !session.isMock && !_isCardRevealed) ...[
                                Container(
                                  margin: const EdgeInsets.only(bottom: 24),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: AppTheme.accentGold.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedDrawType = 'weekly';
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: _selectedDrawType == 'weekly'
                                                ? AppTheme.accentPurple
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                          child: Text(
                                            currentLang == 'id' ? 'Tarot Mingguan' : 'Weekly Tarot',
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: _selectedDrawType == 'weekly'
                                                  ? AppTheme.textLight
                                                  : AppTheme.textLight.withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedDrawType = 'birth';
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: _selectedDrawType == 'birth'
                                                ? AppTheme.accentPurple
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                          child: Text(
                                            currentLang == 'id' ? 'Tarot Lahir' : 'Birth Tarot',
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: _selectedDrawType == 'birth'
                                                  ? AppTheme.textLight
                                                  : AppTheme.textLight.withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              Text(
                                session == null || session.isMock || _selectedDrawType == 'birth'
                                    ? (currentLang == 'id' 
                                        ? 'Tarot Lahir merepresentasikan blueprint jiwa Anda. Kartu ini bersifat statis seumur hidup.'
                                        : 'Birth Tarot represents your soul blueprint. This card is static for lifetime.')
                                    : (currentLang == 'id'
                                        ? 'Tarik Tarot Mingguan untuk melihat peruntungan nasib mingguan Anda berdasarkan siklus Wuku.'
                                        : 'Draw your Weekly Tarot to see your weekly destiny influenced by the current Wuku cycle.'),
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

                                      final themeBorderColor = (drawnCard?.isReversed ?? false)
                                          ? AppTheme.accentPink
                                          : AppTheme.accentGold;

                                      return Stack(
                                        alignment: Alignment.center,
                                        clipBehavior: Clip.none,
                                        children: [
                                          if (isFront)
                                            CustomPaint(
                                              size: const Size(260, 410),
                                              painter: RadialGlowPainter(
                                                glowColor: themeBorderColor,
                                                radiusMultiplier: 1.5,
                                                opacity: 0.35,
                                              ),
                                            ),
                                          TiltableTarotCard(
                                            child: Transform(
                                              transform: Matrix4.identity()
                                                ..setEntry(3, 2, 0.002) // 3D Perspective
                                                ..rotateY(value),
                                              alignment: Alignment.center,
                                              child: isFront
                                                  ? Transform(
                                                      transform: Matrix4.identity()..rotateY(pi),
                                                      alignment: Alignment.center,
                                                      child: PulsingAura(
                                                        glowColor: themeBorderColor,
                                                        child: CardFront(drawnCard: drawnCard),
                                                      ),
                                                    )
                                                  : const CardBack(),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              // Draw button
                              _isLoading
                                  ? const CircularProgressIndicator(color: AppTheme.accentGold)
                                  : ElevatedButton(
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
                                  onPressed: () => shareCardResult(
                                    context: context,
                                    screenshotController: _screenshotController,
                                  ),
                                  icon: const Icon(Icons.share, color: AppTheme.accentGold),
                                  label: Text(
                                    'Bagikan Hasil',
                                    style: textTheme.labelLarge?.copyWith(
                                      color: AppTheme.accentGold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                 if (card != null)
                                  TarotReadingDetailPanel(
                                    card: card,
                                    isReversed: isReversed,
                                    currentLang: currentLang,
                                    suitColor: suitColor,
                                    elementLabel: elementLabel,
                                  ),
                                  const SizedBox(height: 20),
                                ],
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


}


