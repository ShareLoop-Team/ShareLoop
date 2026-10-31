import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/badge_controller.dart';
import '../../controllers/item_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/sl_tokens.dart';
import '../../core/utils/time_ago.dart';
import '../../models/badge_model.dart';
import '../../models/item_post_model.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/illustrated_empty_state.dart';
import '../../widgets/item_photo.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/confirm_dialog.dart';
import '../give_away/create_give_away_screen.dart';
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
    final userId = context.watch<AuthController>().currentUser?.id;
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
            canEdit:
                post.donorId == userId &&
                context.read<ItemController>().canEditPost(post),
            canDelete:
                post.donorId == userId &&
                context.read<ItemController>().canDeletePost(post),
            onEdit: () async {
              await navigator.push<void>(
                MaterialPageRoute(
                  builder: (_) => CreateGiveAwayScreen(editPost: post),
                ),
              );
              if (context.mounted) await ActivityPage.refresh(context);
            },
            onDelete: () => _deletePost(context, post),
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

  Future<void> _deletePost(BuildContext context, ItemPostModel post) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.postDeleteConfirm,
      message: l10n.postDeleteMessage,
      actionLabel: l10n.requestsDeleteAction,
    );
    if (!confirmed || !context.mounted) return;
    final error = await context.read<ItemController>().deletePost(post.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error ?? l10n.postDeleted)));
    if (error == null) await ActivityPage.refresh(context);
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
    final sl = context.sl;
    final next = nextBadge;
    if (next == null) {
      return SoftCard(
        child: Row(
          children: [
            Icon(Icons.emoji_events_outlined, color: sl.accentText),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.profileAllBadgesEarned,
                style: textTheme.titleSmall?.copyWith(
                  color: sl.ink,
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
                    color: sl.ink,
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
                  style: textTheme.bodyMedium?.copyWith(color: sl.inkMuted),
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
              color: sl.accent,
              backgroundColor: sl.surfaceMuted,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.myDonationsBadgeHint(
              next.requiredDonations - donationCount,
              next.level,
            ),
            style: textTheme.bodySmall?.copyWith(color: sl.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// Thumbnail, title, category · time and status of one donated item.
class _DonationCard extends StatelessWidget {
  const _DonationCard({
    required this.post,
    required this.onTap,
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  final ItemPostModel post;
  final VoidCallback onTap;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final sl = context.sl;
    const placeholder = Center(child: Icon(Icons.inventory_2_outlined));
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
                color: sl.surfaceMuted,
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
                    color: sl.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${post.category} · ${timeAgo(l10n, post.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(color: sl.inkMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  '${post.city}, ${post.district}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(color: sl.inkMuted),
                ),
                const SizedBox(height: 8),
                StatusChip.forPost(l10n, post.status),
              ],
            ),
          ),
          if (canEdit || canDelete)
            PopupMenuButton<String>(
              tooltip: MaterialLocalizations.of(context).showMenuTooltip,
              onSelected: (action) => action == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (context) => [
                if (canEdit)
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(AppLocalizations.of(context).itemDetailsEdit),
                  ),
                if (canDelete)
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(AppLocalizations.of(context).postDelete),
                  ),
              ],
            )
          else
            const RowChevron(),
        ],
      ),
    );
  }
}
