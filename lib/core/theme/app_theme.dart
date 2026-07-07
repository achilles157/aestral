import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF0F0B21);
  static const Color cardBg = Color(0xFF1B1535);
  static const Color accentPink = Color(0xFFE87EA1);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentGold = Color(0xFFFBBF24);
  static const Color textLight = Color(0xFFF3F4F6);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color shadowColor = Color(0x3F000000);

  // Astrological Element Colors
  static const Color elementWater = Color(0xFF60A5FA);
  static const Color elementFire = Color(0xFFF87171);
  static const Color elementEarth = accentGold;
  static const Color elementMetal = Color(0xFFE5E7EB);
  static const Color elementCosmic = Color(0xFFC084FC);

  // Semantic State Colors — gunakan token ini, hindari hardcode di widget
  static const Color success = Color(0xFF10B981);
  static const Color error   = Color(0xFFF87171);
  static const Color warning = Color(0xFFFB923C);
  static const Color info    = Color(0xFF60A5FA);

  // Standard Border Radii
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;

  static ThemeData get darkTheme {
    final baseTheme = ThemeData.dark();
    return baseTheme.copyWith(
      scaffoldBackgroundColor: background,
      primaryColor: accentPurple,
      colorScheme: const ColorScheme.dark(
        primary: accentPurple,
        secondary: accentPink,
        surface: cardBg,
        onPrimary: textLight,
        onSecondary: textLight,
        onSurface: textLight,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: Color(0xFF2E2452),
            width: 1.5,
          ),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textLight,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: accentGold,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textLight,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textLight,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textMuted,
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: textLight,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPurple,
          foregroundColor: textLight,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background.withValues(alpha: 0.5),
        labelStyle: GoogleFonts.outfit(color: textMuted),
        hintStyle: GoogleFonts.outfit(color: textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accentPurple.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accentPurple.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentGold, width: 1.5),
        ),
      ),
    );
  }
}
