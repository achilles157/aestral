import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Gradient? gradient;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20.0,
    this.blur = 10.0,
    this.color,
    this.gradient,
    this.borderColor,
    this.borderWidth = 1.0,
    this.boxShadow,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBorderColor = Colors.white.withValues(alpha: 0.12);
    final shouldBlur = !MediaQuery.of(context).disableAnimations;

    final innerDecoration = BoxDecoration(
      color: gradient != null
          ? null
          : (color ?? Colors.white.withValues(alpha: shouldBlur ? 0.05 : 0.09)),
      gradient: gradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? defaultBorderColor,
        width: borderWidth,
      ),
    );

    final inner = Container(
      padding: padding,
      decoration: innerDecoration,
      child: child,
    );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: shouldBlur
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: inner,
              )
            : inner,
      ),
    );
  }
}
