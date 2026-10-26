/// Model: plain data class for a registered ShareLoop user. A single
/// account can act as both Donor and Requester, so no role field is fixed.
class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String district;
  final String city;
  final String? avatarUrl;
  final int donationCount;
  final double averageRating;
  final int ratingCount;
  final bool isAdmin;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.district,
    required this.city,
    this.avatarUrl,
    this.donationCount = 0,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.isAdmin = false,
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? district,
    String? city,
    String? avatarUrl,
    int? donationCount,
    double? averageRating,
    int? ratingCount,
    bool? isAdmin,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      district: district ?? this.district,
      city: city ?? this.city,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      donationCount: donationCount ?? this.donationCount,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
