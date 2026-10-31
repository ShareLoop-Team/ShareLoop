import 'package:flutter/material.dart';

import '../../core/localization/data_labels.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/theme/sl_tokens.dart';
import '../../core/utils/time_ago.dart';
import '../../models/item_post_model.dart';
import '../donor_badge_dot.dart';
import '../item_photo.dart';
import '../user_avatar.dart';
import 'sl_motion.dart';

/// Discovery card for a Give Away post: a 4:3 photo, the title, one meta
/// line (condition · city), and the donor's photo with their badge and how
/// long ago they posted. Flat, with no actions on it: managing a post
/// (edit, delete) happens on its details page.
class SLItemCard extends StatelessWidget {
  const SLItemCard({
    super.key,
    required this.post,
    required this.donorBadge,
    required this.onTap,
    this.donorAvatarUrl,
  });

  static const double photoAspectRatio = 4 / 3;
  static const double _padding = SLSpace.m;
  static const double _avatarSize = 20;

  /// Height of a card [width] wide, for grids, so rows fit the text at the
  /// user's text size.
  static double heightFor(double width, TextScaler scaler) {
    final title = scaler.scale(16) * 1.35;
    final meta = scaler.scale(13) * 1.35;
    final donorRow = meta > _avatarSize ? meta : _avatarSize;
    // A few pixels spare: fonts round line metrics differently.
    const roundingAllowance = 4;
    return width / photoAspectRatio +
        _padding * 2 +
        title +
        2 +
        meta +
        SLSpace.s +
        donorRow +
        roundingAllowance;
  }

  final ItemPostModel post;

  /// Badge name (Bronze, Silver, Gold, Platinum) or null for new donors.
  final String? donorBadge;
  final VoidCallback onTap;

  /// Overrides the post's donor photo, e.g. with the signed-in user's
  /// current one on their own posts.
  final String? donorAvatarUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sl = context.sl;
    final type = context.slType;
    final badge = donorBadge;
    // The dot on the photo shows the badge; screen readers hear its name.
    final badgeLabel = badge == null
        ? l10n.homeNewDonor
        : l10n.homeDonorBadge(l10n.badge(badge));
    final donorFirstName = post.donorName.trim().split(' ').first;
    final placeholder = Icon(
      Icons.image_outlined,
      size: 32,
      color: sl.inkMuted,
    );

    return SLPressScale(
      child: Material(
        color: sl.surface,
        borderRadius: BorderRadius.circular(SLRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: photoAspectRatio,
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
              Padding(
                padding: const EdgeInsets.all(_padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: type.cardTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.condition(post.condition)} · ${post.city}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: type.small,
                    ),
                    const SizedBox(height: SLSpace.s),
                    Row(
                      children: [
                        _DonorAvatar(
                          url: donorAvatarUrl ?? post.donorAvatarUrl,
                          name: post.donorName,
                          badge: donorBadge,
                        ),
                        const SizedBox(width: SLSpace.s - 2),
                        Expanded(
                          child: Semantics(
                            label:
                                '$donorFirstName, $badgeLabel, '
                                '${timeAgo(l10n, post.createdAt)}',
                            excludeSemantics: true,
                            child: Text(
                              '$donorFirstName · '
                              '${timeAgo(l10n, post.createdAt)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: type.small,
                            ),
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
      ),
    );
  }
}

/// A grey placeholder in the shape of [SLItemCard], shown while posts load.
class SLItemCardSkeleton extends StatelessWidget {
  const SLItemCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final sl = context.sl;
    return SLLoadingPulse(child: _card(sl));
  }

  Widget _card(SLColors sl) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: sl.surface,
        borderRadius: BorderRadius.circular(SLRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: SLItemCard.photoAspectRatio,
            child: ColoredBox(color: sl.surfaceMuted),
          ),
          Padding(
            padding: const EdgeInsets.all(SLItemCard._padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(widthFactor: 0.8, child: _bar(sl, 16)),
                const SizedBox(height: SLSpace.s),
                FractionallySizedBox(widthFactor: 0.5, child: _bar(sl, 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _bar(SLColors sl, double height) => Container(
    height: height,
    decoration: BoxDecoration(
      color: sl.surfaceMuted,
      borderRadius: BorderRadius.circular(6),
    ),
  );
}

/// The donor's profile photo (or their initial), with their badge colour
/// as a small dot on its corner.
class _DonorAvatar extends StatelessWidget {
  const _DonorAvatar({
    required this.url,
    required this.name,
    required this.badge,
  });

  final String? url;
  final String name;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    const size = SLItemCard._avatarSize;
    final sl = context.sl;
    final Widget photo;
    if (url case final url? when url.isNotEmpty) {
      photo = UserAvatar(url: url, size: size, ringWidth: 1);
    } else {
      photo = Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: sl.accentSoft, shape: BoxShape.circle),
        child: Text(
          name.isEmpty ? '?' : name.characters.first.toUpperCase(),
          style: context.slType.small.copyWith(
            fontSize: 11,
            height: 1,
            color: sl.accentText,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          photo,
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                color: sl.surface,
                shape: BoxShape.circle,
              ),
              child: DonorBadgeDot(badge: badge, size: 7),
            ),
          ),
        ],
      ),
    );
  }
}
