import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/tarot_data.dart';
import '../models/tarot_card.dart';
import '../providers/tarot_language_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/tarot_card_display.dart';
import 'widgets/tiltable_tarot_card.dart';
import '../../../core/utils/file_saver.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/services/profile_service.dart';
import '../../../core/utils/weton_utils.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/glass_card.dart';
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

  Future<DateTime?> _showOnboardingBirthdayModal(BuildContext context) async {
    DateTime? tempDate;
    return showDialog<DateTime>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: AppTheme.accentGold, width: 1.5),
              ),
              title: Column(
                children: [
                  const Icon(Icons.auto_awesome, color: AppTheme.accentGold, size: 36),
                  const SizedBox(height: 12),
                  Text(
                    'Pintu Gerbang Takdir',
                    style: GoogleFonts.playfairDisplay(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentGold,
                      fontSize: 22,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sebelum dapat menarik kartu tarot dan melihat weton harianmu, selaraskan energi kosmikmu dengan memasukkan tanggal lahir.',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppTheme.textLight.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000, 1, 1),
                        firstDate: DateTime(1900),
                        lastDate: now,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppTheme.accentPurple,
                                onPrimary: AppTheme.textLight,
                                surface: AppTheme.cardBg,
                                onSurface: AppTheme.textLight,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setModalState(() {
                          tempDate = picked;
                        });
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.accentPurple, width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    icon: const Icon(Icons.cake, color: AppTheme.accentPurple),
                    label: Text(
                      tempDate == null
                          ? 'Pilih Tanggal Lahir'
                          : DateFormat('dd MMMM yyyy').format(tempDate!),
                      style: const TextStyle(color: AppTheme.textLight),
                    ),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text(
                    'Batal',
                    style: TextStyle(color: AppTheme.textLight.withValues(alpha: 0.6)),
                  ),
                ),
                ElevatedButton(
                  onPressed: tempDate == null
                      ? null
                      : () async {
                          final dob = tempDate!;
                          final weton = WetonUtils.calculateWeton(dob);
                          final success = await ref.read(profileProvider).saveProfile(
                            dob: dob,
                            latitude: 0.0,
                            longitude: 0.0,
                            weton: weton,
                          );
                          if (context.mounted) {
                            if (success) {
                              Navigator.pop(context, dob);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Gagal menyimpan profil, coba lagi.'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGold,
                    foregroundColor: AppTheme.background,
                  ),
                  child: const Text('Selaraskan Energi'),
                ),
              ],
            );
          },
        );
      },
    );
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
        final pickedDob = await _showOnboardingBirthdayModal(context);
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
                                  GlassCard(
                                    margin: const EdgeInsets.only(top: 8, bottom: 24),
                                    borderColor: suitColor.withValues(alpha: 0.35),
                                    borderWidth: 1.5,
                                    borderRadius: 24,
                                    color: AppTheme.cardBg.withValues(alpha: 0.7),
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
                                            color: AppTheme.textLight.withValues(alpha: 0.95),
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
                                          _buildSectionTitle(context, currentLang == 'id' ? 'Pertanyaan Refleksi' : 'Self-Reflection'),
                                          const SizedBox(height: 12),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: AppTheme.background.withValues(alpha: 0.4),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: AppTheme.accentPurple.withValues(alpha: 0.2), width: 1),
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
                                                            color: AppTheme.textLight.withValues(alpha: 0.9),
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
                                              color: AppTheme.textLight.withValues(alpha: 0.85),
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
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gambar berhasil diunduh: $fileName!'),
                          backgroundColor: AppTheme.accentPurple,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
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


