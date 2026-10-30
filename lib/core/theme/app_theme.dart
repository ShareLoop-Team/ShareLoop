import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'app_typography.dart';
import 'sl_tokens.dart';

/// App-wide Material 3 theme definitions. Pure presentation configuration —
/// no business logic belongs here. Both themes carry the [SLColors] tokens,
/// which redesigned screens read through `context.sl`.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.deepGreen,
      brightness: Brightness.light,
      primary: AppColors.deepGreen,
      secondary: AppColors.brightGreen,
      tertiary: AppColors.softMint,
      // Sheets, menus and pickers stay white; only the page behind them
      // (scaffoldBackgroundColor) is green-tinted.
      surface: AppColors.white,
      error: AppColors.error,
      onPrimary: AppColors.white,
      onSurface: AppColors.ink,
      onError: AppColors.white,
    );
    return _build(
      colorScheme: colorScheme,
      tokens: SLColors.light,
      appBarBackground: AppColors.deepGreen,
      appBarForeground: AppColors.white,
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.deepGreen,
      brightness: Brightness.dark,
      primary: AppColors.brightGreen,
      onPrimary: AppColors.darkGround,
      secondary: AppColors.brightGreen,
      tertiary: AppColors.softMint,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkInk,
      onSurfaceVariant: AppColors.darkInkMuted,
      outline: AppColors.darkInkMuted,
      outlineVariant: AppColors.darkDivider,
      error: AppColors.darkError,
      onError: AppColors.darkGround,
    );
    return _build(
      colorScheme: colorScheme,
      tokens: SLColors.dark,
      appBarBackground: AppColors.darkSurface,
      appBarForeground: AppColors.darkInk,
    );
  }

  static ThemeData _build({
    required ColorScheme colorScheme,
    required SLColors tokens,
    required Color appBarBackground,
    required Color appBarForeground,
  }) {
    final textTheme = AppTypography.textTheme(tokens.ink);
    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.ground,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      textTheme: textTheme,
      extensions: [tokens],
      dividerTheme: DividerThemeData(color: tokens.divider, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackground,
        foregroundColor: appBarForeground,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.action,
          foregroundColor: tokens.onAction,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SLRadius.control),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SLRadius.control),
        ),
        filled: true,
        // Fields sit one tone above the page.
        fillColor: tokens.surface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SLRadius.card),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(SLRadius.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SLRadius.sheet),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      // The home shell's bottom bar: the selected tab is a soft green pill
      // with green icon and label; others are grey.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: tokens.accentSoft,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? tokens.accentText
                : tokens.inkMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? tokens.accentText
                : tokens.inkMuted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: tokens.accentText,
        unselectedItemColor: tokens.inkMuted,
        backgroundColor: tokens.surface,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
