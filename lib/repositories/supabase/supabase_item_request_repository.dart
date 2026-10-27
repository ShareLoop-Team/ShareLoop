import '../../core/errors/app_exception.dart';
import '../../models/item_request_model.dart';
import '../../services/backend_service.dart';
import '../item_request_repository.dart';
import 'supabase_rows.dart';

/// [ItemRequestRepository] backed by the Supabase `item_requests` table.
/// Row Level Security decides which requests come back.
class SupabaseItemRequestRepository implements ItemRequestRepository {
  /// Enough for the feed and the user's own lists; older rows need paging.
  static const int _fetchLimit = 200;

  Future<List<ItemRequestModel>> _query({
    String? column,
    String? value,
  }) {
    return BackendService.guard(() async {
      var query = BackendService.client
          .from('item_requests')
          .select(SupabaseRows.requestSelect)
          .eq('is_hidden', false);
      if (column != null && value != null) {
        query = query.eq(column, value);
      }
      final rows = await query
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .limit(_fetchLimit);
      return [for (final row in rows) SupabaseRows.request(row)];
    });
  }

  @override
  Future<List<ItemRequestModel>> getAllRequests() => _query();

  @override
  Future<List<ItemRequestModel>> getRequestsForPost(String itemPostId) =>
      _query(column: 'item_id', value: itemPostId);

  @override
  Future<List<ItemRequestModel>> getRequestsByUser(String requesterId) =>
      _query(column: 'requester_id', value: requesterId);

  @override
  Future<ItemRequestModel> createRequest(ItemRequestModel request) {
    return BackendService.guard(() async {
      final row = await BackendService.client
          .from('item_requests')
          .insert({
            'requester_id': BackendService.requireUid(),
            'item_id': request.itemPostId,
            'item_name': request.itemName,
            'description': request.description,
            'reason': request.reason,
            'notes': request.notes,
            'category': request.category,
            'district': request.district,
            'city': request.city,
          })
          .select(SupabaseRows.requestSelect)
          .single();
      return SupabaseRows.request(row);
    });
  }

  @override
  Future<void> deleteRequest(String id) {
    return BackendService.guard(() async {
      final deleted = await BackendService.client
          .from('item_requests')
          .delete()
          .eq('id', id)
          .select('id');
      if (deleted.isEmpty) {
        throw const AppException(
          "An approved request can't be deleted.",
        );
      }
    });
  }
}
