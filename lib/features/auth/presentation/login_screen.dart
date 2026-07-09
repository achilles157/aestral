import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../home/presentation/widgets/starry_background.dart';

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
  late final Animation<double> _footerFade;

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
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.15, 0.50, curve: Curves.easeOut),
    ));

    // Tagline (30% – 60%)
    _taglineFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.30, 0.60, curve: Curves.easeOut),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.30, 0.60, curve: Curves.easeOut),
    ));

    // Buttons (50% – 80%)
    _buttonsFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.50, 0.80, curve: Curves.easeOut),
    );
    _buttonsSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.50, 0.80, curve: Curves.easeOut),
    ));

    // Footer (70% – 100%)
    _footerFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.70, 1.0, curve: Curves.easeOut),
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
                content: Text('Gagal Masuk via Google. Coba lagi atau gunakan Akun Tamu.'),
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
              title: const Text('Firebase Belum Siap', style: TextStyle(color: AppTheme.accentGold)),
              content: const Text(
                'Aplikasi mendeteksi bahwa berkas konfigurasi Firebase Anda belum terpasang. '
                'Silakan baca berkas "firebase_setup_guide.md" untuk petunjuk setup.\n\n'
                'Untuk sekarang, Anda dapat memilih "Masuk Sebagai Tamu" untuk menguji aplikasi secara offline.',
                style: TextStyle(color: AppTheme.textLight),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK', style: TextStyle(color: AppTheme.textLight)),
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
      if (mounted) setState(() => _isLoading = false);
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
                                              color: AppTheme.accentGold.withValues(alpha: 0.15),
                                              blurRadius: 60,
                                              spreadRadius: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Rotating mandala
                                      _RotatingMandala(size: 200),
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
                                      color: AppTheme.textLight.withValues(alpha: 0.8),
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
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          // Google Sign-In — glassmorphic
                                          _GlassLoginButton(
                                            onTap: _handleGoogleSignIn,
                                            borderColor: AppTheme.accentGold.withValues(alpha: 0.4),
                                            icon: const _GoogleBrandIcon(),
                                            label: 'Masuk Dengan Google',
                                          ),

                                          const SizedBox(height: 16),

                                          // Guest Login — glassmorphic purple
                                          _GlassLoginButton(
                                            onTap: _handleGuestSignIn,
                                            borderColor: AppTheme.accentPurple.withValues(alpha: 0.5),
                                            glowColor: AppTheme.accentPurple.withValues(alpha: 0.08),
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

                            // Zero budget note
                            FadeTransition(
                              opacity: _footerFade,
                              child: Center(
                                child: Text(
                                  'Zero-Budget High-Performance Architecture',
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontSize: 12,
                                    color: AppTheme.textMuted.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),
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

// ── Rotating Mandala (60s cycle) ──────────────────────────────────────

class _RotatingMandala extends StatefulWidget {
  final double size;
  const _RotatingMandala({required this.size});

  @override
  State<_RotatingMandala> createState() => _RotatingMandalaState();
}

class _RotatingMandalaState extends State<_RotatingMandala>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationController.value * 2 * pi,
          child: child,
        );
      },
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: MandalaPainter(),
      ),
    );
  }
}

// ── Glassmorphic Login Button ─────────────────────────────────────────

class _GlassLoginButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color borderColor;
  final Color? glowColor;
  final Widget icon;
  final String label;

  const _GlassLoginButton({
    required this.onTap,
    required this.borderColor,
    required this.icon,
    required this.label,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 16,
      blur: 12,
      borderColor: borderColor,
      color: (glowColor ?? Colors.white.withValues(alpha: 0.04)),
      boxShadow: [
        BoxShadow(
          color: borderColor.withValues(alpha: 0.12),
          blurRadius: 16,
          spreadRadius: 0,
        ),
      ],
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppTheme.accentGold.withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Branded Google 'G' Icon ───────────────────────────────────────────

class _GoogleBrandIcon extends StatelessWidget {
  const _GoogleBrandIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [
            Color(0xFF4285F4), // Google Blue
            Color(0xFFDB4437), // Google Red
            Color(0xFFF4B400), // Google Yellow
            Color(0xFF0F9D58), // Google Green
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: Text(
          'G',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white, // masked by shader
          ),
        ),
      ),
    );
  }
}

// ── Fallback for missing stars_bg.png ─────────────────────────────────

Widget _fallbackStars(BuildContext context, Object exception, StackTrace? stackTrace) {
  return Container();
}
