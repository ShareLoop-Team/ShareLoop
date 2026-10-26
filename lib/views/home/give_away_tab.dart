import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/badge_controller.dart';
import '../../controllers/item_controller.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/item_grid_card.dart';
import '../../widgets/loading_indicator.dart';

/// View: two-column grid of Give Away posts matching the Home filters.
/// Built as a sliver so it scrolls together with the Home header.
class GiveAwayTab extends StatelessWidget {
  const GiveAwayTab({super.key});

  @override
  Widget build(BuildContext context) {
    final itemController = context.watch<ItemController>();
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
          return ItemGridCard(
            post: post,
            donorBadge: badge?.name,
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.itemDetails,
              arguments: post.id,
            ),
          );
        },
      ),
    );
  }
}
