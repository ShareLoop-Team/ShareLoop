import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/badge_controller.dart';
import '../../controllers/item_controller.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/sl_tokens.dart';
import '../../widgets/sl/sl_item_card.dart';
import '../../widgets/sl/sl_motion.dart';
import '../../widgets/sl/sl_states.dart';

/// View: the grid of Give Away posts matching the Home filters, as a
/// sliver so it scrolls with the Home header. Two columns on phones, more
/// on wide windows. Cards only open the post; owners manage (edit, delete)
/// their posts from its details page.
class GiveAwayTab extends StatelessWidget {
  const GiveAwayTab({super.key, this.onClearFilters});

  /// Offered when the filters leave nothing to show; also clears the
  /// search box the parent owns.
  final VoidCallback? onClearFilters;

  static const double _gap = SLSpace.m;
  static const double _maxCardWidth = 220;

  /// Placeholder cards while loading: two rows on a phone.
  static const int _skeletonCount = 4;

  @override
  Widget build(BuildContext context) {
    final itemController = context.watch<ItemController>();
    final currentUser = context.watch<AuthController>().currentUser;
    final userId = currentUser?.id;
    final badgeController = context.read<BadgeController>();
    final l10n = AppLocalizations.of(context);

    final posts = itemController.posts;
    if (!itemController.isLoading && posts.isEmpty) {
      final Widget state;
      if (itemController.errorMessage case final error?) {
        // A failed load is not "no items": say so and offer a retry.
        state = SLErrorState(
          message: error,
          retryLabel: l10n.stateRetry,
          onRetry: itemController.loadPosts,
        );
      } else if (itemController.hasActiveFilters) {
        state = SLEmptyState(
          icon: Icons.search_off,
          message: l10n.stateNoMatches,
          actionLabel: l10n.stateClearFilters,
          onAction: onClearFilters ?? itemController.clearFilters,
        );
      } else {
        state = SLEmptyState(message: l10n.noItemsAvailable);
      }
      return SliverToBoxAdapter(child: state);
    }

    final scaler = MediaQuery.textScalerOf(context);
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: SLSpace.screen),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final columns = ((width + _gap) / (_maxCardWidth + _gap))
              .ceil()
              .clamp(2, 6);
          final cardWidth = (width - _gap * (columns - 1)) / columns;
          final delegate = SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: _gap,
            crossAxisSpacing: _gap,
            mainAxisExtent: SLItemCard.heightFor(cardWidth, scaler),
          );

          if (itemController.isLoading) {
            return SliverGrid.builder(
              gridDelegate: delegate,
              itemCount: _skeletonCount,
              itemBuilder: (_, _) => const SLItemCardSkeleton(),
            );
          }
          return SliverGrid.builder(
            gridDelegate: delegate,
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final badge = badgeController.badgeForDonationCount(
                itemController.donorDonationCount(post.donorId),
              );
              return SLFadeIn(
                key: ValueKey(post.id),
                index: index,
                child: SLItemCard(
                  post: post,
                  donorBadge: badge?.name,
                  // Your own posts follow a profile photo change at once.
                  donorAvatarUrl: post.donorId == userId
                      ? currentUser?.avatarUrl
                      : null,
                  onTap: () =>
                      Navigator.of(context)
                          .pushNamed(AppRoutes.itemDetails, arguments: post.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
