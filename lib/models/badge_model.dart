/// Model: a gamification badge tier earned from a user's donation count.
class BadgeModel {
  final String name; // Bronze, Silver, Gold, Platinum
  final int requiredDonations;
  final String level; // New Contributor, Active Contributor, ...

  const BadgeModel({
    required this.name,
    required this.requiredDonations,
    required this.level,
  });
}
