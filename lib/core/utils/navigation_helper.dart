import 'package:flutter/material.dart';

/// Creates a custom page route with a cosmic themed transition.
/// It combines a smooth FadeTransition and a subtle ScaleTransition (0.96 -> 1.0)
/// over a 600ms duration.
PageRouteBuilder<T> createCosmicPageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 600),
    reverseTransitionDuration: const Duration(milliseconds: 500),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeTween = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));

      final scaleTween = Tween<double>(begin: 0.96, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
        ),
      );

      return FadeTransition(
        opacity: fadeTween,
        child: ScaleTransition(scale: scaleTween, child: child),
      );
    },
  );
}
