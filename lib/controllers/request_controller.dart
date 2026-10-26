import 'package:flutter/foundation.dart';

import '../models/item_request_model.dart';
import '../repositories/item_request_repository.dart';

/// Controller: coordinates creating item requests and fetching requests
/// for a given post (donor review) or user (my requests).
class RequestController extends ChangeNotifier {
  RequestController({ItemRequestRepository? repository})
      : _repository = repository ?? ItemRequestRepository();

  final ItemRequestRepository _repository;

  List<ItemRequestModel> allRequests = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadRequests() async {
    isLoading = true;
    notifyListeners();
    allRequests = await _repository.getAllRequests();
    isLoading = false;
    notifyListeners();
  }

  List<ItemRequestModel> requestsForPost(String itemPostId) =>
      allRequests.where((r) => r.itemPostId == itemPostId).toList();

  List<ItemRequestModel> requestsByUser(String requesterId) =>
      allRequests.where((r) => r.requesterId == requesterId).toList();

  /// Standalone community requests (not tied to a give-away post), narrowed
  /// by the same category/district/search filters the Home feed uses.
  List<ItemRequestModel> communityRequests({
    String? category,
    String? district,
    String query = '',
  }) {
    final q = query.toLowerCase();
    return allRequests.where((r) {
      final matchesCategory = category == null || r.category == category;
      final matchesDistrict = district == null || r.district == district;
      final matchesSearch = q.isEmpty ||
          r.description.toLowerCase().contains(q) ||
          r.reason.toLowerCase().contains(q);
      return r.itemPostId == null &&
          matchesCategory &&
          matchesDistrict &&
          matchesSearch;
    }).toList();
  }

  Future<String?> createRequest({
    required String requesterId,
    required String requesterName,
    String? itemPostId,
    required String description,
    required String reason,
    required String category,
    required String district,
    required String city,
  }) async {
    if (description.trim().isEmpty || reason.trim().isEmpty) {
      errorMessage = 'Description and reason are required.';
      notifyListeners();
      return errorMessage;
    }
    final request = ItemRequestModel(
      id: 'r${DateTime.now().microsecondsSinceEpoch}',
      requesterId: requesterId,
      requesterName: requesterName,
      itemPostId: itemPostId,
      description: description.trim(),
      reason: reason.trim(),
      category: category,
      district: district,
      city: city.trim(),
      createdAt: DateTime.now(),
    );
    await _repository.createRequest(request);
    await loadRequests();
    return null;
  }

  Future<void> approveRequest(String requestId) async {
    final request = allRequests.firstWhere((r) => r.id == requestId);
    await _repository.updateRequest(
      request.copyWith(status: ItemRequestStatus.approved),
    );
    await loadRequests();
  }

  Future<void> rejectRequest(String requestId) async {
    final request = allRequests.firstWhere((r) => r.id == requestId);
    await _repository.updateRequest(
      request.copyWith(status: ItemRequestStatus.rejected),
    );
    await loadRequests();
  }
}
