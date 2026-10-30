import '../../core/errors/app_exception.dart';
import '../../models/exchange_model.dart';
import '../../models/item_post_model.dart';
import '../../models/item_request_model.dart';
import '../../services/mock_data_service.dart';
import '../exchange_repository.dart';

/// [ExchangeRepository] over in-memory mock data, following the same rules
/// as the backend's ExchangeService (backend/app/Services).
class MockExchangeRepository implements ExchangeRepository {
  final MockDataService _data = MockDataService.instance;

  int _postIndex(String postId) {
    final index = _data.itemPosts.indexWhere((p) => p.id == postId);
    if (index == -1) throw const AppException('Item not found.');
    return index;
  }

  int _liveExchangeIndex(String postId) => _data.exchanges.indexWhere(
        (e) => e.itemPostId == postId && e.status != ExchangeStatus.cancelled,
      );

  void _setRequestStatus(String requestId, ItemRequestStatus status) {
    final index = _data.itemRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _data.itemRequests[index] =
          _data.itemRequests[index].copyWith(status: status);
    }
  }

  ExchangeModel _pending(String postId) {
    final index = _liveExchangeIndex(postId);
    if (index == -1 ||
        _data.exchanges[index].status != ExchangeStatus.pending) {
      throw const AppException('No handover in progress for this item.');
    }
    return _data.exchanges[index];
  }

  @override
  Future<ExchangeModel> selectRequester({
    required String postId,
    required String requestId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final postIndex = _postIndex(postId);
    final post = _data.itemPosts[postIndex];
    final request = _data.itemRequests.firstWhere(
      (r) => r.id == requestId && r.itemPostId == postId,
      orElse: () => throw const AppException('Request not found.'),
    );
    if (post.status != ItemPostStatus.active) {
      throw const AppException('This item is no longer available.');
    }
    if (request.status != ItemRequestStatus.pending) {
      throw const AppException('This request is no longer pending.');
    }
    _data.itemPosts[postIndex] = post.copyWith(
      status: ItemPostStatus.pendingHandover,
      selectedRequesterId: request.requesterId,
    );
    _setRequestStatus(requestId, ItemRequestStatus.approved);
    final exchange = ExchangeModel(
      id: 'x${DateTime.now().microsecondsSinceEpoch}',
      itemPostId: postId,
      requestId: requestId,
      donorId: post.donorId,
      requesterId: request.requesterId,
    );
    _data.exchanges.add(exchange);
    return exchange;
  }

  @override
  Future<ExchangeModel> confirmHandover(String postId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final me = _data.currentUserId;
    var exchange = _pending(postId);
    final now = DateTime.now();
    if (me == exchange.donorId) {
      exchange = exchange.copyWith(
        donorConfirmedAt: exchange.donorConfirmedAt ?? now,
      );
    } else if (me == exchange.requesterId) {
      exchange = exchange.copyWith(
        requesterConfirmedAt: exchange.requesterConfirmedAt ?? now,
      );
    } else {
      throw const AppException('You are not part of this exchange.');
    }

    if (exchange.donorConfirmedAt != null &&
        exchange.requesterConfirmedAt != null) {
      exchange = exchange.copyWith(status: ExchangeStatus.completed);
      final postIndex = _postIndex(postId);
      _data.itemPosts[postIndex] = _data.itemPosts[postIndex]
          .copyWith(status: ItemPostStatus.completed);
      final donorIndex =
          _data.users.indexWhere((u) => u.id == exchange.donorId);
      if (donorIndex != -1) {
        final donor = _data.users[donorIndex];
        _data.users[donorIndex] =
            donor.copyWith(donationCount: donor.donationCount + 1);
      }
      for (final request in _data.itemRequests.toList()) {
        if (request.itemPostId == postId &&
            request.status == ItemRequestStatus.pending) {
          _setRequestStatus(request.id, ItemRequestStatus.rejected);
        }
      }
    }
    _data.exchanges[_liveExchangeIndex(postId)] = exchange;
    return exchange;
  }

  @override
  Future<ExchangeModel> cancelExchange(String postId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final me = _data.currentUserId;
    final exchange = _pending(postId);
    if (me != exchange.donorId && me != exchange.requesterId) {
      throw const AppException('You are not part of this exchange.');
    }
    final cancelled = exchange.copyWith(status: ExchangeStatus.cancelled);
    _data.exchanges[_liveExchangeIndex(postId)] = cancelled;
    final postIndex = _postIndex(postId);
    final post = _data.itemPosts[postIndex];
    // copyWith can't clear selectedRequesterId, so rebuild the post.
    _data.itemPosts[postIndex] = ItemPostModel(
      id: post.id,
      donorId: post.donorId,
      donorName: post.donorName,
      title: post.title,
      description: post.description,
      condition: post.condition,
      category: post.category,
      district: post.district,
      city: post.city,
      photoPaths: post.photoPaths,
      photoUrls: post.photoUrls,
      createdAt: post.createdAt,
    );
    if (exchange.requestId case final requestId?) {
      _setRequestStatus(requestId, ItemRequestStatus.rejected);
    }
    _data.ratings.removeWhere((r) => r.itemPostId == postId);
    return cancelled;
  }

  @override
  Future<ExchangeModel?> getExchangeForPost(String postId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _liveExchangeIndex(postId);
    return index == -1 ? null : _data.exchanges[index];
  }
}
