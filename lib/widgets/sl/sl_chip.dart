import 'package:flutter/material.dart';

import '../../core/theme/sl_tokens.dart';

/// A filter or tag chip. Selected chips are filled with the brand accent
/// (#60BB46) with dark text (6:1); others sit on the surface. 36px tall
/// inside a 44px touch area.
class SLChip extends StatelessWidget {
  const SLChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final sl = context.sl;
    final foreground = selected ? sl.onAccent : sl.ink;
    final radius = BorderRadius.circular(SLRadius.control);
    return Semantics(
      button: onTap != null,
      selected: selected,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: SLSpace.xs),
        child: Material(
          color: selected ? sl.accent : sl.surface,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 36),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: SLSpace.m),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: foreground),
                      const SizedBox(width: SLSpace.xs + 2),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.slType.small.copyWith(
                          color: foreground,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
