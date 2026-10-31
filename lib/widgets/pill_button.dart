import 'package:flutter/material.dart';

import '../core/theme/sl_tokens.dart';

/// Full-width deep-green pill button with a soft shadow, used for the main
/// action pinned at the bottom of a screen. Shows a spinner while
/// [isLoading].
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  /// Green outline on white, for a secondary action. No shadow.
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final sl = context.sl;
    final style = ElevatedButton.styleFrom(
      backgroundColor: outlined ? sl.surface : sl.action,
      foregroundColor: outlined ? sl.accentText : sl.onAction,
      disabledBackgroundColor: sl.action.withValues(alpha: 0.6),
      disabledForegroundColor: sl.onAction,
      elevation: 0,
      minimumSize: const Size.fromHeight(54),
      shape: StadiumBorder(
        side: outlined
            ? BorderSide(color: sl.accentText, width: 1.5)
            : BorderSide.none,
      ),
      textStyle: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    );
    final onTap = isLoading ? null : onPressed;
    final Widget button;
    if (isLoading) {
      button = ElevatedButton(
        onPressed: null,
        style: style,
        child: SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: sl.onAction),
        ),
      );
    } else if (icon case final icon?) {
      button = ElevatedButton.icon(
        onPressed: onTap,
        style: style,
        icon: Icon(icon),
        label: Text(label),
      );
    } else {
      button = ElevatedButton(
        onPressed: onTap,
        style: style,
        child: Text(label),
      );
    }
    if (outlined) return button;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: sl.action.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: button,
    );
  }
}

/// White bar pinned to the bottom of a screen, holding its main action(s).
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.sl.surface,
        border: Border(top: BorderSide(color: context.sl.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
