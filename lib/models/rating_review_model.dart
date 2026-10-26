/// Model: a star rating and comment left after a completed handover.
class RatingReviewModel {
  final String id;
  final String itemPostId;
  final String raterId;
  final String rateeId;
  final int stars; // 1-5
  final String comment;
  final DateTime createdAt;

  const RatingReviewModel({
    required this.id,
    required this.itemPostId,
    required this.raterId,
    required this.rateeId,
    required this.stars,
    required this.comment,
    required this.createdAt,
  });
}
