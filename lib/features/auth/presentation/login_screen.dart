import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/login_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;

  late final AnimationController _animController;

  // Staggered fade+slide intervals
  late final Animation<double> _mandalaFade;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _buttonsFade;
  late final Animation<Offset> _buttonsSlide;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Mandala fades in first (0% – 40%)
    _mandalaFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    // Logo text fades + slides (15% – 50%)
    _logoFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.15, 0.50, curve: Curves.easeOut),
    );
    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.15, 0.50, curve: Curves.easeOut),
          ),
        );

    // Tagline (30% – 60%)
    _taglineFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.30, 0.60, curve: Curves.easeOut),
    );
    _taglineSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.30, 0.60, curve: Curves.easeOut),
          ),
        );

    // Buttons (35% – 70%) — moved earlier so button is tappable by ~700ms
    _buttonsFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.35, 0.70, curve: Curves.easeOut),
    );
    _buttonsSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.35, 0.70, curve: Curves.easeOut),
          ),
        );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Business logic (unchanged) ──────────────────────────────────────

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final auth = ref.read(authProvider.notifier);
    try {
      if (auth.isFirebaseAvailable) {
        final success = await auth.signInWithGoogle();
        if (!success) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Gagal Masuk via Google. Coba lagi atau gunakan Akun Tamu.',
                ),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppTheme.accentGold, width: 1.5),
              ),
              title: const Text(
                'Firebase Belum Siap',
                style: TextStyle(color: AppTheme.accentGold),
              ),
              content: const Text(
                'Layanan tidak tersedia saat ini. '
                'Coba lagi nanti, atau lanjutkan sebagai tamu untuk menggunakan fitur offline.',
                style: TextStyle(color: AppTheme.textLight),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'OK',
                    style: TextStyle(color: AppTheme.textLight),
                  ),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('LoginScreen._handleGoogleSignIn error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGuestSignIn() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signInAsGuest();
    } catch (e) {
      debugPrint('LoginScreen._handleGuestSignIn error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal masuk sebagai tamu. Coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── UI ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.background,
                  Color(0xFF150F33),
                  Color(0xFF090618),
                ],
              ),
            ),
          ),
          // Star overlay decor
          const Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: Image(
                image: AssetImage('assets/images/stars_bg.png'),
                fit: BoxFit.cover,
                errorBuilder: _fallbackStars,
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: constraints.maxHeight * 0.12),

                            // ── Rotating Mandala + Logo ──
                            FadeTransition(
                              opacity: _mandalaFade,
                              child: Center(
                                child: SizedBox(
                                  width: 220,
                                  height: 220,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Golden glow behind mandala
                                      Container(
                                        width: 160,
                                        height: 160,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.accentGold
                                                  .withValues(alpha: 0.15),
                                              blurRadius: 60,
                                              spreadRadius: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Rotating mandala
                                      LoginRotatingMandala(size: 200),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),

                            // ── AESTRAL Logo Text ──
                            SlideTransition(
                              position: _logoSlide,
                              child: FadeTransition(
                                opacity: _logoFade,
                                child: Center(
                                  child: Text(
                                    'A E S T R A L',
                                    style: textTheme.displayLarge?.copyWith(
                                      fontSize: 42,
                                      letterSpacing: 8,
                                      color: AppTheme.accentGold,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // ── Tagline ──
                            SlideTransition(
                              position: _taglineSlide,
                              child: FadeTransition(
                                opacity: _taglineFade,
                                child: Center(
                                  child: Text(
                                    'Pintu Gerbang Takdir & Misteri Kosmis',
                                    style: textTheme.bodyLarge?.copyWith(
                                      letterSpacing: 1.5,
                                      color: AppTheme.textLight.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: constraints.maxHeight * 0.10),

                            // ── Login Buttons ──
                            SlideTransition(
                              position: _buttonsSlide,
                              child: FadeTransition(
                                opacity: _buttonsFade,
                                child: _isLoading
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          color: AppTheme.accentPurple,
                                        ),
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          // Google Sign-In — glassmorphic
                                          LoginGlassButton(
                                            onTap: _handleGoogleSignIn,
                                            borderColor: AppTheme.accentGold
                                                .withValues(alpha: 0.4),
                                            icon: const LoginGoogleBrandIcon(),
                                            label: 'Masuk Dengan Google',
                                          ),

                                          const SizedBox(height: 16),

                                          // Guest Login — glassmorphic purple
                                          LoginGlassButton(
                                            onTap: _handleGuestSignIn,
                                            borderColor: AppTheme.accentPurple
                                                .withValues(alpha: 0.5),
                                            glowColor: AppTheme.accentPurple
                                                .withValues(alpha: 0.08),
                                            icon: const Icon(
                                              Icons.person_outline,
                                              color: AppTheme.accentPurple,
                                              size: 24,
                                            ),
                                            label: 'Masuk Sebagai Tamu',
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            SizedBox(height: constraints.maxHeight * 0.08),

                            // Version note removed — internal label
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fallback for missing stars_bg.png ─────────────────────────────────

Widget _fallbackStars(
  BuildContext context,
  Object exception,
  StackTrace? stackTrace,
) {
  return Container();
}
