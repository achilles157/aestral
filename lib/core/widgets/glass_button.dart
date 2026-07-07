import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class GlassButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: isEnabled,
      label: semanticLabel,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.4,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(borderRadius),
          child: GlassCard(
            borderRadius: borderRadius,
            borderColor: (glowColor ?? AppTheme.accentPurple).withValues(alpha: 0.35),
            borderWidth: borderWidth,
            color: Colors.white.withValues(alpha: 0.04),
            padding: padding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  ExcludeSemantics(child: icon!),
                  const SizedBox(width: 8),
                ],
                DefaultTextStyle(
                  style: const TextStyle(
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  child: label,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
