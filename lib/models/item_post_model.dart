enum ItemPostStatus { active, pendingHandover, completed }

/// Model: a "Give Away" post created by a donor.
class ItemPostModel {
  final String id;
  final String donorId;
  final String donorName;

  /// The donor's completed donations, for the badge shown on cards.
  final int donorDonationCount;

  /// The donor's average rating (0 when they have no ratings yet).
  final double donorRating;
  final String title;
  final String description;
  final String condition; // new, good, used
  final String category;
  final String district;
  final String city;

  /// Where the photos are stored (Storage object names, or local file paths
  /// on mock data). The first one is the cover.
  final List<String> photoPaths;

  /// Displayable URLs for [photoPaths], in the same order; empty when the
  /// photos can't be shown (e.g. mock data).
  final List<String> photoUrls;
  final DateTime createdAt;
  final ItemPostStatus status;
  final String? selectedRequesterId;

  const ItemPostModel({
    required this.id,
    required this.donorId,
    required this.donorName,
    this.donorDonationCount = 0,
    this.donorRating = 0,
    required this.title,
    required this.description,
    required this.condition,
    required this.category,
    required this.district,
    required this.city,
    this.photoPaths = const [],
    this.photoUrls = const [],
    required this.createdAt,
    this.status = ItemPostStatus.active,
    this.selectedRequesterId,
  });

  ItemPostModel copyWith({
    ItemPostStatus? status,
    String? selectedRequesterId,
    int? donorDonationCount,
    double? donorRating,
  }) {
    return ItemPostModel(
      id: id,
      donorId: donorId,
      donorName: donorName,
      donorDonationCount: donorDonationCount ?? this.donorDonationCount,
      donorRating: donorRating ?? this.donorRating,
      title: title,
      description: description,
      condition: condition,
      category: category,
      district: district,
      city: city,
      photoPaths: photoPaths,
      photoUrls: photoUrls,
      createdAt: createdAt,
      status: status ?? this.status,
      selectedRequesterId: selectedRequesterId ?? this.selectedRequesterId,
    );
  }
}
