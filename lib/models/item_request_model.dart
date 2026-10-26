enum ItemRequestStatus { pending, approved, rejected }

/// Model: an item request. Either a standalone "need post" or a response
/// requesting a specific donor's give-away post (itemPostId set).
class ItemRequestModel {
  final String id;
  final String requesterId;
  final String requesterName;
  final String? itemPostId;
  final String description;
  final String reason;
  final String category;
  final String district;
  final String city;
  final DateTime createdAt;
  final ItemRequestStatus status;

  const ItemRequestModel({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    this.itemPostId,
    required this.description,
    required this.reason,
    required this.category,
    required this.district,
    required this.city,
    required this.createdAt,
    this.status = ItemRequestStatus.pending,
  });

  ItemRequestModel copyWith({ItemRequestStatus? status}) {
    return ItemRequestModel(
      id: id,
      requesterId: requesterId,
      requesterName: requesterName,
      itemPostId: itemPostId,
      description: description,
      reason: reason,
      category: category,
      district: district,
      city: city,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }
}
