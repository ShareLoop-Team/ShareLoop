import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/badge_controller.dart';
import '../../controllers/item_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/time_ago.dart';
import '../../models/item_post_model.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/donor_badge_dot.dart';
import '../../widgets/info_note.dart';
import '../../widgets/item_photo.dart';
import '../../widgets/photo_viewer.dart';
import '../../widgets/pill_button.dart';

/// View: full details of a Give Away post: photo gallery, tags, location,
/// description and donor card, with "Request this item" pinned at the
/// bottom for non-owners, or incoming requests for the donor.
class ItemDetailsScreen extends StatelessWidget {
  const ItemDetailsScreen({super.key, required this.postId});

  final String postId;

  Future<void> _confirmDelete(BuildContext context, ItemPostModel post) async {
    final l10n = AppLocalizations.of(context);
    final itemController = context.read<ItemController>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.postDeleteConfirm,
      message: l10n.postDeleteMessage,
      actionLabel: l10n.requestsDeleteAction,
    );
    if (!confirmed) return;
    final error = await itemController.deletePost(post.id);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(l10n.postDeleted)));
  }

  Future<void> _share(BuildContext context, ItemPostModel post) {
    final l10n = AppLocalizations.of(context);
    // iPads anchor the share sheet to the button that opened it.
    final box = context.findRenderObject() as RenderBox?;
    return SharePlus.instance.share(
      ShareParams(
        subject: post.title,
        text: l10n.itemDetailsShareText(
          post.title,
          post.district,
          post.description,
        ),
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final itemController = context.watch<ItemController>();
    final currentUser = context.watch<AuthController>().currentUser;
    final ItemPostModel? post =
        itemController.posts.where((p) => p.id == postId).firstOrNull ??
            itemController.postsByDonor(currentUser?.id ?? '')
                .where((p) => p.id == postId)
                .firstOrNull;

    if (post == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.itemDetailsTitle)),
        body: Center(child: Text(l10n.itemDetailsUnavailable)),
      );
    }

    final isOwner = currentUser != null && currentUser.id == post.donorId;
    final isSelectedRequester =
        currentUser != null && currentUser.id == post.selectedRequesterId;
    final handoverPending = post.status == ItemPostStatus.pendingHandover;
    final badge = context
        .watch<BadgeController>()
        .badgeForDonationCount(post.donorDonationCount)
        ?.name;

    void openRoute(String route) =>
        Navigator.of(context).pushNamed(route, arguments: post.id);
    final arrangeHandover = PillButton(
      icon: Icons.handshake_outlined,
      label: l10n.itemDetailsArrangeHandover,
      onPressed: () => openRoute(AppRoutes.contactShared),
    );

    final List<Widget> actions;
    if (isOwner) {
      actions = [
        if (handoverPending) ...[arrangeHandover, const SizedBox(height: 12)],
        PillButton(
          icon: Icons.inbox_outlined,
          label: l10n.itemDetailsViewRequests,
          onPressed: () => openRoute(AppRoutes.incomingRequests),
        ),
      ];
    } else if (isSelectedRequester && handoverPending) {
      actions = [arrangeHandover];
    } else if (post.status == ItemPostStatus.active) {
      actions = [
        PillButton(
          icon: Icons.redeem_outlined,
          label: l10n.itemDetailsRequest,
          onPressed: () => openRoute(AppRoutes.createRequest),
        ),
      ];
    } else {
      actions = [
        Text(
          l10n.itemDetailsClosed,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ];
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Gallery(
              post: post,
              backTooltip: MaterialLocalizations.of(context).backButtonTooltip,
              shareTooltip: l10n.itemDetailsShare,
              viewPhotoLabel: l10n.itemDetailsViewPhoto,
              onBack: () => Navigator.of(context).maybePop(),
              onShare: (buttonContext) => _share(buttonContext, post),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Tag(
                            label: post.condition,
                            background: AppColors.paleMint,
                            foreground: AppColors.deepGreen,
                          ),
                          _Tag(
                            label: post.category,
                            background: AppColors.mutedSurface,
                            foreground: AppColors.ink,
                          ),
                          _StatusTag(status: post.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _InfoLine(
                              icon: Icons.location_on_outlined,
                              text: '${post.district}, ${post.city}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InfoLine(
                              icon: Icons.schedule,
                              text: l10n.itemDetailsPosted(
                                timeAgo(l10n, post.createdAt),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        post.description,
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.ink,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _DonorCard(
                        name: post.donorName,
                        badgeLabel: badge == null
                            ? l10n.homeNewDonor
                            : l10n.homeDonorBadge(badge),
                        badge: badge,
                        rating: post.donorRating,
                        itemsGiven: l10n.itemDetailsItemsGiven(
                          post.donorDonationCount,
                        ),
                      ),
                      const SizedBox(height: 16),
                      InfoNote(text: l10n.itemDetailsPrivacyNote),
                      if (isOwner && itemController.canDeletePost(post)) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmDelete(context, post),
                            icon: const Icon(Icons.delete_outline),
                            label: Text(l10n.postDelete),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: const StadiumBorder(),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(children: actions),

    );
  }
}

/// Full-width photo pager with round back/share buttons and page dots.
class _Gallery extends StatefulWidget {
  const _Gallery({
    required this.post,
    required this.backTooltip,
    required this.shareTooltip,
    required this.viewPhotoLabel,
    required this.onBack,
    required this.onShare,
  });

  final ItemPostModel post;
  final String backTooltip;
  final String shareTooltip;
  final String viewPhotoLabel;
  final VoidCallback onBack;

  /// Receives the share button's context so the share sheet can anchor to it.
  final void Function(BuildContext buttonContext) onShare;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final photos = widget.post.photoUrls;
    final topInset = MediaQuery.paddingOf(context).top;
    // Square on phones, but never more than 45% of the screen so the
    // title and details stay in view.
    final screen = MediaQuery.sizeOf(context);
    final height = math.min(screen.width, screen.height * 0.45);
    const placeholder = Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 64,
        color: AppColors.deepGreen,
      ),
    );

    return SizedBox(
      height: height + topInset,
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.paleMint,
              child: photos.isEmpty
                  ? placeholder
                  : PageView.builder(
                      itemCount: photos.length,
                      onPageChanged: (page) => setState(() => _page = page),
                      // Tapping opens the full-screen zoomable viewer.
                      itemBuilder: (context, index) => Semantics(
                        button: true,
                        label: widget.viewPhotoLabel,
                        child: GestureDetector(
                          onTap: () => showPhotoViewer(
                            context,
                            urls: photos,
                            initialIndex: index,
                          ),
                          child: ExcludeSemantics(
                            // Below the status bar so nothing hides under it.
                            child: Padding(
                              padding: EdgeInsets.only(top: topInset),
                              child: ItemPhotoFull(
                                url: photos[index],
                                placeholder: placeholder,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          Positioned(
            top: topInset + 12,
            left: 16,
            child: _RoundButton(
              icon: Icons.arrow_back_ios_new,
              tooltip: widget.backTooltip,
              onPressed: widget.onBack,
            ),
          ),
          Positioned(
            top: topInset + 12,
            right: 16,
            child: Builder(
              builder: (buttonContext) => _RoundButton(
                icon: Icons.share_outlined,
                tooltip: widget.shareTooltip,
                onPressed: () => widget.onShare(buttonContext),
              ),
            ),
          ),
          if (photos.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < photos.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _page ? 22 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? AppColors.deepGreen
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// White circular icon button floating over the photo.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: AppColors.ink.withValues(alpha: 0.3),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, size: 20, color: AppColors.ink),
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      ),
    );
  }
}

/// Rounded pill label, optionally with a leading icon.
class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Available / Handover pending / Given away.
class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.status});

  final ItemPostStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (status) {
      ItemPostStatus.active => _Tag(
          label: l10n.itemDetailsAvailable,
          icon: Icons.check,
          background: AppColors.paleMint,
          foreground: AppColors.deepGreen,
        ),
      ItemPostStatus.pendingHandover => _Tag(
          label: l10n.itemDetailsPendingHandover,
          icon: Icons.schedule,
          background: AppColors.amber.withValues(alpha: 0.15),
          foreground: AppColors.ink,
        ),
      ItemPostStatus.completed => _Tag(
          label: l10n.itemDetailsGivenAway,
          background: AppColors.mutedSurface,
          foreground: AppColors.textSecondary,
        ),
    };
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.ink),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// White card with the donor's initial, name, badge, rating and donations.
class _DonorCard extends StatelessWidget {
  const _DonorCard({
    required this.name,
    required this.badgeLabel,
    required this.badge,
    required this.rating,
    required this.itemsGiven,
  });

  final String name;
  final String badgeLabel;
  final String? badge;
  final double rating;
  final String itemsGiven;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final secondary = textTheme.bodySmall?.copyWith(
      color: AppColors.textSecondary,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.softMint,
            child: Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.deepGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                // Each group stays together, so on narrow phones the rating
                // wraps as a whole instead of splitting star and number.
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 2,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DonorBadgeDot(badge: badge, size: 10),
                        const SizedBox(width: 6),
                        Flexible(child: Text(badgeLabel, style: secondary)),
                      ],
                    ),
                    if (rating > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: AppColors.amber,
                          ),
                          const SizedBox(width: 2),
                          Text(rating.toStringAsFixed(1), style: secondary),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(itemsGiven, style: secondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
