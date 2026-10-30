import 'package:flutter/material.dart';

/// Brand color palette. All colors used in the app must come from here —
/// no hard-coded [Color] values elsewhere.
class AppColors {
  AppColors._();

  static const Color brightGreen = Color(0xFF60BB46);
  static const Color deepGreen = Color(0xFF0F843D);
  static const Color softMint = Color(0xFFBCE2B3);
  // Main screen background: a soft green-tinted off-white, so the white
  // cards and fields on top of it stand out.
  static const Color canvas = Color(0xFFF0F6EC);
  // Background baked into the intro illustrations, so they blend seamlessly.
  static const Color introBackground = Color(0xFFF4F9F3);
  // Background baked into the registration illustration.
  static const Color registerHeroBackground = Color(0xFFEEF4E6);
  // Primary text: neutral near-black.
  static const Color ink = Color(0xFF1F2937);
  static const Color amber = Color(0xFFD99B27);
  static const Color error = Color(0xFFC74747);
  static const Color white = Color(0xFFFFFFFF);
  // Full-screen photo viewer background.
  static const Color black = Color(0xFF000000);
  // Secondary text: neutral grey.
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE1E8E2);
  // Secondary surface: progress tracks, toggles, chips, locked fields.
  static const Color mutedSurface = Color(0xFFE8F1E3);
  static const Color paleMint = Color(0xFFE3F2DD);
  static const Color silver = Color(0xFFA3A8A6);
  static const Color bronze = Color(0xFFB9805A);
  // A cool grey that stays visible on light and dark surfaces.
  static const Color platinum = Color(0xFF7D8A96);

  // Dark theme: a near-black ground with a faint green cast, lighter
  // surfaces stepped up from it, and light neutral text.
  static const Color darkGround = Color(0xFF0E1210);
  static const Color darkSurface = Color(0xFF171C19);
  static const Color darkSurfaceMuted = Color(0xFF212823);
  static const Color darkInk = Color(0xFFF2F4F3);
  static const Color darkInkMuted = Color(0xFFA3ADA7);
  static const Color darkDivider = Color(0xFF2A322D);
  static const Color darkAccentSoft = Color(0xFF1D3122);
  static const Color darkError = Color(0xFFE57373);
}
