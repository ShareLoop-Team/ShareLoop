import '../core/config/backend_config.dart';
import '../models/rating_review_model.dart';
import 'mock/mock_rating_repository.dart';
import 'api/api_rating_repository.dart';

/// Repository: ratings and reviews left after handover.
abstract class RatingRepository {
  factory RatingRepository() => BackendConfig.isConfigured
      ? ApiRatingRepository()
      : MockRatingRepository();

  Future<List<RatingReviewModel>> getRatingsForUser(String rateeId);

  /// Saves the rating and updates the ratee's average. On the real backend
  /// the ratee is derived from the exchange, not taken from [rating].
  Future<RatingReviewModel> addRating(RatingReviewModel rating);
}
