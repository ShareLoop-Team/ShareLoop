import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../models/item_post_model.dart';
import '../models/item_request_model.dart';
import '../models/rating_review_model.dart';
import '../models/user_model.dart';
import '../repositories/item_post_repository.dart';
import '../repositories/item_request_repository.dart';
import '../repositories/rating_repository.dart';
import '../repositories/user_repository.dart';

/// Controller: coordinates loading and editing the signed-in user's
/// profile, plus their posts/requests/reviews summary.
class ProfileController extends ChangeNotifier {
  ProfileController({
    UserRepository? userRepository,
    ItemPostRepository? postRepository,
    ItemRequestRepository? requestRepository,
    RatingRepository? ratingRepository,
  })  : _userRepository = userRepository ?? UserRepository(),
        _postRepository = postRepository ?? ItemPostRepository(),
        _requestRepository = requestRepository ?? ItemRequestRepository(),
        _ratingRepository = ratingRepository ?? RatingRepository();

  final UserRepository _userRepository;
  final ItemPostRepository _postRepository;
  final ItemRequestRepository _requestRepository;
  final RatingRepository _ratingRepository;

  UserModel? user;
  List<ItemPostModel> myPosts = [];
  List<ItemRequestModel> myRequests = [];
  List<RatingReviewModel> myReviews = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadProfile(String userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      user = await _userRepository.getUserById(userId);
      myPosts = await _postRepository.getPostsByDonor(userId);
      myRequests = await _requestRepository.getRequestsByUser(userId);
      myReviews = await _ratingRepository.getRatingsForUser(userId);
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// The other party of a handover, shown on the contact screen. Kept apart
  /// from [user] so it never replaces the signed-in user's own profile.
  UserModel? contact;

  Future<void> loadContact(String userId) async {
    contact = null;
    errorMessage = null;
    notifyListeners();
    try {
      contact = await _userRepository.getUserById(userId);
    } on AppException catch (e) {
      errorMessage = e.message;
    }
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String name,
    required String phone,
    required String district,
    required String city,
  }) async {
    final current = user;
    if (current == null) return false;
    if (name.trim().isEmpty || phone.trim().isEmpty) return false;
    final updated = current.copyWith(
      name: name.trim(),
      phone: phone.trim(),
      district: district,
      city: city.trim(),
    );
    try {
      await _userRepository.updateUser(updated);
    } on AppException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
    user = updated;
    notifyListeners();
    return true;
  }
}
