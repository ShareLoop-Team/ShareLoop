import '../models/item_request_model.dart';
import '../services/mock_data_service.dart';

/// Repository: mock data access for item requests (standalone needs and
/// responses to a specific give-away post).
class ItemRequestRepository {
  final MockDataService _data = MockDataService.instance;

  Future<List<ItemRequestModel>> getAllRequests() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_data.itemRequests.reversed);
  }

  Future<List<ItemRequestModel>> getRequestsForPost(String itemPostId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _data.itemRequests
        .where((r) => r.itemPostId == itemPostId)
        .toList();
  }

  Future<List<ItemRequestModel>> getRequestsByUser(String requesterId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _data.itemRequests
        .where((r) => r.requesterId == requesterId)
        .toList();
  }

  Future<ItemRequestModel> createRequest(ItemRequestModel request) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _data.itemRequests.add(request);
    return request;
  }

  Future<void> updateRequest(ItemRequestModel request) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _data.itemRequests.indexWhere((r) => r.id == request.id);
    if (index != -1) {
      _data.itemRequests[index] = request;
    }
  }
}
