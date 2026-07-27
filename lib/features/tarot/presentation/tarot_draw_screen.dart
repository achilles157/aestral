import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/tarot_data.dart';
import '../models/tarot_card.dart';
import '../providers/tarot_language_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/tarot_card_display.dart';
import 'widgets/tiltable_tarot_card.dart';
import 'widgets/tarot_draw_modals.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/providers/birth_profile_provider.dart';
import '../../../core/models/birth_profile.dart';
import '../../../core/utils/weton_utils.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/radial_glow_painter.dart';
import '../../../core/widgets/glass_button.dart';
import '../models/tarot_oracle_reading.dart';
import 'widgets/tarot_oracle_panel.dart';
import 'widgets/tarot_draw_type_toggle.dart';
import 'widgets/tarot_carousel_section.dart';
import '../../ai/presentation/oracle_chat_screen.dart';
import '../../history/models/reading_entry.dart';
import '../../history/services/reading_history_service.dart';
import '../../../core/services/analytics_service.dart';

class TarotDrawScreen extends ConsumerStatefulWidget {
  const TarotDrawScreen({super.key});

  @override
  ConsumerState<TarotDrawScreen> createState() => _TarotDrawScreenState();
}

class _TarotDrawScreenState extends ConsumerState<TarotDrawScreen>
    with TickerProviderStateMixin {
  late List<AnimationController> _flipControllers;
  late List<Animation<double>> _flipAnimations;
  final ScreenshotController _screenshotController = ScreenshotController();
  late PageController _pageController;
  List<bool> _cardRevealedStates = [false, false, false];
  // Ceremony pulse state — brief scale pulse sebelum flip dimulai
  List<bool> _cardPulsing = [false, false, false];
  int _activeCarouselIndex = 0;
  bool _isLoading = false;
  String _selectedDrawType = 'mangsa';
  TarotOracleReading? _oracleReading;
  bool _isOracleLoading = false;
  bool _oracleError = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _flipControllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      );
    });

    _flipAnimations = _flipControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: pi).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOutBack),
      );
    }).toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _flipControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleDraw(List<TarotCard> deck) async {
    // Guard against double-tap while a draw is already in progress
    if (_isLoading) return;

    final messenger = ScaffoldMessenger.of(context);
    final drawnCards = ref.read(drawnCardProvider);

    if (drawnCards != null) {
      // Reset card first
      Future.wait(_flipControllers.map((c) => c.reverse())).then((_) {
        ref.read(drawnCardProvider.notifier).reset();
        setState(() {
          _cardRevealedStates = [false, false, false];
          _activeCarouselIndex = 0;
          _oracleReading = null;
          _oracleError = false;
        });
      });
      return;
    }

    final session = ref.read(authProvider);
    if (session == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Sesi tidak valid. Silakan login kembali.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      BirthProfile profile = await ref.read(birthProfileProvider.future);
      DateTime? selectedDate = profile.dobDate;

      if (selectedDate == null) {
        if (!mounted) return;
        // Show onboarding modal
        final pickedDob = await showOnboardingBirthdayModal(context, ref);
        if (pickedDob == null) {
          // User cancelled
          setState(() => _isLoading = false);
          return;
        }
        profile = await ref.read(birthProfileProvider.future);
        selectedDate = profile.dobDate;
      }

      if (selectedDate == null) {
        setState(() => _isLoading = false);
        return;
      }

      final birthDateTime = selectedDate;
      final birthDateStr =
          "${birthDateTime.year}-${birthDateTime.month.toString().padLeft(2, '0')}-${birthDateTime.day.toString().padLeft(2, '0')}";

      final birthWeton = WetonUtils.calculateWeton(birthDateTime);
      final mangsaId = WetonUtils.calculatePranataMangsaId(DateTime.now());

      final authHeader = await ref.read(authProvider.notifier).getAuthHeader();

      final response = await ApiService.drawTarot(
        birthDate: birthDateStr,
        pangarasan: birthWeton.pangarasan,
        drawType: session.isMock ? 'birth' : _selectedDrawType,
        mangsaId: _selectedDrawType == 'mangsa' ? mangsaId : null,
        authHeader: authHeader,
      );

      final List<dynamic> cardsJson = response['cards'] as List<dynamic>;
      final List<DrawnCardInfo> drawnCardsList = cardsJson.map((cJson) {
        final cardIndex = cJson['cardIndex'] as int;
        final isReversed = cJson['isReversed'] as bool? ?? false;
        final label = cJson['label'] as String;
        final card = deck.firstWhere(
          (c) => c.id == cardIndex,
          orElse: () => deck.first,
        );
        return DrawnCardInfo(card: card, isReversed: isReversed, label: label);
      }).toList();

      ref.read(drawnCardProvider.notifier).setCards(drawnCardsList);
      // Save to reading history (fire-and-forget)
      ReadingHistoryService.save(
        ReadingEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'tarot',
          title: drawnCardsList.map((c) => c.card.nameId).join(' · '),
          subtitle: session.isMock || _selectedDrawType == 'birth'
              ? 'Tarot Lahir'
              : 'Tarot Kosmis',
          timestamp: DateTime.now(),
          accentColor: 0xFFBA68C8,
        ),
      ).catchError((_) {});
      AnalyticsService.logTarotDrawn(
        session.isMock || _selectedDrawType == 'birth' ? 'birth' : 'mangsa',
      ).catchError((_) {});
      // Save to Firestore for logged-in users (cross-device history)
      if (!session.isMock) {
        _saveToFirestore(
          uid: session.uid,
          drawnCards: drawnCardsList,
          drawType: _selectedDrawType,
          birthDate: birthDateStr,
        ).catchError((_) {});
      }
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error calling backend, falling back to local draw: $e');
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Koneksi terganggu. Menggunakan penarikan lokal offline.',
          ),
          backgroundColor: AppTheme.accentPink,
        ),
      );

      // Fallback to local RNG
      ref.read(drawnCardProvider.notifier).drawCard(deck);
      setState(() => _isLoading = false);
    }
  }

  void _revealCard(int index) {
    if (_cardRevealedStates[index]) return;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      // Skip flip animation — langsung reveal
      _flipControllers[index].value = pi;
      setState(() => _cardRevealedStates[index] = true);
    } else {
      // Ceremony: brief scale pulse sebelum flip dimulai
      setState(() => _cardPulsing[index] = true);
      Future.delayed(const Duration(milliseconds: 180), () {
        if (!mounted) return;
        setState(() => _cardPulsing[index] = false);
        _flipControllers[index].forward().then((_) {
          if (mounted) setState(() => _cardRevealedStates[index] = true);
        });
      });
    }
  }

  Future<void> _generateOracleReading(List<DrawnCardInfo> drawnCards) async {
    if (_isOracleLoading) return;
    setState(() {
      _isOracleLoading = true;
      _oracleError = false;
    });

    try {
      final session = ref.read(authProvider);
      if (session == null) {
        setState(() => _isOracleLoading = false);
        return;
      }

      final authHeader = await ref.read(authProvider.notifier).getAuthHeader();

      final cards = drawnCards
          .map(
            (info) => <String, dynamic>{
              'label': info.label,
              'nameId': info.card.nameId,
              'isReversed': info.isReversed,
              'uprightMeaning': info.card.uprightMeaningId,
              'reversedMeaning': info.card.reversedMeaningId,
              'archetypeId': info.card.archetypeId,
              'elementalId': info.card.elementalId,
              'keywordsId': info.card.keywordsId,
              if (info.card.aiHookId.isNotEmpty) 'aiHookId': info.card.aiHookId,
            },
          )
          .toList();

      final currentWeton = WetonUtils.calculateWeton(DateTime.now());
      final wetonContext = {
        'wukuBerjalan': {'nama': currentWeton.wuku, 'elemen': ''},
      };

      final result = await ApiService.generateTarotReading(
        cards: cards,
        authHeader: authHeader,
        wetonContext: wetonContext,
      );

      if (!mounted) return;
      setState(() {
        _oracleReading = TarotOracleReading.fromJson(result);
        _isOracleLoading = false;
      });
    } catch (e) {
      debugPrint('Oracle tarot reading error: $e');
      if (!mounted) return;
      setState(() {
        _isOracleLoading = false;
        _oracleError = true;
      });
    }
  }

  Future<void> _consultOracle(List<DrawnCardInfo> drawnCards) async {
    final authHeader = await ref.read(authProvider.notifier).getAuthHeader();
    if (!mounted) return;

    final aiContext = {
      'tarotCards': drawnCards
          .map(
            (c) => {
              'name': c.card.nameId,
              'label': c.label,
              'isReversed': c.isReversed,
              'archetype': c.card.archetypeId,
              'element': c.card.elementalId,
              'aiHook': c.card.aiHookId,
              'keywords': c.card.keywordsId,
            },
          )
          .toList(),
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OracleChatScreen(
          oracleType: 'tarot',
          authHeader: authHeader,
          aiContext: aiContext,
        ),
      ),
    );
  }

  // ─── Empty card placeholder row ─────────────────────────────────────────

  Widget _buildEmptyCardRow(String currentLang) {
    return Column(
      children: [
        Text(
          currentLang == 'id'
              ? 'Tanyakan sesuatu pada semesta,\nlalu tarik tiga kartu.'
              : 'Ask the universe something,\nthen draw your three cards.',
          style: GoogleFonts.playfairDisplay(
            fontSize: 13,
            color: AppTheme.textLight.withValues(alpha: 0.45),
            fontStyle: FontStyle.italic,
            height: 1.7,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (index) {
            final labelText = index == 0
                ? (currentLang == 'id' ? 'Masa Lalu' : 'Past')
                : index == 1
                ? (currentLang == 'id' ? 'Masa Kini' : 'Present')
                : (currentLang == 'id' ? 'Masa Depan' : 'Future');
            const cardWidth = 90.0;
            const cardHeight = 145.0;
            return Column(
              children: [
                Text(
                  labelText,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textLight.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 8),
                const Opacity(
                  opacity: 0.6,
                  child: CardBack(width: cardWidth, height: cardHeight),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  /// Simpan draw tarot ke Firestore subcollection tarot_history.
  /// Fire-and-forget — non-fatal jika Firestore tidak tersedia.
  Future<void> _saveToFirestore({
    required String uid,
    required List<DrawnCardInfo> drawnCards,
    required String drawType,
    required String birthDate,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tarot_history')
        .add({
          'cards': drawnCards
              .map(
                (c) => {
                  'nameId': c.card.nameId,
                  'isReversed': c.isReversed,
                  'label': c.label,
                  'archetypeId': c.card.archetypeId,
                  'elementalId': c.card.elementalId,
                },
              )
              .toList(),
          'drawType': drawType,
          'drawnAt': FieldValue.serverTimestamp(),
          'birthDate': birthDate,
        });
  }

  Widget _buildOracleSection(List<DrawnCardInfo> drawnCards) {
    if (_oracleReading != null) {
      return Column(
        children: [
          TarotOraclePanel(
            oracleReading: _oracleReading!,
            drawnCards: drawnCards,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _consultOracle(drawnCards),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0).withValues(alpha: 0.15),
              side: BorderSide(
                color: const Color(0xFF9C27B0).withValues(alpha: 0.5),
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            icon: const Icon(
              Icons.auto_awesome,
              color: Color(0xFFCE93D8),
              size: 18,
            ),
            label: Text(
              '✦ Tanya Madame Sophia',
              style: GoogleFonts.playfairDisplay(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFCE93D8),
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      );
    }

    if (_isOracleLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const CircularProgressIndicator(color: AppTheme.accentGold),
            const SizedBox(height: 12),
            Text(
              'Orakel sedang membaca benang kosmis...',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_oracleError) ...[
          Text(
            'Koneksi orakel terputus. Coba lagi.',
            style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.accentPink),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
        ElevatedButton.icon(
          onPressed: () => _generateOracleReading(drawnCards),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentGold.withValues(alpha: 0.12),
            side: BorderSide(
              color: AppTheme.accentGold.withValues(alpha: 0.5),
              width: 1,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          icon: const Icon(
            Icons.auto_awesome,
            color: AppTheme.accentGold,
            size: 18,
          ),
          label: Text(
            _oracleError ? 'Coba Lagi' : '✦ Singkap Bacaan Kosmis',
            style: GoogleFonts.playfairDisplay(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentGold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLangButton(
    BuildContext context,
    WidgetRef ref,
    String label,
    bool isActive,
  ) {
    return Semantics(
      label: 'Bahasa $label${isActive ? ', dipilih' : ''}',
      button: true,
      selected: isActive,
      child: GestureDetector(
        onTap: () {
          ref
              .read(tarotLanguageProvider.notifier)
              .setLanguage(label.toLowerCase());
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deckAsync = ref.watch(tarotDeckProvider);
    final drawnCards = ref.watch(drawnCardProvider);
    final textTheme = Theme.of(context).textTheme;
    final currentLang = ref.watch(tarotLanguageProvider);
    final session = ref.watch(authProvider);

    final bool allFlipped = !_cardRevealedStates.contains(false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          session == null || session.isMock
              ? (currentLang == 'id'
                    ? 'Tarot Lahir (Soul Card)'
                    : 'Birth Tarot (Soul Card)')
              : (_selectedDrawType == 'birth'
                    ? (currentLang == 'id'
                          ? 'Tarot Lahir (Soul Card)'
                          : 'Birth Tarot (Soul Card)')
                    : (currentLang == 'id' ? 'Tarot Kosmis' : 'Cosmic Tarot')),
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: AppTheme.accentGold,
            fontSize: 20,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.accentGold.withValues(alpha: 0.4),
                width: 1,
              ),
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
          // Background gradient
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
          // Cosmic star overlay for glassmorphism depth
          Positioned.fill(
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(
                'assets/images/tarot_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
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
                              if (session != null &&
                                  !session.isMock &&
                                  drawnCards == null) ...[
                                TarotDrawTypeToggle(
                                  selectedDrawType: _selectedDrawType,
                                  currentLang: currentLang,
                                  onTypeChanged: (t) =>
                                      setState(() => _selectedDrawType = t),
                                ),
                              ],
                              Text(
                                session == null ||
                                        session.isMock ||
                                        _selectedDrawType == 'birth'
                                    ? (currentLang == 'id'
                                          ? 'Tarot Lahir merepresentasikan blueprint jiwa Anda. Kartu ini bersifat statis seumur hidup.'
                                          : 'Birth Tarot represents your soul blueprint. This card is static for lifetime.')
                                    : (currentLang == 'id'
                                          ? 'Tebaran kartu kosmis mengikuti ritme alam semesta yang berganti setiap beberapa pekan.'
                                          : 'Your cosmic spread shifts with the natural rhythm of the universe every few weeks.'),
                                style: textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              // Capture area for social sharing
                              Screenshot(
                                controller: _screenshotController,
                                child: Container(
                                  color: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: drawnCards == null
                                      ? _buildEmptyCardRow(currentLang)
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: List.generate(3, (index) {
                                            final cardInfo = drawnCards[index];
                                            final labelText = index == 0
                                                ? (currentLang == 'id'
                                                      ? 'Masa Lalu'
                                                      : 'Past')
                                                : index == 1
                                                ? (currentLang == 'id'
                                                      ? 'Masa Kini'
                                                      : 'Present')
                                                : (currentLang == 'id'
                                                      ? 'Masa Depan'
                                                      : 'Future');

                                            final double value =
                                                _flipAnimations[index].value;
                                            final bool isFront =
                                                value >= pi / 2;

                                            final themeBorderColor =
                                                cardInfo.isReversed
                                                ? AppTheme.accentPink
                                                : AppTheme.accentGold;

                                            const cardWidth = 90.0;
                                            const cardHeight = 145.0;

                                            return Column(
                                              children: [
                                                Text(
                                                  labelText,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.accentGold,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Semantics(
                                                  label:
                                                      _cardRevealedStates[index]
                                                      ? 'Kartu sudah tersingkap'
                                                      : 'Ketuk untuk menyingkap kartu',
                                                  button:
                                                      !_cardRevealedStates[index],
                                                  child: GestureDetector(
                                                    onTap: () =>
                                                        _revealCard(index),
                                                    child: AnimatedScale(
                                                      scale: _cardPulsing[index]
                                                          ? 1.08
                                                          : 1.0,
                                                      duration: const Duration(
                                                        milliseconds: 160,
                                                      ),
                                                      curve: Curves.easeOut,
                                                      child: AnimatedBuilder(
                                                        animation:
                                                            _flipAnimations[index],
                                                        builder: (context, child) {
                                                          return Stack(
                                                            alignment: Alignment
                                                                .center,
                                                            clipBehavior:
                                                                Clip.none,
                                                            children: [
                                                              if (isFront)
                                                                CustomPaint(
                                                                  size: const Size(
                                                                    cardWidth,
                                                                    cardHeight,
                                                                  ),
                                                                  painter: RadialGlowPainter(
                                                                    glowColor:
                                                                        themeBorderColor,
                                                                    radiusMultiplier:
                                                                        1.3,
                                                                    opacity:
                                                                        0.3,
                                                                  ),
                                                                ),
                                                              TiltableTarotCard(
                                                                width:
                                                                    cardWidth,
                                                                height:
                                                                    cardHeight,
                                                                child: Transform(
                                                                  transform:
                                                                      Matrix4.identity()
                                                                        ..setEntry(
                                                                          3,
                                                                          2,
                                                                          0.002,
                                                                        )
                                                                        ..rotateY(
                                                                          value,
                                                                        ),
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  child: isFront
                                                                      ? Transform(
                                                                          transform: Matrix4.identity()
                                                                            ..rotateY(
                                                                              pi,
                                                                            ),
                                                                          alignment:
                                                                              Alignment.center,
                                                                          child: PulsingAura(
                                                                            glowColor:
                                                                                themeBorderColor,
                                                                            child: CardFront(
                                                                              drawnCard: cardInfo,
                                                                              width: cardWidth,
                                                                              height: cardHeight,
                                                                            ),
                                                                          ),
                                                                        )
                                                                      : const CardBack(
                                                                          width:
                                                                              cardWidth,
                                                                          height:
                                                                              cardHeight,
                                                                        ),
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }),
                                        ),
                                ),
                              ),
                              // Tap hint — only visible when cards drawn but not all flipped yet
                              if (drawnCards != null && !allFlipped)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.touch_app_rounded,
                                        size: 14,
                                        color: Colors.white38,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Ketuk kartu untuk menyingkap',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: Colors.white38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 32),
                              GlassButton(
                                onPressed: () => _handleDraw(deck),
                                isEnabled: !_isLoading,
                                glowColor: drawnCards != null
                                    ? AppTheme.accentPink
                                    : AppTheme.accentPurple,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: AppTheme.textLight,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        drawnCards != null
                                            ? Icons.refresh
                                            : Icons.auto_awesome,
                                        color: AppTheme.textLight,
                                        size: 20,
                                      ),
                                label: Text(
                                  _isLoading
                                      ? (currentLang == 'id'
                                            ? 'Menarik...'
                                            : 'Drawing...')
                                      : drawnCards != null
                                      ? (currentLang == 'id'
                                            ? 'Tarik Ulang'
                                            : 'Redraw')
                                      : (currentLang == 'id'
                                            ? 'Tarik Kartu'
                                            : 'Draw Card'),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Share button (only active when cards are drawn)
                              if (drawnCards != null) ...[
                                TextButton.icon(
                                  onPressed: () => shareCardResult(
                                    context: context,
                                    screenshotController: _screenshotController,
                                  ),
                                  icon: const Icon(
                                    Icons.share,
                                    color: AppTheme.accentGold,
                                  ),
                                  label: Text(
                                    'Bagikan Hasil',
                                    style: textTheme.labelLarge?.copyWith(
                                      color: AppTheme.accentGold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Carousel detail reading
                                if (allFlipped) ...[
                                  TarotCarouselSection(
                                    drawnCards: drawnCards,
                                    activeIndex: _activeCarouselIndex,
                                    currentLang: currentLang,
                                    pageController: _pageController,
                                    onPageChanged: (i) => setState(
                                      () => _activeCarouselIndex = i,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _buildOracleSection(drawnCards),
                                  const SizedBox(height: 24),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.accentPurple),
              ),
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
