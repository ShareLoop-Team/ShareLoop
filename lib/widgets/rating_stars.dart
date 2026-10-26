import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Reusable star rating display/input. Read-only unless [onChanged] is set.
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.onChanged,
    this.size = 24,
  });

  final double rating;
  final ValueChanged<int>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = index < rating.round();
        final icon = Icon(
          filled ? Icons.star : Icons.star_border,
          color: AppColors.amber,
          size: size,
        );
        if (onChanged == null) return icon;
        return InkWell(
          onTap: () => onChanged!(index + 1),
          child: icon,
        );
      }),
    );
  }
}
