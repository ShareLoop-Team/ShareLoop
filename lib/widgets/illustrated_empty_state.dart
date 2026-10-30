import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme/sl_tokens.dart';

/// Friendly empty state: a round illustration, a bold title, a short
/// explanation and an optional card below (a tip, progress, next step).
class IllustratedEmptyState extends StatelessWidget {
  const IllustratedEmptyState({
    super.key,
    required this.illustration,
    required this.title,
    required this.message,
    this.footer,
  });

  /// SVG asset path.
  final String illustration;
  final String title;
  final String message;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sl = context.sl;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: SvgPicture.asset(illustration, width: 144, height: 144),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            color: sl.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(color: sl.inkMuted, height: 1.5),
        ),
        if (footer != null) ...[const SizedBox(height: 20), footer!],
      ],
    );
  }
}

/// White rounded card with a soft shadow, for content on the canvas.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final sl = context.sl;
    final radius = BorderRadius.circular(20);
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius),
      child: Material(
        color: sl.surface,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
