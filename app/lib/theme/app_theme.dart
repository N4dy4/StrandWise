import 'package:flutter/material.dart';

/// StrandWise design tokens (requirement R1: pink, friendly, approachable —
/// soft palette, rounded components).
abstract final class AppColors {
  static const Color blush = Color(0xFFFFF0F5); // soft background
  static const Color rose = Color(0xFFF8BBD0); // light accent
  static const Color pink = Color(0xFFF06292); // primary
  static const Color deepPink = Color(0xFFC2185B); // emphasis / pressed
  static const Color cream = Color(0xFFFFF8FA); // card surface
  static const Color ink = Color(0xFF4A2B3A); // warm dark text
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

    return ThemeData(
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
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius),
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
  }
}
