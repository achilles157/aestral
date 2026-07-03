import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class GlassButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget label;
  final Widget? icon;
  final Color? glowColor;
  final double borderRadius;
  final double borderWidth;
  final EdgeInsetsGeometry padding;

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.glowColor,
    this.borderRadius = 16.0,
    this.borderWidth = 1.0,
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
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
              icon!,
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
    );
  }
}
