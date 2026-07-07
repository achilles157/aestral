import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class GlassButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget label;
  final Widget? icon;
  final Color? glowColor;
  final double borderRadius;
  final double borderWidth;
  final EdgeInsetsGeometry padding;

  /// Whether the button is interactive. When false, the button is visually
  /// dimmed (40% opacity) and taps are ignored.
  final bool isEnabled;

  /// Optional semantic label for screen readers.
  /// If null, the label widget's text will be used by Flutter's default semantics.
  final String? semanticLabel;

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.glowColor,
    this.borderRadius = 16.0,
    this.borderWidth = 1.0,
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    this.isEnabled = true,
    this.semanticLabel,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.isEnabled,
      label: widget.semanticLabel,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeInOut,
        child: Opacity(
          opacity: widget.isEnabled ? 1.0 : 0.4,
          child: InkWell(
            onTap: widget.isEnabled ? widget.onPressed : null,
            onHighlightChanged: widget.isEnabled
                ? (highlighted) => setState(() => _pressed = highlighted)
                : null,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: GlassCard(
              borderRadius: widget.borderRadius,
              borderColor: (widget.glowColor ?? AppTheme.accentPurple)
                  .withValues(alpha: 0.35),
              borderWidth: widget.borderWidth,
              color: Colors.white.withValues(alpha: 0.04),
              padding: widget.padding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    ExcludeSemantics(child: widget.icon!),
                    const SizedBox(width: 8),
                  ],
                  DefaultTextStyle(
                    style: const TextStyle(
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    child: widget.label,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
