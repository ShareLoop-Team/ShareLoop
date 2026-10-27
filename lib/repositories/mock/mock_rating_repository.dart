import '../../models/rating_review_model.dart';
import '../../services/mock_data_service.dart';
import '../rating_repository.dart';

/// [RatingRepository] over in-memory mock data.
class MockRatingRepository implements RatingRepository {
  final MockDataService _data = MockDataService.instance;

  @override
  Future<List<RatingReviewModel>> getRatingsForUser(String rateeId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _data.ratings.where((r) => r.rateeId == rateeId).toList();
  }

  @override
  Future<RatingReviewModel> addRating(RatingReviewModel rating) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _data.ratings.add(rating);

    final ratings =
        _data.ratings.where((r) => r.rateeId == rating.rateeId).toList();
    final average =
        ratings.map((r) => r.stars).reduce((a, b) => a + b) / ratings.length;
    final index = _data.users.indexWhere((u) => u.id == rating.rateeId);
    if (index != -1) {
      _data.users[index] = _data.users[index].copyWith(
        averageRating: average,
        ratingCount: ratings.length,
      );
    }
    return rating;
  }
}
