import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// App-wide Material 3 theme definitions. Pure presentation configuration —
/// no business logic belongs here.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.deepGreen,
      brightness: Brightness.light,
      primary: AppColors.deepGreen,
      secondary: AppColors.brightGreen,
      tertiary: AppColors.softMint,
      surface: AppColors.canvas,
      error: AppColors.error,
      onPrimary: AppColors.white,
      onSurface: AppColors.ink,
      onError: AppColors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvas,
      textTheme: ThemeData.light().textTheme.apply(
            bodyColor: AppColors.ink,
            displayColor: AppColors.ink,
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.deepGreen,
        foregroundColor: AppColors.white,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepGreen,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppColors.softMint.withValues(alpha: 0.3),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: AppColors.deepGreen,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: AppColors.white,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.deepGreen,
      brightness: Brightness.dark,
      primary: AppColors.brightGreen,
      secondary: AppColors.softMint,
      error: AppColors.error,
      onPrimary: AppColors.ink,
      onError: AppColors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.ink,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.white,
        centerTitle: true,
        elevation: 0,
      ),
    );
  }
}
