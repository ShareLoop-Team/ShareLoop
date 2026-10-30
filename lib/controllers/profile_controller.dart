import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../models/item_post_model.dart';
import '../models/item_request_model.dart';
import '../models/exchange_model.dart';
import '../models/photo_upload.dart';
import '../models/rating_review_model.dart';
import '../models/user_model.dart';
import '../repositories/item_post_repository.dart';
import '../repositories/item_request_repository.dart';
import '../repositories/exchange_repository.dart';
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
    ExchangeRepository? exchangeRepository,
  }) : _userRepository = userRepository ?? UserRepository(),
       _postRepository = postRepository ?? ItemPostRepository(),
       _requestRepository = requestRepository ?? ItemRequestRepository(),
       _ratingRepository = ratingRepository ?? RatingRepository(),
       _exchangeRepository = exchangeRepository ?? ExchangeRepository();

  final UserRepository _userRepository;
  final ItemPostRepository _postRepository;
  final ItemRequestRepository _requestRepository;
  final RatingRepository _ratingRepository;
  final ExchangeRepository _exchangeRepository;

  UserModel? user;
  List<ItemPostModel> myPosts = [];
  List<ItemRequestModel> myRequests = [];
  List<RatingReviewModel> myReviews = [];
  final Map<String, ItemPostModel> reviewPosts = {};
  final Map<String, UserModel> reviewAuthors = {};
  List<ExchangeModel> myExchanges = [];
  final Map<String, ItemPostModel> exchangePosts = {};
  final Map<String, ItemRequestModel> exchangeRequests = {};
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadProfile(String userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final initialData = await Future.wait<Object?>([
        _userRepository.getUserById(userId),
        _postRepository.getPostsByDonor(userId),
        _requestRepository.getRequestsByUser(userId),
        _ratingRepository.getRatingsForUser(userId),
        _exchangeRepository.getExchangesByUser(userId),
      ]);
      user = initialData[0] as UserModel?;
      myPosts = initialData[1] as List<ItemPostModel>;
      myRequests = initialData[2] as List<ItemRequestModel>;
      myReviews = initialData[3] as List<RatingReviewModel>;
      myExchanges = initialData[4] as List<ExchangeModel>;

      reviewPosts.clear();
      reviewAuthors.clear();
      exchangePosts.clear();
      exchangeRequests.clear();

      // Reviews and exchanges can point to the same post. Fetch each referenced
      // post once, then expose it through whichever profile sections need it.
      final postIds = <String>{
        for (final review in myReviews) review.itemPostId,
        for (final exchange in myExchanges) ?exchange.itemPostId,
      };
      final posts = await Future.wait(postIds.map(_postRepository.getPostById));
      final reviewPostIds = myReviews
          .map((review) => review.itemPostId)
          .toSet();
      final exchangePostIds = myExchanges
          .map((exchange) => exchange.itemPostId)
          .whereType<String>()
          .toSet();
      for (final post in posts.whereType<ItemPostModel>()) {
        if (reviewPostIds.contains(post.id)) {
          reviewPosts[post.id] = post;
        }
        if (exchangePostIds.contains(post.id)) {
          exchangePosts[post.id] = post;
        }
      }

      final authorIds = myReviews.map((review) => review.raterId).toSet();
      final authors = await Future.wait(
        authorIds.map(_userRepository.getUserById),
      );
      for (final author in authors.whereType<UserModel>()) {
        reviewAuthors[author.id] = author;
      }

      // Fetch each requester's list once even when they have multiple active
      // exchanges, then retain only requests referenced by these exchanges.
      final requestOwners = <String, String>{};
      for (final exchange in myExchanges) {
        final requestId = exchange.requestId;
        if (requestId != null) {
          requestOwners[requestId] = exchange.requesterId;
        }
      }
      final requesterIds = {
        for (final requesterId in requestOwners.values) requesterId,
      };
      final requesterLists = await Future.wait(
        requesterIds.map(_requestRepository.getRequestsByUser),
      );
      for (final requests in requesterLists) {
        for (final request in requests) {
          if (requestOwners[request.id] == request.requesterId) {
            exchangeRequests[request.id] = request;
          }
        }
      }
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

  /// Saves just [current]'s district and city (e.g. picked on Home, where
  /// the full profile may not be loaded). Returns the saved user, or null
  /// with [errorMessage] set.
  Future<UserModel?> updateLocation(
    UserModel current, {
    required String district,
    required String city,
  }) async {
    errorMessage = null;
    final updated = current.copyWith(district: district, city: city);
    try {
      await _userRepository.updateUser(updated);
    } on AppException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return null;
    }
    if (user?.id == updated.id) user = updated;
    notifyListeners();
    return updated;
  }

  /// Saves the edited details, and [photo] as the new profile photo when
  /// one was picked. On failure [errorMessage] says why.
  Future<bool> updateProfile({
    required String name,
    required String phone,
    required String district,
    required String city,
    PhotoUpload? photo,
  }) async {
    final current = user;
    if (current == null) return false;
    if (name.trim().isEmpty || phone.trim().isEmpty) return false;
    errorMessage = null;
    var updated = current.copyWith(
      name: name.trim(),
      phone: phone.trim(),
      district: district,
      city: city.trim(),
    );
    try {
      if (photo != null) {
        final avatarUrl = await _userRepository.updateAvatar(current.id, photo);
        updated = updated.copyWith(avatarUrl: avatarUrl);
      }
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
