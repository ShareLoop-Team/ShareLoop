import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
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
    errorMessage = null;
    notifyListeners();
    try {
      allRequests = await _repository.getAllRequests();
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
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
          r.itemName.toLowerCase().contains(q) ||
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
    String itemName = '',
    required String description,
    required String reason,
    String notes = '',
    required String category,
    required String district,
    required String city,
  }) async {
    // A standalone request must say what is needed; a targeted one names
    // the post's item.
    if ((itemPostId == null && itemName.trim().isEmpty) ||
        description.trim().isEmpty ||
        reason.trim().isEmpty) {
      errorMessage = 'Item name, description and reason are required.';
      notifyListeners();
      return errorMessage;
    }
    final request = ItemRequestModel(
      id: 'r${DateTime.now().microsecondsSinceEpoch}',
      requesterId: requesterId,
      requesterName: requesterName,
      itemPostId: itemPostId,
      itemName: itemName.trim(),
      description: description.trim(),
      reason: reason.trim(),
      notes: notes.trim(),
      category: category,
      district: district,
      city: city.trim(),
      createdAt: DateTime.now(),
    );
    try {
      await _repository.createRequest(request);
    } on AppException catch (e) {
      return e.message;
    }
    await loadRequests();
    return null;
  }

  /// Removes the requester's own request. Updates the list in place so the
  /// page doesn't flash a loading state. Returns an error message on
  /// failure. (Requests are approved through ItemController.selectRequester.)
  Future<String?> deleteRequest(String requestId) async {
    try {
      await _repository.deleteRequest(requestId);
    } on AppException catch (e) {
      return e.message;
    }
    allRequests = allRequests.where((r) => r.id != requestId).toList();
    notifyListeners();
    return null;
  }
}
