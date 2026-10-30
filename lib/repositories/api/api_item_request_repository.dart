import '../../models/item_request_model.dart';
import '../../services/api_client.dart';
import '../item_request_repository.dart';
import 'api_rows.dart';

/// [ItemRequestRepository] backed by the Laravel API. The server decides
/// which requests the caller may see.
class ApiItemRequestRepository implements ItemRequestRepository {
  ApiClient get _api => ApiClient.instance;

  Future<List<ItemRequestModel>> _query(Map<String, Object?> query) async {
    final body = await _api.get('/requests', query: query);
    return [for (final row in ApiRows.list(body)) ApiRows.request(row)];
  }

  @override
  Future<List<ItemRequestModel>> getAllRequests() => _query(const {});

  @override
  Future<List<ItemRequestModel>> getRequestsForPost(String itemPostId) =>
      _query({'item_id': itemPostId});

  @override
  Future<List<ItemRequestModel>> getRequestsByUser(String requesterId) =>
      _query({'requester_id': requesterId});

  @override
  Future<ItemRequestModel> createRequest(ItemRequestModel request) async {
    final body = await _api.post('/requests', {
      'item_id': request.itemPostId,
      'item_name': request.itemName,
      'description': request.description,
      'reason': request.reason,
      'notes': request.notes,
      'category': request.category,
      'district': request.district,
      'city': request.city,
    });
    return ApiRows.request(ApiRows.object(body));
  }

  @override
  Future<ItemRequestModel> updateRequest(ItemRequestModel request) async {
    final body = await _api.patch('/requests/${request.id}', {
      'item_name': request.itemName,
      'description': request.description,
      'reason': request.reason,
      'notes': request.notes,
      'category': request.category,
      'district': request.district,
      'city': request.city,
    });
    return ApiRows.request(ApiRows.object(body));
  }

  @override
  Future<void> deleteRequest(String id) async {
    await _api.delete('/requests/$id');
  }
}
