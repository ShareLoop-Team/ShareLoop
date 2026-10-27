import '../../models/rating_review_model.dart';
import '../../services/backend_service.dart';
import '../rating_repository.dart';
import 'supabase_rows.dart';

/// [RatingRepository] backed by the Supabase `ratings` table. Ratings are
/// written by submit_rating(), which works out the ratee from the exchange
/// and refreshes their average in the same transaction.
class SupabaseRatingRepository implements RatingRepository {
  @override
  Future<List<RatingReviewModel>> getRatingsForUser(String rateeId) {
    return BackendService.guard(() async {
      final rows = await BackendService.client
          .from('ratings')
          .select()
          .eq('ratee_id', rateeId)
          .order('created_at', ascending: false)
          .limit(100);
      return [for (final row in rows) SupabaseRows.rating(row)];
    });
  }

  @override
  Future<RatingReviewModel> addRating(RatingReviewModel rating) {
    return BackendService.guard(() async {
      final row = await BackendService.client.rpc('submit_rating', params: {
        'p_item_id': rating.itemPostId,
        'p_stars': rating.stars,
        'p_comment': rating.comment,
      });
      return SupabaseRows.rating(row as Map<String, dynamic>);
    });
  }
}
