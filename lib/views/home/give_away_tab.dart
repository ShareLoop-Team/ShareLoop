import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/badge_controller.dart';
import '../../controllers/item_controller.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/routes/app_routes.dart';
import '../../models/item_post_model.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/item_grid_card.dart';
import '../../widgets/loading_indicator.dart';

/// View: two-column grid of Give Away posts matching the Home filters.
/// Built as a sliver so it scrolls together with the Home header.
class GiveAwayTab extends StatelessWidget {
  const GiveAwayTab({super.key, this.onClearFilters});

  /// Offered when the filters leave nothing to show; also clears the
  /// search box the parent owns.
  final VoidCallback? onClearFilters;

  Future<void> _confirmDelete(BuildContext context, ItemPostModel post) async {
    final l10n = AppLocalizations.of(context);
    final itemController = context.read<ItemController>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.postDeleteConfirm,
      message: l10n.postDeleteMessage,
      actionLabel: l10n.requestsDeleteAction,
    );
    if (!confirmed) return;
    final error = await itemController.deletePost(post.id);
    messenger.showSnackBar(SnackBar(content: Text(error ?? l10n.postDeleted)));
  }

  @override
  Widget build(BuildContext context) {
    final itemController = context.watch<ItemController>();
    final currentUser = context.watch<AuthController>().currentUser;
    final userId = currentUser?.id;
    final badgeController = context.read<BadgeController>();
    final l10n = AppLocalizations.of(context);

    if (itemController.isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: LoadingIndicator(),
      );
    }
    final posts = itemController.availablePosts;
    if (posts.isEmpty) {
      final EmptyState state;
      if (itemController.errorMessage case final error?) {
        // A failed load is not "no items": say so and offer a retry.
        state = EmptyState(
          icon: Icons.cloud_off_outlined,
          message: error,
          actionLabel: l10n.stateRetry,
          onAction: itemController.loadPosts,
        );
      } else if (itemController.hasActiveFilters) {
        state = EmptyState(
          icon: Icons.search_off,
          message: l10n.stateNoMatches,
          actionLabel: l10n.stateClearFilters,
          onAction: onClearFilters ?? itemController.clearFilters,
        );
      } else {
        state = EmptyState(message: l10n.noItemsAvailable);
      }
      return SliverFillRemaining(hasScrollBody: false, child: state);
    }
    // The donor photo row is a little taller than its text.
    final tileHeight =
        ItemGridCard.imageHeight +
        32 +
        MediaQuery.textScalerOf(context).scale(80);
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          mainAxisExtent: tileHeight,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
        ),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          final badge = badgeController.badgeForDonationCount(
            itemController.donorDonationCount(post.donorId),
          );
          final canDelete =
              post.donorId == userId && itemController.canDeletePost(post);
          return ItemGridCard(
            post: post,
            donorBadge: badge?.name,
            // Your own posts follow a profile photo change at once.
            donorAvatarUrl: post.donorId == userId
                ? currentUser?.avatarUrl
                : null,
            onTap: () =>
                Navigator.of(context)
                    .pushNamed(AppRoutes.itemDetails, arguments: post.id),
            onDelete: canDelete ? () => _confirmDelete(context, post) : null,
            deleteTooltip: l10n.postDelete,
          );
        },
      ),
    );
  }
}
