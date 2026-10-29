import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// StrandWise design tokens (requirement R1: pink, friendly, approachable —
/// soft palette, rounded components).
abstract final class AppColors {
  static const Color blush = Color(0xFFFFF5F7);
  static const Color rose = Color(0xFFFDE3EC);
  static const Color pink = Color(0xFFE8648F);
  static const Color deepPink = Color(0xFFC7517C);
  static const Color cream = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF3A1F2B);
  static const Color muted = Color(0xFF8F7280);
  static const Color border = Color(0x24F27BA5);
}

abstract final class AppTheme {
  static const double cornerRadius = 20;

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.pink,
      primary: AppColors.pink,
      onPrimary: Colors.white,
      secondary: AppColors.rose,
      surface: AppColors.cream,
      onSurface: AppColors.ink,
      brightness: Brightness.light,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.blush,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.blush,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cream,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.pink,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cream,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
          borderSide: BorderSide.none,
        ),
      ),
    );

    final body = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );
    final headline = GoogleFonts.fraunces(
      fontWeight: FontWeight.w500,
      letterSpacing: -0.5,
      color: AppColors.ink,
    );

    return base.copyWith(
      textTheme: body.copyWith(
        displayLarge: headline.copyWith(fontSize: 44),
        headlineLarge: headline.copyWith(fontSize: 32),
        headlineMedium: headline.copyWith(fontSize: 26),
        headlineSmall: headline.copyWith(fontSize: 24),
        titleLarge: headline.copyWith(fontSize: 20),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.rose,
        selectedColor: AppColors.pink,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
    );
  }
}
