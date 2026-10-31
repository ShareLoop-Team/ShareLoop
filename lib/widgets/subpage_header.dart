import 'package:flutter/material.dart';

import '../core/theme/sl_tokens.dart';

/// White circular back button with a light border.
class CircleBackButton extends StatelessWidget {
  const CircleBackButton({super.key, this.onPressed});

  /// Defaults to popping the current route.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final sl = context.sl;
    return IconButton(
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: sl.surface,
        foregroundColor: sl.ink,
        fixedSize: const Size.square(44),
        side: BorderSide(color: sl.divider),
      ),
    );
  }
}

/// Back button beside a bold page title and an optional grey subtitle, for
/// pages opened from another screen (no app bar).
class SubpageHeader extends StatelessWidget {
  const SubpageHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sl = context.sl;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleBackButton(),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: textTheme.headlineSmall?.copyWith(
                    color: sl.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: textTheme.bodyMedium?.copyWith(color: sl.inkMuted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
