import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// Cosmic typing indicator untuk Oracle Chat.
/// Menampilkan tiga titik berdenyut sebagai indikasi bahwa AI sedang mengetik.
///
/// Dipakai di [OracleChatScreen] saat `isStreaming` true.
class CosmicTypingIndicator extends StatefulWidget {
  const CosmicTypingIndicator({super.key, this.accentColor, this.label});

  /// Warna aksen titik — default ke AppTheme.accentGold
  final Color? accentColor;

  /// Label opsional di samping titik (default "Mengetik...")
  final String? label;

  @override
  State<CosmicTypingIndicator> createState() => _CosmicTypingIndicatorState();
}

class _CosmicTypingIndicatorState extends State<CosmicTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accentColor ?? AppTheme.accentGold;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 260),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Dot(controller: _controller, delay: 0, color: color),
              const SizedBox(width: 5),
              _Dot(controller: _controller, delay: 200, color: color),
              const SizedBox(width: 5),
              _Dot(controller: _controller, delay: 400, color: color),
              if (widget.label != null || true) ...[
                const SizedBox(width: 10),
                Text(
                  widget.label ?? 'Mengetik...',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: color.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.controller,
    required this.delay,
    required this.color,
  });

  final AnimationController controller;
  final int delay;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = (controller.value * 1000);
        final phase = ((t + delay) % 1000) / 1000;
        // S-curve opacity: low → peak → low
        final opacity = phase < 0.5 ? phase * 2 * 0.7 : (1 - phase) * 2 * 0.7;
        final scale = 0.6 + opacity * 0.6;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.3 + opacity),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
