import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The app's type scale. Inter is the primary font; it has no Sinhala
/// glyphs, so Flutter falls back to Noto Sans Sinhala character by
/// character, letting mixed English/Sinhala text render correctly. Both are
/// bundled (pubspec.yaml), so nothing is downloaded at runtime.
///
/// Sizes are logical pixels (Flutter's sp) and scale with the device's text
/// size setting. Screens pick a role from `Theme.of(context).textTheme`:
///
/// | Role              | Style          | Size | Weight |
/// |-------------------|----------------|------|--------|
/// | Main heading      | headlineSmall  | 26   | 700    |
/// | Section heading   | titleLarge     | 20   | 600    |
/// | Card title        | titleMedium    | 16   | 600    |
/// | Small title       | titleSmall     | 14   | 600    |
/// | Body              | bodyLarge/Med. | 16/14| 400    |
/// | Caption           | bodySmall      | 12   | 400    |
/// | Button            | labelLarge     | 14   | 600    |
/// | Navigation label  | labelMedium    | 12   | 500    |
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Inter';

  /// Used for any character Inter can't draw.
  static const List<String> fontFamilyFallback = ['NotoSansSinhala'];

  static TextTheme textTheme(Color color) {
    TextStyle style(
      double size,
      FontWeight weight,
      double height, {
      double letterSpacing = 0,
    }) {
      return TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );
    }

    return TextTheme(
      displayLarge: style(57, FontWeight.w700, 1.12, letterSpacing: -0.5),
      displayMedium: style(45, FontWeight.w700, 1.16, letterSpacing: -0.4),
      displaySmall: style(36, FontWeight.w700, 1.22, letterSpacing: -0.3),
      headlineLarge: style(32, FontWeight.w700, 1.25, letterSpacing: -0.3),
      headlineMedium: style(28, FontWeight.w700, 1.29, letterSpacing: -0.2),
      headlineSmall: style(26, FontWeight.w700, 1.25, letterSpacing: -0.2),
      titleLarge: style(20, FontWeight.w600, 1.3),
      titleMedium: style(16, FontWeight.w600, 1.5),
      titleSmall: style(14, FontWeight.w600, 1.43),
      bodyLarge: style(16, FontWeight.w400, 1.5),
      bodyMedium: style(14, FontWeight.w400, 1.43),
      bodySmall: style(12, FontWeight.w400, 1.33),
      labelLarge: style(14, FontWeight.w600, 1.43, letterSpacing: 0.1),
      labelMedium: style(12, FontWeight.w500, 1.33, letterSpacing: 0.2),
      labelSmall: style(11, FontWeight.w500, 1.45, letterSpacing: 0.3),
    );
  }

  /// Adds the bundled fonts' SIL Open Font Licences to the app's licence
  /// page, as the licence requires when redistributing them.
  static void registerLicenses() {
    LicenseRegistry.addLicense(() async* {
      for (final (name, file) in const [
        ('Inter', 'Inter-OFL.txt'),
        ('Noto Sans Sinhala', 'NotoSansSinhala-OFL.txt'),
      ]) {
        yield LicenseEntryWithLineBreaks(
          [name],
          await rootBundle.loadString('assets/fonts/$file'),
        );
      }
    });
  }
}
