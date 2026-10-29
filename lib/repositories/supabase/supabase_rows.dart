import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/backend_config.dart';
import '../../models/exchange_model.dart';
import '../../models/item_post_model.dart';
import '../../models/item_request_model.dart';
import '../../models/rating_review_model.dart';
import '../../models/user_model.dart';
import '../../services/backend_service.dart';

/// Column lists and row -> model mapping shared by the Supabase
/// repositories. Table and column names match supabase/migrations.
class SupabaseRows {
  SupabaseRows._();

  static const String profileSelect = '*, contacts:profile_contacts(email, phone)';

  static const String itemSelect = '*, '
      'donor:profiles!items_donor_id_fkey(display_name, donation_count, '
      'rating_avg), '
      'selected_request:item_requests!items_selected_request_id_fkey(requester_id)';

  static const String requestSelect =
      '*, requester:profiles!item_requests_requester_id_fkey(display_name)';

  /// PostgREST returns a to-one embed as an object, or null when RLS hides it.
  static Map<String, dynamic>? _embedded(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is List && value.isNotEmpty) {
      return value.first as Map<String, dynamic>;
    }
    return null;
  }

  static UserModel user(Map<String, dynamic> row, {String? avatarUrl}) {
    final contacts = _embedded(row['contacts']);
    return UserModel(
      id: row['id'] as String,
      name: row['display_name'] as String,
      email: contacts?['email'] as String? ?? '',
      phone: contacts?['phone'] as String? ?? '',
      district: row['district'] as String,
      city: row['city'] as String? ?? '',
      avatarUrl: avatarUrl,
      donationCount: row['donation_count'] as int? ?? 0,
      averageRating: (row['rating_avg'] as num? ?? 0).toDouble(),
      ratingCount: row['rating_count'] as int? ?? 0,
      isAdmin: row['is_admin'] as bool? ?? false,
      isSuspended: row['status'] == 'suspended',
    );
  }

  static ItemPostStatus itemStatus(String value) => switch (value) {
        'pending_handover' => ItemPostStatus.pendingHandover,
        'completed' => ItemPostStatus.completed,
        _ => ItemPostStatus.active,
      };

  static ItemPostModel item(
    Map<String, dynamic> row, {
    Map<String, String> signedUrls = const {},
  }) {
    final donor = _embedded(row['donor']);
    final selected = _embedded(row['selected_request']);
    final paths = (row['image_paths'] as List? ?? const []).cast<String>();
    return ItemPostModel(
      id: row['id'] as String,
      donorId: row['donor_id'] as String,
      donorName: donor?['display_name'] as String? ?? '',
      donorDonationCount: donor?['donation_count'] as int? ?? 0,
      donorRating: (donor?['rating_avg'] as num? ?? 0).toDouble(),
      title: row['title'] as String,
      description: row['description'] as String,
      condition: row['condition'] as String,
      category: row['category'] as String,
      district: row['district'] as String,
      city: row['city'] as String? ?? '',
      photoPaths: paths,
      photoUrls: [for (final path in paths) ?signedUrls[path]],
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      status: itemStatus(row['status'] as String),
      selectedRequesterId: selected?['requester_id'] as String?,
    );
  }

  /// Signed URLs for storage [paths] in one call. Photos are optional on
  /// every page, so a failure just leaves them out.
  static Future<Map<String, String>> signPhotos(Iterable<String> paths) async {
    final unique = paths.toSet().toList();
    final signedUrls = <String, String>{};
    if (unique.isEmpty) return signedUrls;
    try {
      final results = await BackendService.client.storage
          .from(BackendConfig.itemImagesBucket)
          .createSignedUrlsResult(
            unique,
            BackendConfig.signedUrlLifetime.inSeconds,
          );
      for (final result in results.whereType<SignedUrlSuccess>()) {
        signedUrls[result.path] = result.signedUrl;
      }
    } catch (_) {
      // Show the page without the photos.
    }
    return signedUrls;
  }

  /// Maps item rows, fetching signed photo URLs for all of them in one call.
  static Future<List<ItemPostModel>> items(List<dynamic> rows) async {
    final maps = rows.cast<Map<String, dynamic>>();
    final signedUrls = await signPhotos([
      for (final row in maps)
        ...(row['image_paths'] as List? ?? const []).cast<String>(),
    ]);
    return [for (final row in maps) item(row, signedUrls: signedUrls)];
  }

  /// Maps profile rows, fetching signed profile-photo URLs in one call.
  static Future<List<UserModel>> users(List<dynamic> rows) async {
    final maps = rows.cast<Map<String, dynamic>>();
    final signedUrls = await signPhotos([
      for (final row in maps)
        if (row['avatar_path'] case final String path) path,
    ]);
    return [
      for (final row in maps)
        user(row, avatarUrl: signedUrls[row['avatar_path']]),
    ];
  }

  static ItemRequestStatus requestStatus(String value) => switch (value) {
        'approved' => ItemRequestStatus.approved,
        'rejected' => ItemRequestStatus.rejected,
        _ => ItemRequestStatus.pending,
      };

  static ItemRequestModel request(Map<String, dynamic> row) {
    final requester = _embedded(row['requester']);
    return ItemRequestModel(
      id: row['id'] as String,
      requesterId: row['requester_id'] as String,
      requesterName: requester?['display_name'] as String? ?? '',
      itemPostId: row['item_id'] as String?,
      itemName: row['item_name'] as String? ?? '',
      description: row['description'] as String,
      reason: row['reason'] as String,
      notes: row['notes'] as String? ?? '',
      category: row['category'] as String,
      district: row['district'] as String,
      city: row['city'] as String? ?? '',
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      status: requestStatus(row['status'] as String),
    );
  }

  static DateTime? _time(Object? value) =>
      value == null ? null : DateTime.parse(value as String).toLocal();

  static ExchangeModel exchange(Map<String, dynamic> row) {
    return ExchangeModel(
      id: row['id'] as String,
      itemPostId: row['item_id'] as String?,
      requestId: row['request_id'] as String?,
      donorId: row['donor_id'] as String,
      requesterId: row['requester_id'] as String,
      status: switch (row['status'] as String) {
        'completed' => ExchangeStatus.completed,
        'cancelled' => ExchangeStatus.cancelled,
        _ => ExchangeStatus.pending,
      },
      donorConfirmedAt: _time(row['donor_confirmed_at']),
      requesterConfirmedAt: _time(row['requester_confirmed_at']),
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
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }
}
