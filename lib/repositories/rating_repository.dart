import '../models/rating_review_model.dart';
import '../services/mock_data_service.dart';

/// Repository: mock data access for ratings and reviews left after handover.
class RatingRepository {
  final MockDataService _data = MockDataService.instance;

  Future<List<RatingReviewModel>> getRatingsForUser(String rateeId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _data.ratings.where((r) => r.rateeId == rateeId).toList();
  }

  Future<RatingReviewModel> addRating(RatingReviewModel rating) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _data.ratings.add(rating);
    return rating;
  }
}
