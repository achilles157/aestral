import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../../features/auth/services/auth_service.dart';

/// Bottom sheet kosmis premium untuk memicu alur login/registrasi pengguna.
/// Menampilkan benefit registrasi dan tombol Google Sign-In yang berkilau.
class CosmicAuthBottomSheet extends ConsumerStatefulWidget {
  final String message;

  const CosmicAuthBottomSheet({
    super.key,
    this.message = 'Simpan riwayat obrolan orakel, sinkronisasikan planner harian, dan buka ramalan lengkap.',
  });

  /// Helper statis untuk menampilkan bottom sheet ini dari mana saja.
  static Future<bool?> show(BuildContext context, {String? message}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.70),
      builder: (context) => CosmicAuthBottomSheet(
        message: message ?? 'Simpan riwayat obrolan orakel, sinkronisasikan planner harian, dan buka ramalan lengkap.',
      ),
    );
  }

  @override
  ConsumerState<CosmicAuthBottomSheet> createState() => _CosmicAuthBottomSheetState();
}

class _CosmicAuthBottomSheetState extends ConsumerState<CosmicAuthBottomSheet>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final auth = ref.read(authProvider.notifier);

    try {
      if (auth.isFirebaseAvailable) {
        final success = await auth.signInWithGoogle();
        if (mounted) {
          setState(() => _isLoading = false);
          if (success) {
            Navigator.pop(context, true); // Login sukses
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Selamat datang di Aestral! Sinkronisasi kosmis berhasil.'),
                backgroundColor: AppTheme.accentPurple,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          _showNoFirebaseDialog();
        }
      }
    } catch (e) {
      debugPrint('CosmicAuthBottomSheet login error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan saat masuk. Silakan coba lagi.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showNoFirebaseDialog() {
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
          'Konfigurasi Firebase belum terdeteksi aktif pada perangkat lokal ini.\n\n'
          'Silakan selesaikan setup Firebase terlebih dahulu agar fitur login Google dapat digunakan secara online.',
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 32),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0B26).withValues(alpha: 0.88),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              offset: const Offset(0, -10),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 28),

            // Pulsing Cosmic Icon (Mandala)
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                final glow = _glowController.value;
                return Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentPurple.withValues(alpha: 0.15),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentPurple.withValues(alpha: 0.2 + glow * 0.2),
                        blurRadius: 16 + glow * 12,
                        spreadRadius: 2 + glow * 2,
                      )
                    ],
                    border: Border.all(
                      color: AppTheme.accentGold.withValues(alpha: 0.3 + glow * 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.auto_awesome,
                      color: AppTheme.accentGold,
                      size: 32,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Garis Takdir Kosmis Anda',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle / Message
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Google Login Button
            if (_isLoading)
              const CircularProgressIndicator(color: AppTheme.accentGold)
            else
              Semantics(
                button: true,
                label: 'Masuk dengan Google',
                child: InkWell(
                  onTap: _handleGoogleSignIn,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFE5C07B), // Emas
                          Color(0xFFBA8B32), // Emas Tua
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentGold.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Simulating a Google icon
                        const Icon(Icons.g_mobiledata_rounded, color: Colors.black87, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'Masuk dengan Google',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Mungkin Nanti',
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
