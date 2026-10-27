import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

/// Reusable selectable pill for category filters/selection.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.deepGreen : AppColors.white,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.deepGreen : AppColors.softMint,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: selected ? AppColors.white : AppColors.ink,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontally scrolling "All" + one [CategoryChip] per category.
/// [selected] is null when "All" is chosen.
class CategoryChipsRow extends StatelessWidget {
  const CategoryChipsRow({
    super.key,
    required this.allLabel,
    required this.selected,
    required this.onSelected,
  });

  final String allLabel;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final chips = <(String, String?)>[
      (allLabel, null),
      for (final category in AppConstants.itemCategories) (category, category),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (final (label, value) in chips)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CategoryChip(
                label: label,
                selected: selected == value,
                onTap: () => onSelected(value),
              ),
            ),
        ],
      ),
    );
  }
}
