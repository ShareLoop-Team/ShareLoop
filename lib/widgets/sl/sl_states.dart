import 'package:flutter/material.dart';

import '../../core/theme/sl_tokens.dart';
import 'sl_button.dart';

/// Nothing to show (no data yet, or the filters match nothing): one short
/// sentence and, optionally, the next action. No illustration.
class SLEmptyState extends StatelessWidget {
  const SLEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final sl = context.sl;
    final label = actionLabel;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SLSpace.screen,
        vertical: SLSpace.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: sl.inkMuted),
          const SizedBox(height: SLSpace.m),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.slType.body.copyWith(color: sl.inkMuted),
          ),
          if (label != null && onAction != null) ...[
            const SizedBox(height: SLSpace.l),
            SLButton(
              label: label,
              onPressed: onAction,
              variant: SLButtonVariant.secondary,
            ),
          ],
        ],
      ),
    );
  }
}

/// A block failed to load: says so where the content would be, with Retry.
class SLErrorState extends StatelessWidget {
  const SLErrorState({
    super.key,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SLEmptyState(
      message: message,
      icon: Icons.cloud_off_outlined,
      actionLabel: retryLabel,
      onAction: onRetry,
    );
  }
}

/// A flat placeholder block at the real size of what is loading. No
/// shimmer, so the layout doesn't move when the content arrives.
class SLSkeleton extends StatelessWidget {
  const SLSkeleton({super.key, this.width, this.height = 14, this.radius = 6});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.sl.surfaceMuted,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
