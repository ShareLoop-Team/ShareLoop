import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/profile_controller.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/time_ago.dart';
import '../../core/theme/sl_tokens.dart';
import '../../models/rating_review_model.dart';
import '../../widgets/illustrated_empty_state.dart';
import '../../widgets/rating_stars.dart';
import 'activity_page.dart';

/// View: ratings and comments other people left for the signed-in user,
/// with their average on top.
class MyReviewsScreen extends StatelessWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final sl = context.sl;
    final profile = context.watch<ProfileController>();
    final reviews = profile.myReviews;
    final average = reviews.isEmpty
        ? 0.0
        : reviews.fold<int>(0, (sum, r) => sum + r.stars) / reviews.length;

    return ActivityPage(
      title: l10n.profileReviews,
      subtitle: l10n.myReviewsSubtitle,
      isEmpty: reviews.isEmpty,
      emptyState: IllustratedEmptyState(
        illustration: 'assets/images/empty_reviews.svg',
        title: l10n.myReviewsEmptyTitle,
        message: l10n.myReviewsEmptyBody,
        footer: SoftCard(
          padding: const EdgeInsets.all(18),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.myReviewsFirstTitle,
                  style: textTheme.titleSmall?.copyWith(
                    color: sl.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.myReviewsFirstBody,
                  style: textTheme.bodyMedium?.copyWith(
                    color: sl.inkMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      items: [
        _Summary(average: average, count: reviews.length),
        for (final review in reviews)
          _ReviewCard(
            review: review,
            reviewerName: profile.reviewAuthors[review.raterId]?.name,
            itemTitle: profile.reviewPosts[review.itemPostId]?.title,
          ),
      ],
      // Back to the home feed, where items are browsed.
      action: ActivityAction(
        label: l10n.myReviewsAction,
        icon: Icons.search,
        outlined: true,
        onOpen: () async {
          Navigator.of(context)
              .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
        },
      ),
    );
  }
}

/// Big average rating with stars and the number of reviews.
class _Summary extends StatelessWidget {
  const _Summary({required this.average, required this.count});

  final double average;
  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final sl = context.sl;
    return SoftCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Text(
            average.toStringAsFixed(1),
            style: textTheme.displaySmall?.copyWith(
              color: sl.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RatingStars(rating: average, size: 22),
                const SizedBox(height: 4),
                Text(
                  l10n.myReviewsCount(count),
                  style: textTheme.bodyMedium?.copyWith(color: sl.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.reviewerName,
    required this.itemTitle,
  });

  final RatingReviewModel review;
  final String? reviewerName;
  final String? itemTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final sl = context.sl;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RatingStars(rating: review.stars.toDouble(), size: 18),
              const Spacer(),
              Text(
                timeAgo(l10n, review.createdAt),
                style: textTheme.bodySmall?.copyWith(color: sl.inkMuted),
              ),
            ],
          ),
          if (reviewerName case final name? when name.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(name, style: textTheme.titleSmall),
          ],
          if (itemTitle case final title? when title.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              title,
              style: textTheme.bodySmall?.copyWith(color: sl.inkMuted),
            ),
          ],
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: textTheme.bodyMedium?.copyWith(color: sl.ink, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}
