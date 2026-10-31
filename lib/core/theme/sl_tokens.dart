import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// ShareLoop design tokens ("Calm marketplace"): colour roles that differ
/// between the light and dark themes, plus the fixed spacing, radius, type
/// and motion scales. Screens read them with `context.sl`, `SLSpace`,
/// `SLRadius` and `context.slType`, never with raw values.
///
/// Rules the tokens encode:
/// - Surfaces are told apart by a small step in tone, not by lines or
///   shadows. Shadows are only for things that float (sheets, dialogs).
/// - [action] (deep green) fills primary buttons, with white text.
///   [accent] (#60BB46) marks selection, progress and highlights, and never
///   carries white text.
@immutable
class SLColors extends ThemeExtension<SLColors> {
  const SLColors({
    required this.ground,
    required this.surface,
    required this.surfaceMuted,
    required this.ink,
    required this.inkMuted,
    required this.divider,
    required this.action,
    required this.onAction,
    required this.accent,
    required this.onAccent,
    required this.accentText,
    required this.accentSoft,
    required this.danger,
  });

  /// Page background.
  final Color ground;

  /// Panels and cards.
  final Color surface;

  /// One tone step from [surface]: tracks, chips, placeholders.
  final Color surfaceMuted;
  final Color ink;
  final Color inkMuted;
  final Color divider;

  /// Primary button fill, and [onAction] on it.
  final Color action;
  final Color onAction;

  /// Selection, progress and highlight fills.
  final Color accent;

  /// Text and icons on [accent]: dark in both themes (6:1), never white.
  final Color onAccent;

  /// Green text and icons readable on [surface] and [ground].
  final Color accentText;

  /// Selected chip / soft highlight background.
  final Color accentSoft;
  final Color danger;

  static const SLColors light = SLColors(
    ground: AppColors.canvas,
    surface: AppColors.white,
    surfaceMuted: AppColors.mutedSurface,
    ink: AppColors.ink,
    inkMuted: AppColors.textSecondary,
    divider: AppColors.border,
    action: AppColors.deepGreen,
    onAction: AppColors.white,
    accent: AppColors.brightGreen,
    onAccent: AppColors.ink,
    accentText: AppColors.deepGreen,
    accentSoft: AppColors.paleMint,
    danger: AppColors.error,
  );

  static const SLColors dark = SLColors(
    ground: AppColors.darkGround,
    surface: AppColors.darkSurface,
    surfaceMuted: AppColors.darkSurfaceMuted,
    ink: AppColors.darkInk,
    inkMuted: AppColors.darkInkMuted,
    divider: AppColors.darkDivider,
    action: AppColors.deepGreen,
    onAction: AppColors.white,
    accent: AppColors.brightGreen,
    onAccent: AppColors.ink,
    accentText: AppColors.brightGreen,
    accentSoft: AppColors.darkAccentSoft,
    danger: AppColors.darkError,
  );

  @override
  SLColors copyWith({
    Color? ground,
    Color? surface,
    Color? surfaceMuted,
    Color? ink,
    Color? inkMuted,
    Color? divider,
    Color? action,
    Color? onAction,
    Color? accent,
    Color? onAccent,
    Color? accentText,
    Color? accentSoft,
    Color? danger,
  }) {
    return SLColors(
      ground: ground ?? this.ground,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      divider: divider ?? this.divider,
      action: action ?? this.action,
      onAction: onAction ?? this.onAction,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentText: accentText ?? this.accentText,
      accentSoft: accentSoft ?? this.accentSoft,
      danger: danger ?? this.danger,
    );
  }

  @override
  SLColors lerp(SLColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return SLColors(
      ground: mix(ground, other.ground),
      surface: mix(surface, other.surface),
      surfaceMuted: mix(surfaceMuted, other.surfaceMuted),
      ink: mix(ink, other.ink),
      inkMuted: mix(inkMuted, other.inkMuted),
      divider: mix(divider, other.divider),
      action: mix(action, other.action),
      onAction: mix(onAction, other.onAction),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      accentText: mix(accentText, other.accentText),
      accentSoft: mix(accentSoft, other.accentSoft),
      danger: mix(danger, other.danger),
    );
  }
}

/// 4-point spacing scale. Screens use a 20px side margin, 24 between
/// sections and 12 inside them.
class SLSpace {
  SLSpace._();

  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Left and right page margin.
  static const double screen = 20;

  /// Gap between sections of a screen.
  static const double section = 24;
}

/// The three corner radii. Buttons are fully round (StadiumBorder).
class SLRadius {
  SLRadius._();

  /// Inputs, chips and small controls.
  static const double control = 12;

  /// Cards and panels.
  static const double card = 16;

  /// Bottom sheets and dialogs.
  static const double sheet = 24;
}

/// The five type sizes, in Inter (with the Sinhala and Tamil fallbacks the
/// theme sets). One large title per screen; most text is [body] or [small].
@immutable
class SLType {
  const SLType._(this._base, this._colors);

  final TextStyle _base;
  final SLColors _colors;

  /// Screen title: 28, bold.
  TextStyle get title => _base.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.5,
    color: _colors.ink,
  );

  /// Section title: 20, semibold.
  TextStyle get section => _base.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.2,
    color: _colors.ink,
  );

  /// Card and row title: 16, semibold.
  TextStyle get cardTitle => _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: _colors.ink,
  );

  /// Body: 15, regular.
  TextStyle get body => _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: _colors.ink,
  );

  /// Meta, captions and labels: 13, regular.
  TextStyle get small => _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: _colors.inkMuted,
  );
}

/// Motion rules: short, purposeful, and off when the user asks the system
/// to reduce motion.
class SLMotion {
  SLMotion._();

  static const Duration press = Duration(milliseconds: 120);
  static const Duration enter = Duration(milliseconds: 280);

  /// Delay between items that enter one after another.
  static const Duration stagger = Duration(milliseconds: 60);

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

extension SLContext on BuildContext {
  /// The current theme's colour roles (light values if a theme lacks them).
  SLColors get sl => Theme.of(this).extension<SLColors>() ?? SLColors.light;

  SLType get slType =>
      SLType._(Theme.of(this).textTheme.bodyLarge ?? const TextStyle(), sl);
}
