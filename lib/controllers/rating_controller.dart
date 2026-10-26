import 'package:flutter/foundation.dart';

import '../models/rating_review_model.dart';
import '../repositories/rating_repository.dart';
import '../repositories/user_repository.dart';

/// Controller: coordinates submitting a rating/review after handover and
/// recomputing the ratee's average rating.
class RatingController extends ChangeNotifier {
  RatingController({
    RatingRepository? ratingRepository,
    UserRepository? userRepository,
  })  : _ratingRepository = ratingRepository ?? RatingRepository(),
        _userRepository = userRepository ?? UserRepository();

  final RatingRepository _ratingRepository;
  final UserRepository _userRepository;

  bool isLoading = false;
  String? errorMessage;

  Future<String?> submitRating({
    required String itemPostId,
    required String raterId,
    required String rateeId,
    required int stars,
    required String comment,
  }) async {
    if (stars < 1 || stars > 5) {
      errorMessage = 'Please select a star rating.';
      notifyListeners();
      return errorMessage;
    }
    isLoading = true;
    notifyListeners();

    await _ratingRepository.addRating(
      RatingReviewModel(
        id: 'rv${DateTime.now().microsecondsSinceEpoch}',
        itemPostId: itemPostId,
        raterId: raterId,
        rateeId: rateeId,
        stars: stars,
        comment: comment.trim(),
        createdAt: DateTime.now(),
      ),
    );

    final ratings = await _ratingRepository.getRatingsForUser(rateeId);
    final average =
        ratings.map((r) => r.stars).reduce((a, b) => a + b) / ratings.length;
    final ratee = await _userRepository.getUserById(rateeId);
    if (ratee != null) {
      await _userRepository.updateUser(
        ratee.copyWith(
          averageRating: average,
          ratingCount: ratings.length,
        ),
      );
    }

    isLoading = false;
    notifyListeners();
    return null;
  }
}
