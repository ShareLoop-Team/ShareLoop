import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Small dot in the donor's badge colour, shown before "Silver donor" etc.
class DonorBadgeDot extends StatelessWidget {
  const DonorBadgeDot({super.key, required this.badge, this.size = 8});

  /// Badge name (Bronze, Silver, Gold, Platinum) or null for new donors.
  final String? badge;
  final double size;

  static Color colorFor(String? badge) {
    switch (badge) {
      case 'Bronze':
        return AppColors.bronze;
      case 'Silver':
        return AppColors.silver;
      case 'Gold':
        return AppColors.amber;
      case 'Platinum':
        return AppColors.ink;
      default:
        return AppColors.softMint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: colorFor(badge), shape: BoxShape.circle),
    );
  }
}
