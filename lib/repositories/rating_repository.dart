import '../core/config/backend_config.dart';
import '../models/rating_review_model.dart';
import 'mock/mock_rating_repository.dart';
import 'api/api_rating_repository.dart';

/// Repository: ratings and reviews left after handover, over in-memory data.
abstract class RatingRepository {
  factory RatingRepository() => BackendConfig.isConfigured
      ? ApiRatingRepository()
      : MockRatingRepository();

  Future<List<RatingReviewModel>> getRatingsForUser(String rateeId);

  /// Saves the rating and updates the ratee's average.
  Future<RatingReviewModel> addRating(RatingReviewModel rating);
}
