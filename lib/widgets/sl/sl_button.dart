import 'package:flutter/material.dart';

import '../../core/theme/sl_tokens.dart';
import 'sl_motion.dart';

enum SLButtonVariant {
  /// Deep green fill, white label: the one main action of a screen.
  primary,

  /// Surface fill with a hairline edge.
  secondary,

  /// Green label only.
  text,

  /// Red label on a surface: destructive actions.
  danger,
}

/// The app's button: fully round, flat, 48px tall (a 44px+ touch target),
/// with a light press shrink. [expand] makes it fill the width.
class SLButton extends StatelessWidget {
  const SLButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = SLButtonVariant.primary,
    this.icon,
    this.expand = false,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final SLButtonVariant variant;
  final IconData? icon;
  final bool expand;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final sl = context.sl;
    final type = context.slType;
    final (
      Color background,
      Color foreground,
      BorderSide? side,
    ) = switch (variant) {
      SLButtonVariant.primary => (sl.action, sl.onAction, null),
      SLButtonVariant.secondary => (
        sl.surface,
        sl.ink,
        BorderSide(color: sl.divider),
      ),
      SLButtonVariant.text => (Colors.transparent, sl.accentText, null),
      SLButtonVariant.danger => (
        sl.surface,
        sl.danger,
        BorderSide(color: sl.divider),
      ),
    };
    final disabled = onPressed == null || isLoading;
    final child = isLoading
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: foreground,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: SLSpace.s),
              ],
              // Two lines rather than a cut-off word in long translations.
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );

    final button = TextButton(
      onPressed: disabled ? null : onPressed,
      style: TextButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: variant == SLButtonVariant.text
            ? Colors.transparent
            : sl.surfaceMuted,
        disabledForegroundColor: isLoading ? foreground : sl.inkMuted,
        minimumSize: Size(expand ? double.infinity : 0, 48),
        padding: const EdgeInsets.symmetric(
          horizontal: SLSpace.xl,
          vertical: SLSpace.s,
        ),
        shape: StadiumBorder(side: side ?? BorderSide.none),
        textStyle: type.cardTitle,
        elevation: 0,
      ),
      child: child,
    );
    return SLPressScale(enabled: !disabled, child: button);
  }
}
