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
  const GiveAwayTab({super.key});

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
    final userId = context.watch<AuthController>().currentUser?.id;
    final badgeController = context.read<BadgeController>();
    final l10n = AppLocalizations.of(context);

    if (itemController.isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: LoadingIndicator(),
      );
    }
    final posts = itemController.posts;
    if (posts.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(message: l10n.noItemsAvailable),
      );
    }
    final tileHeight = ItemGridCard.imageHeight +
        26 +
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
          final canDelete = post.donorId == userId &&
              itemController.canDeletePost(post);
          return ItemGridCard(
            post: post,
            donorBadge: badge?.name,
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.itemDetails,
              arguments: post.id,
            ),
            onDelete: canDelete ? () => _confirmDelete(context, post) : null,
            deleteTooltip: l10n.postDelete,
          );
        },
      ),
    );
  }
}
