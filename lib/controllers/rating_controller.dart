import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../models/rating_review_model.dart';
import '../repositories/rating_repository.dart';

/// Controller: coordinates submitting a rating/review after handover. The
/// repository keeps the ratee's average rating up to date.
class RatingController extends ChangeNotifier {
  RatingController({RatingRepository? ratingRepository})
      : _ratingRepository = ratingRepository ?? RatingRepository();

  final RatingRepository _ratingRepository;

  bool isLoading = false;
  String? errorMessage;

  /// Returns an error message, or null once the rating is saved.
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
    errorMessage = null;
    notifyListeners();

    try {
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
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return errorMessage;
  }
}
