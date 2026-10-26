enum ItemPostStatus { active, pendingHandover, completed }

/// Model: a "Give Away" post created by a donor.
class ItemPostModel {
  final String id;
  final String donorId;
  final String donorName;
  final String title;
  final String description;
  final String condition; // new, good, used
  final String category;
  final String district;
  final String city;
  final List<String> photoPaths;
  final DateTime createdAt;
  final ItemPostStatus status;
  final String? selectedRequesterId;

  const ItemPostModel({
    required this.id,
    required this.donorId,
    required this.donorName,
    required this.title,
    required this.description,
    required this.condition,
    required this.category,
    required this.district,
    required this.city,
    this.photoPaths = const [],
    required this.createdAt,
    this.status = ItemPostStatus.active,
    this.selectedRequesterId,
  });

  ItemPostModel copyWith({
    ItemPostStatus? status,
    String? selectedRequesterId,
  }) {
    return ItemPostModel(
      id: id,
      donorId: donorId,
      donorName: donorName,
      title: title,
      description: description,
      condition: condition,
      category: category,
      district: district,
      city: city,
      photoPaths: photoPaths,
      createdAt: createdAt,
      status: status ?? this.status,
      selectedRequesterId: selectedRequesterId ?? this.selectedRequesterId,
    );
  }
}
