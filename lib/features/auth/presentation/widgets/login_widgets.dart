import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../home/presentation/widgets/starry_background.dart';

// ── Rotating Mandala (60s cycle) ──────────────────────────────────────

class LoginRotatingMandala extends StatefulWidget {
  final double size;
  const LoginRotatingMandala({required this.size});

  @override
  State<LoginRotatingMandala> createState() => _LoginRotatingMandalaState();
}

class _LoginRotatingMandalaState extends State<LoginRotatingMandala>
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

class LoginGlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color borderColor;
  final Color? glowColor;
  final Widget icon;
  final String label;

  const LoginGlassButton({
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

class LoginGoogleBrandIcon extends StatelessWidget {
  const LoginGoogleBrandIcon();

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
