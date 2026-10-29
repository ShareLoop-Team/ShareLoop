import 'package:flutter/material.dart';

/// Brand color palette. All colors used in the app must come from here —
/// no hard-coded [Color] values elsewhere.
class AppColors {
  AppColors._();

  static const Color brightGreen = Color(0xFF60BB46);
  static const Color deepGreen = Color(0xFF0F843D);
  static const Color softMint = Color(0xFFBCE2B3);
  static const Color canvas = Color(0xFFF7FAF6);
  // Background baked into the intro illustrations, so they blend seamlessly.
  static const Color introBackground = Color(0xFFF4F9F3);
  static const Color ink = Color(0xFF173126);
  static const Color amber = Color(0xFFD99B27);
  static const Color error = Color(0xFFC74747);
  static const Color white = Color(0xFFFFFFFF);
  // Full-screen photo viewer background.
  static const Color black = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF6B7A72);
  static const Color border = Color(0xFFE1E8E2);
  static const Color mutedSurface = Color(0xFFE9EEEA);
  static const Color paleMint = Color(0xFFE3F2DD);
  static const Color silver = Color(0xFFA3A8A6);
  static const Color bronze = Color(0xFFB9805A);
}
