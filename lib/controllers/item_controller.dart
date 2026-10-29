import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../models/exchange_model.dart';
import '../models/item_post_model.dart';
import '../models/photo_upload.dart';
import '../repositories/exchange_repository.dart';
import '../repositories/item_post_repository.dart';

/// Controller: coordinates browsing, filtering, and creating Give Away
/// posts, plus the handover workflow (requester selection, confirmation).
class ItemController extends ChangeNotifier {
  ItemController({
    ItemPostRepository? repository,
    ExchangeRepository? exchangeRepository,
  })  : _repository = repository ?? ItemPostRepository(),
        _exchangeRepository = exchangeRepository ?? ExchangeRepository();

  final ItemPostRepository _repository;
  final ExchangeRepository _exchangeRepository;

  List<ItemPostModel> _allPosts = [];
  final Map<String, ExchangeModel> _exchanges = {};
  bool isLoading = false;
  String? errorMessage;

  String? categoryFilter;
  String? districtFilter;
  String searchQuery = '';

  List<ItemPostModel> get posts {
    return _allPosts.where((p) {
      final matchesCategory =
          categoryFilter == null || p.category == categoryFilter;
      final matchesDistrict =
          districtFilter == null || p.district == districtFilter;
      final matchesSearch = searchQuery.isEmpty ||
          p.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesDistrict && matchesSearch;
    }).toList();
  }

  /// [posts] that can still be requested, for the browse lists. Posts with a
  /// handover underway or done stay in [posts] so their screens can find them.
  List<ItemPostModel> get availablePosts =>
      posts.where((p) => p.status == ItemPostStatus.active).toList();

  Future<void> loadPosts() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      _allPosts = await _repository.getAllPosts();
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Donation count of a post's donor, used to show their badge on cards.
  int donorDonationCount(String donorId) {
    for (final post in _allPosts) {
      if (post.donorId == donorId) return post.donorDonationCount;
    }
    return 0;
  }

  List<ItemPostModel> postsByDonor(String donorId) =>
      _allPosts.where((p) => p.donorId == donorId).toList();

  void setCategoryFilter(String? category) {
    categoryFilter = category;
    notifyListeners();
  }

  void setDistrictFilter(String? district) {
    districtFilter = district;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    categoryFilter = null;
    districtFilter = null;
    searchQuery = '';
    notifyListeners();
  }

  /// Returns an error message, or null once the post is published.
  Future<String?> createPost({
    required String donorId,
    required String donorName,
    required String title,
    required String description,
    required String condition,
    required String category,
    required String district,
    required String city,
    List<PhotoUpload> photos = const [],
  }) async {
    if (title.trim().isEmpty || description.trim().isEmpty) {
      errorMessage = 'Title and description are required.';
      notifyListeners();
      return errorMessage;
    }
    final post = ItemPostModel(
      id: 'p${DateTime.now().microsecondsSinceEpoch}',
      donorId: donorId,
      donorName: donorName,
      title: title.trim(),
      description: description.trim(),
      condition: condition,
      category: category,
      district: district,
      city: city.trim(),
      createdAt: DateTime.now(),
    );
    try {
      await _repository.createPost(post, photos: photos);
    } on AppException catch (e) {
      return e.message;
    }
    await loadPosts();
    return null;
  }

  /// Whether the donor may still delete the post: not once a requester has
  /// been chosen and the handover is underway.
  bool canDeletePost(ItemPostModel post) =>
      post.status != ItemPostStatus.pendingHandover;

  /// Removes the donor's own post. Updates the list in place so the feed
  /// doesn't flash a loading state. Returns an error message on failure.
  Future<String?> deletePost(String postId) async {
    try {
      await _repository.deletePost(postId);
    } on AppException catch (e) {
      return e.message;
    }
    _allPosts = _allPosts.where((p) => p.id != postId).toList();
    notifyListeners();
    return null;
  }

  /// The handover for [postId] once loaded (see [loadExchange]), if the
  /// signed-in user is part of it.
  ExchangeModel? exchangeFor(String postId) => _exchanges[postId];

  Future<void> loadExchange(String postId) async {
    try {
      final exchange = await _exchangeRepository.getExchangeForPost(postId);
      if (exchange == null) {
        _exchanges.remove(postId);
      } else {
        _exchanges[postId] = exchange;
      }
      notifyListeners();
    } on AppException catch (e) {
      errorMessage = e.message;
      notifyListeners();
    }
  }

  /// The donor selects one request for their post. Returns an error
  /// message, or null on success.
  Future<String?> selectRequester(String postId, String requestId) {
    return _runExchangeStep(
      postId,
      () => _exchangeRepository.selectRequester(
        postId: postId,
        requestId: requestId,
      ),
    );
  }

  /// The signed-in party confirms the handover; the post completes once
  /// both parties have. Returns an error message, or null on success.
  Future<String?> confirmHandover(String postId) =>
      _runExchangeStep(postId, () => _exchangeRepository.confirmHandover(postId));

  Future<String?> cancelExchange(String postId) =>
      _runExchangeStep(postId, () => _exchangeRepository.cancelExchange(postId));

  Future<String?> _runExchangeStep(
    String postId,
    Future<ExchangeModel> Function() step,
  ) async {
    try {
      final exchange = await step();
      if (exchange.status == ExchangeStatus.cancelled) {
        _exchanges.remove(postId);
      } else {
        _exchanges[postId] = exchange;
      }
    } on AppException catch (e) {
      return e.message;
    }
    await loadPosts();
    return null;
  }
}
