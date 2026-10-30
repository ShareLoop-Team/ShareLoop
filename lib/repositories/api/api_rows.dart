import '../../models/category_model.dart';
import '../../models/exchange_model.dart';
import '../../models/item_post_model.dart';
import '../../models/item_request_model.dart';
import '../../models/rating_review_model.dart';
import '../../models/user_model.dart';

/// JSON -> model mapping for the Laravel API's resources
/// (backend/app/Http/Resources).
class ApiRows {
  ApiRows._();

  /// Unwraps Laravel's `{"data": ...}` resource envelope.
  static dynamic data(dynamic body) =>
      body is Map<String, dynamic> && body.containsKey('data')
          ? body['data']
          : body;

  static List<Map<String, dynamic>> list(dynamic body) =>
      (data(body) as List? ?? const []).cast<Map<String, dynamic>>();

  static Map<String, dynamic> object(dynamic body) =>
      data(body) as Map<String, dynamic>;

  static DateTime _time(Object? value) =>
      value == null ? DateTime.now() : DateTime.parse(value as String).toLocal();

  static DateTime? _maybeTime(Object? value) =>
      value == null ? null : DateTime.parse(value as String).toLocal();

  static UserModel user(Map<String, dynamic> row) {
    return UserModel(
      id: row['id'] as String,
      name: row['display_name'] as String? ?? '',
      email: row['email'] as String? ?? '',
      phone: row['phone'] as String? ?? '',
      district: row['district'] as String? ?? '',
      city: row['city'] as String? ?? '',
      avatarUrl: row['avatar_url'] as String?,
      donationCount: row['donation_count'] as int? ?? 0,
      averageRating: (row['rating_avg'] as num? ?? 0).toDouble(),
      ratingCount: row['rating_count'] as int? ?? 0,
      isAdmin: row['is_admin'] as bool? ?? false,
      isSuspended: row['status'] == 'suspended',
    );
  }

  static ItemPostStatus itemStatus(String? value) => switch (value) {
        'pending_handover' => ItemPostStatus.pendingHandover,
        'completed' => ItemPostStatus.completed,
        _ => ItemPostStatus.active,
      };

  static ItemPostModel item(Map<String, dynamic> row) {
    final donor = row['donor'] as Map<String, dynamic>? ?? const {};
    return ItemPostModel(
      id: row['id'] as String,
      donorId: row['donor_id'] as String,
      donorName: donor['display_name'] as String? ?? '',
      donorDonationCount: donor['donation_count'] as int? ?? 0,
      donorAvatarUrl: donor['avatar_url'] as String?,
      donorRating: (donor['rating_avg'] as num? ?? 0).toDouble(),
      title: row['title'] as String,
      description: row['description'] as String,
      condition: row['condition'] as String,
      category: row['category'] as String,
      district: row['district'] as String,
      city: row['city'] as String? ?? '',
      photoPaths: (row['image_paths'] as List? ?? const []).cast<String>(),
      photoUrls: (row['image_urls'] as List? ?? const []).cast<String>(),
      createdAt: _time(row['created_at']),
      status: itemStatus(row['status'] as String?),
      selectedRequesterId: row['selected_requester_id'] as String?,
    );
  }

  static ItemRequestStatus requestStatus(String? value) => switch (value) {
        'approved' => ItemRequestStatus.approved,
        'rejected' => ItemRequestStatus.rejected,
        _ => ItemRequestStatus.pending,
      };

  static ItemRequestModel request(Map<String, dynamic> row) {
    final requester = row['requester'] as Map<String, dynamic>? ?? const {};
    return ItemRequestModel(
      id: row['id'] as String,
      requesterId: row['requester_id'] as String,
      requesterName: requester['display_name'] as String? ?? '',
      requesterAvatarUrl: requester['avatar_url'] as String?,
      itemPostId: row['item_id'] as String?,
      itemName: row['item_name'] as String? ?? '',
      description: row['description'] as String,
      reason: row['reason'] as String,
      notes: row['notes'] as String? ?? '',
      category: row['category'] as String,
      district: row['district'] as String,
      city: row['city'] as String? ?? '',
      createdAt: _time(row['created_at']),
      status: requestStatus(row['status'] as String?),
    );
  }

  static ExchangeModel exchange(Map<String, dynamic> row) {
    return ExchangeModel(
      id: row['id'] as String,
      itemPostId: row['item_id'] as String?,
      requestId: row['request_id'] as String?,
      donorId: row['donor_id'] as String,
      requesterId: row['requester_id'] as String,
      status: switch (row['status'] as String?) {
        'completed' => ExchangeStatus.completed,
        'cancelled' => ExchangeStatus.cancelled,
        _ => ExchangeStatus.pending,
      },
      donorConfirmedAt: _maybeTime(row['donor_confirmed_at']),
      requesterConfirmedAt: _maybeTime(row['requester_confirmed_at']),
    );
  }

  static RatingReviewModel rating(Map<String, dynamic> row) {
    return RatingReviewModel(
      id: row['id'] as String,
      itemPostId: row['item_id'] as String? ?? '',
      raterId: row['rater_id'] as String,
      rateeId: row['ratee_id'] as String,
      stars: row['stars'] as int,
      comment: row['comment'] as String? ?? '',
      createdAt: _time(row['created_at']),
    );
  }

  static CategoryModel category(Map<String, dynamic> row) {
    return CategoryModel(
      id: row['id'] as String,
      name: row['name'] as String,
      iconName: row['icon_name'] as String? ?? 'category',
    );
  }
}
