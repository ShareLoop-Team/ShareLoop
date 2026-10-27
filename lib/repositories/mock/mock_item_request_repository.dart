import '../../models/item_request_model.dart';
import '../../services/mock_data_service.dart';
import '../item_request_repository.dart';

/// [ItemRequestRepository] over in-memory mock data.
class MockItemRequestRepository implements ItemRequestRepository {
  final MockDataService _data = MockDataService.instance;

  @override
  Future<List<ItemRequestModel>> getAllRequests() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_data.itemRequests.reversed);
  }

  @override
  Future<List<ItemRequestModel>> getRequestsForPost(String itemPostId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _data.itemRequests
        .where((r) => r.itemPostId == itemPostId)
        .toList();
  }

  @override
  Future<List<ItemRequestModel>> getRequestsByUser(String requesterId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _data.itemRequests
        .where((r) => r.requesterId == requesterId)
        .toList();
  }

  @override
  Future<ItemRequestModel> createRequest(ItemRequestModel request) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _data.itemRequests.add(request);
    return request;
  }

  @override
  Future<void> deleteRequest(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _data.itemRequests.removeWhere((r) => r.id == id);
  }
}
