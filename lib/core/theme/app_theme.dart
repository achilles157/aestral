import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Colors ───────────────────────────────────────────────────────────────
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
  static const Color error = Color(0xFFF87171);
  static const Color warning = Color(0xFFFB923C);
  static const Color info = Color(0xFF60A5FA);

  // ─── Border Radii ────────────────────────────────────────────────────────
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;

  // ─── Type Scale ───────────────────────────────────────────────────────────
  /// Playfair Display — display heading (32)
  static const double fontDisplay = 32.0;

  /// Playfair Display — section heading (24)
  static const double fontTitleLarge = 24.0;

  /// Outfit — sub-heading (20)
  static const double fontTitleMedium = 20.0;

  /// Outfit — primary body copy (16)
  static const double fontBodyLarge = 16.0;

  /// Outfit — secondary body copy (14)
  static const double fontBodyMedium = 14.0;

  /// Outfit — caption / supporting text (12)
  static const double fontBodySmall = 12.0;

  /// Outfit — chip / tag / overline (11)
  static const double fontLabel = 11.0;

  // ─── Gradient Tokens ──────────────────────────────────────────────────────
  /// Deep background gradient — scaffold overlay
  static const LinearGradient cosmicGradient = LinearGradient(
    colors: [background, cardBg],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Gold → Purple diagonal — CTA cards, feature highlights
  static const LinearGradient goldToPurpleGradient = LinearGradient(
    colors: [accentGold, accentPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Purple → transparent — upsell cards, banners
  static const LinearGradient purpleFadeGradient = LinearGradient(
    colors: [Color(0x1F8B5CF6), Color(0x0FFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Card inner gradient — subtle depth on glass cards
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1F1940), Color(0xFF0F0B21)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Theme ────────────────────────────────────────────────────────────────
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
          side: const BorderSide(color: Color(0xFF2E2452), width: 1.5),
        ),
      ),
      textTheme: TextTheme(
        // Playfair Display — display heading
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: fontDisplay,
          fontWeight: FontWeight.bold,
          color: textLight,
          letterSpacing: 0.5,
          height: 1.2,
        ),
        // Playfair Display — section heading
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: fontTitleLarge,
          fontWeight: FontWeight.bold,
          color: accentGold,
          letterSpacing: 0.5,
          height: 1.3,
        ),
        // Outfit — sub-heading
        titleLarge: GoogleFonts.outfit(
          fontSize: fontTitleMedium,
          fontWeight: FontWeight.w600,
          color: textLight,
          height: 1.3,
        ),
        // Outfit — card title / form label heading
        titleMedium: GoogleFonts.outfit(
          fontSize: fontBodyLarge,
          fontWeight: FontWeight.w600,
          color: textLight,
          height: 1.4,
        ),
        // Outfit — primary body (AI oracle, descriptions)
        bodyLarge: GoogleFonts.outfit(
          fontSize: fontBodyLarge,
          fontWeight: FontWeight.normal,
          color: textLight,
          height: 1.7, // breathing room for long mystical text
        ),
        // Outfit — secondary body (subtitles, supporting copy)
        bodyMedium: GoogleFonts.outfit(
          fontSize: fontBodyMedium,
          fontWeight: FontWeight.normal,
          color: textMuted,
          height: 1.6,
        ),
        // Outfit — caption / supporting text
        bodySmall: GoogleFonts.outfit(
          fontSize: fontBodySmall,
          fontWeight: FontWeight.normal,
          color: textMuted,
          height: 1.5,
        ),
        // Outfit — bold action label
        labelLarge: GoogleFonts.outfit(
          fontSize: fontBodyMedium,
          fontWeight: FontWeight.bold,
          color: textLight,
          letterSpacing: 0.3,
        ),
        // Outfit — chip / tag / overline
        labelSmall: GoogleFonts.outfit(
          fontSize: fontLabel,
          fontWeight: FontWeight.w500,
          color: textMuted,
          letterSpacing: 0.5,
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
            fontSize: fontBodyLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background.withValues(alpha: 0.5),
        labelStyle: GoogleFonts.outfit(color: textMuted),
        hintStyle: GoogleFonts.outfit(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
