import '../core/config/backend_config.dart';
import '../models/item_request_model.dart';
import 'mock/mock_item_request_repository.dart';
import 'api/api_item_request_repository.dart';

/// Repository: item requests (standalone needs and responses to a specific
/// give-away post). Approval happens through [ExchangeRepository].
abstract class ItemRequestRepository {
  factory ItemRequestRepository() => BackendConfig.isConfigured
      ? ApiItemRequestRepository()
      : MockItemRequestRepository();

  /// Every request the user may see: public needs, their own requests, and
  /// requests on their posts. Newest first.
  Future<List<ItemRequestModel>> getAllRequests();

  Future<List<ItemRequestModel>> getRequestsForPost(String itemPostId);

  Future<List<ItemRequestModel>> getRequestsByUser(String requesterId);

  Future<ItemRequestModel> createRequest(ItemRequestModel request);

  Future<void> deleteRequest(String id);
}
