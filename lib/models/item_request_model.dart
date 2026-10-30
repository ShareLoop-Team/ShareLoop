enum ItemRequestStatus { pending, approved, rejected }

/// Model: an item request. Either a standalone "need post" or a response
/// requesting a specific donor's give-away post (itemPostId set).
class ItemRequestModel {
  final String id;
  final String requesterId;
  final String requesterName;

  /// The requester's profile photo when they posted, if they had one.
  final String? requesterAvatarUrl;
  final String? itemPostId;
  final String itemName; // empty on older requests; fall back to description
  final String description;
  final String reason;
  final String notes; // optional extra info for donors
  final String category;
  final String district;
  final String city;
  final DateTime createdAt;
  final ItemRequestStatus status;

  const ItemRequestModel({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    this.requesterAvatarUrl,
    this.itemPostId,
    this.itemName = '',
    required this.description,
    required this.reason,
    this.notes = '',
    required this.category,
    required this.district,
    required this.city,
    required this.createdAt,
    this.status = ItemRequestStatus.pending,
  });

  ItemRequestModel copyWith({
    ItemRequestStatus? status,
    String? itemName,
    String? description,
    String? reason,
    String? notes,
    String? category,
    String? district,
    String? city,
  }) {
    return ItemRequestModel(
      id: id,
      requesterId: requesterId,
      requesterName: requesterName,
      requesterAvatarUrl: requesterAvatarUrl,
      itemPostId: itemPostId,
      itemName: itemName ?? this.itemName,
      description: description ?? this.description,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      district: district ?? this.district,
      city: city ?? this.city,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }
}
