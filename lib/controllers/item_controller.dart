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
  }) : _repository = repository ?? ItemPostRepository(),
       _exchangeRepository = exchangeRepository ?? ExchangeRepository();

  final ItemPostRepository _repository;
  final ExchangeRepository _exchangeRepository;

  List<ItemPostModel> _allPosts = [];
  final Map<String, ExchangeModel> _exchanges = {};
  bool isLoading = false;
  String? errorMessage;

  String? categoryFilter;
  String? districtFilter;

  /// Only posts in this city; Home sets it to the user's own city.
  String? cityFilter;
  String searchQuery = '';

  /// The profile city [applyProfileCity] last applied.
  String? _profileCity;

  List<ItemPostModel> get posts {
    return _allPosts.where((p) {
      final matchesCategory =
          categoryFilter == null || p.category == categoryFilter;
      final matchesDistrict =
          districtFilter == null || p.district == districtFilter;
      final matchesCity = cityFilter == null || p.city == cityFilter;
      final matchesSearch =
          searchQuery.isEmpty ||
          p.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesDistrict && matchesCity && matchesSearch;
    }).toList();
  }

  /// Whether a search, category, district or city is narrowing [posts].
  bool get hasActiveFilters =>
      categoryFilter != null ||
      districtFilter != null ||
      cityFilter != null ||
      searchQuery.trim().isNotEmpty;

  /// Whether [city] (the user's profile city) is already applied, so a
  /// null [cityFilter] means they chose to see all areas.
  bool hasAppliedProfileCity(String? city) => _profileCity == city;

  /// Filters to the user's city when it is new or has changed, leaving any
  /// "all areas" choice alone otherwise.
  void applyProfileCity(String? city) {
    if (_profileCity == city) return;
    _profileCity = city;
    cityFilter = city;
    notifyListeners();
  }

  /// Any loaded post by id, regardless of the Home filters.
  ItemPostModel? postById(String id) =>
      _allPosts.where((p) => p.id == id).firstOrNull;

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

  void setCityFilter(String? city) {
    cityFilter = city;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    categoryFilter = null;
    districtFilter = null;
    cityFilter = null;
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

  /// Whether the donor may still edit the post: only while it is available,
  /// not once a requester is chosen or the item has been given away.
  bool canEditPost(ItemPostModel post) => post.status == ItemPostStatus.active;

  /// Saves the donor's edits. [keptPhotoUrls] are the existing photos left
  /// in place (in order); [newPhotos] are added after them. Returns an
  /// error message, or null once saved.
  Future<String?> updatePost(
    ItemPostModel post, {
    required String title,
    required String description,
    required String condition,
    required String category,
    required String district,
    required String city,
    required List<String> keptPhotoUrls,
    List<PhotoUpload> newPhotos = const [],
  }) async {
    if (!canEditPost(post)) return 'This item can no longer be edited.';
    if (title.trim().isEmpty || description.trim().isEmpty) {
      return 'Title and description are required.';
    }
    final kept = [
      for (var i = 0; i < post.photoUrls.length; i++)
        if (keptPhotoUrls.contains(post.photoUrls[i])) i,
    ];
    final edited = post.copyWith(
      title: title.trim(),
      description: description.trim(),
      condition: condition,
      category: category,
      district: district,
      city: city.trim(),
      photoUrls: [for (final i in kept) post.photoUrls[i]],
      photoPaths: [
        for (final i in kept)
          if (i < post.photoPaths.length) post.photoPaths[i],
      ],
    );
    try {
      await _repository.updatePost(edited, newPhotos: newPhotos);
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
  Future<String?> confirmHandover(String postId) => _runExchangeStep(
    postId,
    () => _exchangeRepository.confirmHandover(postId),
  );

  Future<String?> cancelExchange(String postId) => _runExchangeStep(
    postId,
    () => _exchangeRepository.cancelExchange(postId),
  );

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
