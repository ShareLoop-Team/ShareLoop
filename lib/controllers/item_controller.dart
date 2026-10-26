import 'package:flutter/foundation.dart';

import '../models/item_post_model.dart';
import '../repositories/item_post_repository.dart';
import '../repositories/user_repository.dart';

/// Controller: coordinates browsing, filtering, and creating Give Away
/// posts, plus the donor's requester-selection action.
class ItemController extends ChangeNotifier {
  ItemController({
    ItemPostRepository? repository,
    UserRepository? userRepository,
  })  : _repository = repository ?? ItemPostRepository(),
        _userRepository = userRepository ?? UserRepository();

  final ItemPostRepository _repository;
  final UserRepository _userRepository;

  List<ItemPostModel> _allPosts = [];
  Map<String, int> _donationCountByDonor = {};
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

  Future<void> loadPosts() async {
    isLoading = true;
    notifyListeners();
    _allPosts = await _repository.getAllPosts();
    final users = await _userRepository.getAllUsers();
    _donationCountByDonor = {for (final u in users) u.id: u.donationCount};
    isLoading = false;
    notifyListeners();
  }

  /// Donation count of a post's donor, used to show their badge on cards.
  int donorDonationCount(String donorId) => _donationCountByDonor[donorId] ?? 0;

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

  Future<String?> createPost({
    required String donorId,
    required String donorName,
    required String title,
    required String description,
    required String condition,
    required String category,
    required String district,
    required String city,
    List<String> photoPaths = const [],
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
      photoPaths: photoPaths,
      createdAt: DateTime.now(),
    );
    await _repository.createPost(post);
    await loadPosts();
    return null;
  }

  Future<void> selectRequester(String postId, String requesterId) async {
    final post = await _repository.getPostById(postId);
    if (post == null) return;
    final updated = post.copyWith(
      status: ItemPostStatus.pendingHandover,
      selectedRequesterId: requesterId,
    );
    await _repository.updatePost(updated);
    await loadPosts();
  }

  Future<void> markCompleted(String postId) async {
    final post = await _repository.getPostById(postId);
    if (post == null) return;
    await _repository.updatePost(
      post.copyWith(status: ItemPostStatus.completed),
    );
    await loadPosts();
  }
}
