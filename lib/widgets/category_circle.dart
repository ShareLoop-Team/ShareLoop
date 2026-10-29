import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

/// Photo and icon shown for each category; a category without a photo gets
/// a plain green circle.
const Map<String, (String?, IconData)> _categoryArt = {
  'Educational Books': (
    'assets/images/item_grade10_science.jpg',
    Icons.menu_book_outlined,
  ),
  'School Supplies': (
    'assets/images/item_leather_backpack.jpg',
    Icons.backpack_outlined,
  ),
  'Clothes': ('assets/images/item_white_tshirt.jpg', Icons.checkroom_outlined),
  'Shoes': (
    'assets/images/item_slip_on_sneakers.jpg',
    Icons.directions_walk_outlined,
  ),
  'Electronics': ('assets/images/item_smartphone.jpg', Icons.devices_outlined),
  'Household Items': (
    'assets/images/item_pressure_cooker.jpg',
    Icons.kitchen_outlined,
  ),
  'Other': (null, Icons.more_horiz),
};

/// Round category tile: a darkened photo with a white icon, the name below,
/// and a green ring while selected.
class CategoryCircle extends StatelessWidget {
  const CategoryCircle({
    super.key,
    required this.label,
    required this.photo,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  static const double _size = 60;

  final String label;
  final String? photo;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final photo = this.photo;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 76,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.deepGreen : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Container(
                  width: _size,
                  height: _size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.deepGreen,
                    image: photo == null
                        ? null
                        : DecorationImage(
                            image: AssetImage(photo),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withValues(alpha: 0.42),
                              BlendMode.darken,
                            ),
                          ),
                  ),
                  child: Icon(icon, color: AppColors.white, size: 26),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected ? AppColors.deepGreen : AppColors.ink,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      height: 1.25,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontally scrolling "All" + one [CategoryCircle] per category.
/// [selected] is null when "All" is chosen.
class CategoryCirclesRow extends StatelessWidget {
  const CategoryCirclesRow({
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryCircle(
            label: allLabel,
            photo: null,
            icon: Icons.grid_view_rounded,
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final category in AppConstants.itemCategories)
            CategoryCircle(
              label: category,
              photo: _categoryArt[category]?.$1,
              icon: _categoryArt[category]?.$2 ?? Icons.category_outlined,
              selected: selected == category,
              onTap: () => onSelected(category),
            ),
        ],
      ),
    );
  }
}
