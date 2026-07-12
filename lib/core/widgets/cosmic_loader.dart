import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Mystical pulsing loader — pengganti on-brand untuk [CircularProgressIndicator].
///
/// Menghormati [MediaQuery.disableAnimations]: saat reduced motion aktif,
/// tampilkan ikon statis tanpa animasi.
class CosmicLoader extends StatefulWidget {
  final Color color;
  final double size;
  final String? label;

  const CosmicLoader({
    super.key,
    this.color = AppTheme.accentGold,
    this.size = 64.0,
    this.label,
  });

  @override
  State<CosmicLoader> createState() => _CosmicLoaderState();
}

class _CosmicLoaderState extends State<CosmicLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final s = widget.size;

    Widget icon = Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.color.withValues(alpha: 0.10),
        border: Border.all(
          color: widget.color.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: reduceMotion
            ? null
            : [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.20),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ],
      ),
      child: Icon(
        Icons.auto_awesome,
        color: widget.color.withValues(alpha: 0.75),
        size: s * 0.40,
      ),
    );

    if (!reduceMotion) {
      icon = AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) => Transform.scale(
          scale: _pulse.value,
          child: Container(
            width: s,
            height: s,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: 0.10),
              border: Border.all(
                color: widget.color.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.25 * _pulse.value),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(
              Icons.auto_awesome,
              color: widget.color.withValues(alpha: 0.75),
              size: s * 0.40,
            ),
          ),
        ),
      );
    }

    if (widget.label == null) return icon;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(height: 16),
        Text(
          widget.label!,
          style: TextStyle(
            color: Colors.white60,
            fontSize: 13,
            fontFamily: 'Outfit',
          ),
        ),
      ],
    );
  }
}
