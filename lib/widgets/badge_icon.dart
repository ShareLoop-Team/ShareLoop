import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Reusable small badge indicator showing tier colour and name.
class BadgeIcon extends StatelessWidget {
  const BadgeIcon({super.key, required this.badgeName, this.compact = false});

  final String badgeName;
  final bool compact;

  Color _colorFor(String name) {
    switch (name) {
      case 'Bronze':
        return const Color(0xFFCD7F32);
      case 'Silver':
        return const Color(0xFFA8A9AD);
      case 'Gold':
        return const Color(0xFFFFD700);
      case 'Platinum':
        return const Color(0xFF8A9A9A);
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(badgeName);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, size: compact ? 14 : 16, color: color),
          const SizedBox(width: 4),
          Text(
            badgeName,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: compact ? 11 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
