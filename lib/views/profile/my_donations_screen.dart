import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/badge_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/time_ago.dart';
import '../../models/badge_model.dart';
import '../../models/item_post_model.dart';
import '../../widgets/illustrated_empty_state.dart';
import '../../widgets/item_photo.dart';
import '../../widgets/status_chip.dart';
import 'activity_page.dart';

/// View: the items the signed-in user has given away, with progress toward
/// their next badge.
class MyDonationsScreen extends StatelessWidget {
  const MyDonationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = context.watch<ProfileController>();
    final posts = profile.myPosts;
    final donationCount = profile.user?.donationCount ?? 0;
    final nextBadge = context.read<BadgeController>().nextBadge(donationCount);
    final badgeCard = _BadgeProgress(
      donationCount: donationCount,
      nextBadge: nextBadge,
    );
    final navigator = Navigator.of(context);

    return ActivityPage(
      title: l10n.profileMyDonations,
      subtitle: l10n.myDonationsSubtitle,
      isEmpty: posts.isEmpty,
      emptyState: IllustratedEmptyState(
        illustration: 'assets/images/empty_donations.svg',
        title: l10n.myDonationsEmptyTitle,
        message: l10n.myDonationsEmptyBody,
        footer: badgeCard,
      ),
      items: [
        badgeCard,
        for (final post in posts)
          _DonationCard(
            post: post,
            onTap: () =>
                navigator.pushNamed(AppRoutes.itemDetails, arguments: post.id),
          ),
      ],
      action: ActivityAction(
        label: posts.isEmpty
            ? l10n.myDonationsFirstAction
            : l10n.myDonationsAction,
        icon: Icons.redeem_outlined,
        onOpen: () => navigator.pushNamed(AppRoutes.createGiveAway),
      ),
    );
  }
}

/// "Bronze badge · 0 of 5 items" with a progress bar and what's next.
class _BadgeProgress extends StatelessWidget {
  const _BadgeProgress({required this.donationCount, required this.nextBadge});

  final int donationCount;

  /// Null once every badge has been earned.
  final BadgeModel? nextBadge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final next = nextBadge;
    if (next == null) {
      return SoftCard(
        child: Row(
          children: [
            const Icon(Icons.emoji_events_outlined, color: AppColors.amber),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.profileAllBadgesEarned,
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  l10n.myDonationsBadgeTitle(next.name),
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  l10n.profileBadgeProgress(
                    donationCount,
                    next.requiredDonations,
                  ),
                  textAlign: TextAlign.end,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: donationCount / next.requiredDonations,
              minHeight: 8,
              color: AppColors.brightGreen,
              backgroundColor: AppColors.mutedSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.myDonationsBadgeHint(
              next.requiredDonations - donationCount,
              next.level,
            ),
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thumbnail, title, category · time and status of one donated item.
class _DonationCard extends StatelessWidget {
  const _DonationCard({required this.post, required this.onTap});

  final ItemPostModel post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    const placeholder = Center(
      child: Icon(Icons.inventory_2_outlined, color: AppColors.deepGreen),
    );
    return SoftCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox.square(
              dimension: 68,
              child: ColoredBox(
                color: AppColors.paleMint,
                child: post.photoUrls.isEmpty
                    ? placeholder
                    : ItemPhoto(
                        url: post.photoUrls.first,
                        placeholder: placeholder,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${post.category} · ${timeAgo(l10n, post.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                StatusChip.forPost(l10n, post.status),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
