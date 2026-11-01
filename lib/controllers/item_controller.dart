import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../models/exchange_model.dart';
import '../models/item_filter_criteria.dart';
import '../models/item_post_model.dart';
import '../models/photo_upload.dart';

export '../models/item_filter_criteria.dart';
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

  ItemFilterCriteria _criteria = ItemFilterCriteria.empty;

  /// The active catalog filter criteria.
  ItemFilterCriteria get filterCriteria => _criteria;

  String? get categoryFilter => _criteria.category;
  set categoryFilter(String? value) => setCategoryFilter(value);

  String? get conditionFilter => _criteria.condition;
  set conditionFilter(String? value) => setConditionFilter(value);

  String? get districtFilter => _criteria.district;
  set districtFilter(String? value) => setDistrictFilter(value);

  /// Only posts in this city; Home sets it to the user's own city.
  String? get cityFilter => _criteria.city;
  set cityFilter(String? value) => setCityFilter(value);

  String get searchQuery => _criteria.searchQuery;
  set searchQuery(String value) => setSearchQuery(value);

  ItemSortOption get sortOption => _criteria.sortOption;
  set sortOption(ItemSortOption value) => setSortOption(value);

  double? get minRatingFilter => _criteria.minDonorRating;
  set minRatingFilter(double? value) => setMinRatingFilter(value);

  /// Unfiltered list of all posts loaded in memory.
  List<ItemPostModel> get allPosts => List.unmodifiable(_allPosts);

  /// The profile city [applyProfileCity] last applied.
  String? _profileCity;

  /// Posts matching the current search, category, condition, location,
  /// and sort criteria.
  List<ItemPostModel> get posts => _criteria.filterAndSort(_allPosts);

  /// Whether a search, category, condition, district, city, rating or sort
  /// is currently active.
  bool get hasActiveFilters => _criteria.hasActiveFilters;

  /// Whether [city] (the user's profile city) is already applied, so a
  /// null [cityFilter] means they chose to see all areas.
  bool hasAppliedProfileCity(String? city) => _profileCity == city;

  /// Filters to the user's city when it is new or has changed, leaving any
  /// "all areas" choice alone otherwise.
  void applyProfileCity(String? city) {
    if (_profileCity == city) return;
    _profileCity = city;
    setCityFilter(city);
  }

  /// Any loaded post by id, regardless of the Home filters.
  ItemPostModel? postById(String id) =>
      _allPosts.where((p) => p.id == id).firstOrNull;

  /// [posts] that can still be requested, for the browse lists. Posts with a
  /// handover underway or done stay in [posts] so their screens can find them.
  List<ItemPostModel> get availablePosts => _criteria
      .copyWith(status: ItemPostStatus.active)
      .filterAndSort(_allPosts);

  /// Filters and sorts any custom list of [items] using the given or
  /// current filter criteria.
  List<ItemPostModel> filterItems(
    List<ItemPostModel> items, {
    ItemFilterCriteria? criteria,
  }) {
    return (criteria ?? _criteria).filterAndSort(items);
  }

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
    if (_criteria.category == category) return;
    _criteria = _criteria.copyWith(
      category: category,
      clearCategory: category == null,
    );
    notifyListeners();
  }

  void setConditionFilter(String? condition) {
    if (_criteria.condition == condition) return;
    _criteria = _criteria.copyWith(
      condition: condition,
      clearCondition: condition == null,
    );
    notifyListeners();
  }

  void setDistrictFilter(String? district) {
    if (_criteria.district == district) return;
    _criteria = _criteria.copyWith(
      district: district,
      clearDistrict: district == null,
    );
    notifyListeners();
  }

  void setCityFilter(String? city) {
    if (_criteria.city == city) return;
    _criteria = _criteria.copyWith(
      city: city,
      clearCity: city == null,
    );
    notifyListeners();
  }

  void setSearchQuery(String query) {
    if (_criteria.searchQuery == query) return;
    _criteria = _criteria.copyWith(searchQuery: query);
    notifyListeners();
  }

  void setSortOption(ItemSortOption option) {
    if (_criteria.sortOption == option) return;
    _criteria = _criteria.copyWith(sortOption: option);
    notifyListeners();
  }

  void setMinRatingFilter(double? rating) {
    if (_criteria.minDonorRating == rating) return;
    _criteria = _criteria.copyWith(
      minDonorRating: rating,
      clearMinDonorRating: rating == null,
    );
    notifyListeners();
  }

  void setFilterCriteria(ItemFilterCriteria criteria) {
    _criteria = criteria;
    notifyListeners();
  }

  void clearFilters() {
    _criteria = ItemFilterCriteria.empty;
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
