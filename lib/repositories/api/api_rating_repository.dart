import '../../models/rating_review_model.dart';
import '../../services/api_client.dart';
import '../rating_repository.dart';
import 'api_rows.dart';

/// [RatingRepository] backed by the Laravel API. The server works out the
/// ratee from the exchange and refreshes their average.
class ApiRatingRepository implements RatingRepository {
  ApiClient get _api => ApiClient.instance;

  @override
  Future<List<RatingReviewModel>> getRatingsForUser(String rateeId) async {
    final body = await _api.get('/users/$rateeId/ratings');
    return [for (final row in ApiRows.list(body)) ApiRows.rating(row)];
  }

  @override
  Future<RatingReviewModel> addRating(RatingReviewModel rating) async {
    final body = await _api.post('/items/${rating.itemPostId}/ratings', {
      'stars': rating.stars,
      'comment': rating.comment,
    });
    return ApiRows.rating(ApiRows.object(body));
  }
}
