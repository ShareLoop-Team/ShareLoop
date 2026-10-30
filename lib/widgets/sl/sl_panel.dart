import 'package:flutter/material.dart';

import '../../core/theme/sl_tokens.dart';
import '../app_icon.dart';

/// A section title, optionally with something on the right (a filter chip,
/// "View all"). The title keeps to one line.
class SLSectionHeader extends StatelessWidget {
  const SLSectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    // The title keeps priority: [trailing] may use at most 45% of the row.
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.slType.section,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: SLSpace.m),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * 0.45,
              ),
              child: trailing!,
            ),
          ],
        ],
      ),
    );
  }
}

/// A flat surface panel: one tone above the page, rounded, no shadow.
/// [children] are stacked with hairline dividers between them; use
/// [padding] for panels that hold free content instead of rows.
class SLPanel extends StatelessWidget {
  const SLPanel({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
    this.dividerIndent = 0,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  /// Start inset of the dividers, e.g. to line up with row labels.
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    final sl = context.sl;
    return Material(
      color: sl.surface,
      borderRadius: BorderRadius.circular(SLRadius.card),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: dividerIndent,
                  color: sl.divider,
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// One row of an [SLPanel]: an outline icon, a label, an optional value,
/// and a chevron when it opens something. [destructive] colours the icon
/// and label red (e.g. Sign Out). At least 52px tall.
class SLListRow extends StatelessWidget {
  const SLListRow({
    super.key,
    required this.label,
    this.icon,
    this.value,
    this.onTap,
    this.destructive = false,
    this.showChevron = true,
  });

  /// Indent for panel dividers so they start under the label.
  static const double labelInset = SLSpace.l + 24 + SLSpace.m;

  final String label;

  /// An [Icon] or [AppIcon]; sized and coloured by the row.
  final Widget? icon;
  final String? value;
  final VoidCallback? onTap;
  final bool destructive;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final sl = context.sl;
    final type = context.slType;
    final labelColor = destructive ? sl.danger : sl.ink;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SLSpace.l,
            vertical: SLSpace.m,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                IconTheme(
                  data: IconThemeData(
                    size: 22,
                    color: destructive ? sl.danger : sl.inkMuted,
                  ),
                  child: icon!,
                ),
                const SizedBox(width: SLSpace.m),
              ],
              Expanded(
                child: Text(
                  label,
                  style: type.body.copyWith(
                    color: labelColor,
                    fontWeight: destructive ? FontWeight.w600 : null,
                  ),
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: SLSpace.s),
                // Capped so the label keeps the spare width.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: type.small,
                  ),
                ),
              ],
              if (onTap != null && showChevron) ...[
                const SizedBox(width: SLSpace.xs),
                const RowChevron(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
