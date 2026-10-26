import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/localization/generated/app_localizations.dart';
import '../core/utils/time_ago.dart';
import '../models/item_post_model.dart';

/// Reusable photo-first card for Give Away posts in two-column grids:
/// condition tag over the image, then title, category · district, and the
/// donor's badge with how long ago the item was posted.
class ItemGridCard extends StatelessWidget {
  const ItemGridCard({
    super.key,
    required this.post,
    required this.donorBadge,
    required this.onTap,
  });

  /// Height of the image area; grids use it to size each tile.
  static const double imageHeight = 124;

  final ItemPostModel post;

  /// Badge name (Bronze, Silver, Gold, Platinum) or null for new donors.
  final String? donorBadge;
  final VoidCallback onTap;

  static Color _badgeColor(String? badge) {
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
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final donorLabel = donorBadge == null
        ? l10n.homeNewDonor
        : l10n.homeDonorBadge(donorBadge!);

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: imageHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(
                      color: AppColors.paleMint,
                      child: Icon(
                        Icons.image_outlined,
                        size: 36,
                        color: AppColors.deepGreen.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        post.condition,
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${post.category} · ${post.district}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _badgeColor(donorBadge),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$donorLabel · ${timeAgo(l10n, post.createdAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
