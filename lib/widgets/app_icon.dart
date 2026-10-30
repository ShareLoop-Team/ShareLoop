import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/constants/app_colors.dart';

/// The app's custom glyphs, drawn as 2px rounded-stroke SVGs in
/// `assets/icons/`.
enum AppGlyph {
  // Bottom navigation.
  home,
  give,
  requests,
  profile,

  // Profile settings.
  language,
  notifications,

  // "Opens a page" arrow at the end of list rows and cards.
  chevron,

  // Edit your own post (item details).
  edit;

  String get asset => 'assets/icons/$name.svg';
}

/// One custom icon. Takes its colour and size from the ambient [IconTheme],
/// so it behaves like a regular [Icon] (e.g. it follows a navigation bar's
/// selected / unselected styling).
class AppIcon extends StatelessWidget {
  const AppIcon(this.glyph, {super.key});

  final AppGlyph glyph;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final size = iconTheme.size ?? 24;
    final color = iconTheme.color;
    return SvgPicture.asset(
      glyph.asset,
      width: size,
      height: size,
      colorFilter:
          color == null ? null : ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

/// The grey arrow at the end of a row or card that opens another page.
class RowChevron extends StatelessWidget {
  const RowChevron({super.key});

  @override
  Widget build(BuildContext context) {
    return const IconTheme(
      data: IconThemeData(size: 20, color: AppColors.textSecondary),
      child: AppIcon(AppGlyph.chevron),
    );
  }
}
