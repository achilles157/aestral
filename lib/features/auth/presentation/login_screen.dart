import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final auth = ref.read(authProvider.notifier);
    
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
  }

  void _handleGuestSignIn() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    await ref.read(authProvider.notifier).signInAsGuest();
  }

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
                            const Spacer(flex: 3),
                            // Ornate App Logo
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    'A E S T R A L',
                                    style: textTheme.displayLarge?.copyWith(
                                      fontSize: 42,
                                      letterSpacing: 8,
                                      color: AppTheme.accentGold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Pintu Gerbang Takdir & Misteri Kosmis',
                                    style: textTheme.bodyLarge?.copyWith(
                                      letterSpacing: 1.5,
                                      color: AppTheme.textLight.withValues(alpha: 0.8),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(flex: 3),
                            // Login Options
                            if (_isLoading)
                              const Center(child: CircularProgressIndicator(color: AppTheme.accentPurple))
                            else ...[
                              // Google Sign-In Button
                              ElevatedButton.icon(
                                onPressed: _handleGoogleSignIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                icon: const Icon(Icons.g_mobiledata, size: 36, color: Colors.redAccent),
                                label: Text(
                                  'Masuk Dengan Google',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Guest Login Button
                              OutlinedButton.icon(
                                onPressed: _handleGuestSignIn,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppTheme.accentPurple, width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(Icons.person_outline, color: AppTheme.accentPurple),
                                label: Text(
                                  'Masuk Sebagai Tamu',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textLight,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(flex: 2),
                            // Zero budget note
                            Center(
                              child: Text(
                                'Zero-Budget High-Performance Architecture',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                  color: AppTheme.textMuted.withValues(alpha: 0.5),
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
              }
            ),
          ),
        ],
      ),
    );
  }
}

Widget _fallbackStars(BuildContext context, Object exception, StackTrace? stackTrace) {
  return Container();
}
