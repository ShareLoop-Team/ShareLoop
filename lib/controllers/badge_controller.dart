import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../models/badge_model.dart';

/// Controller: derives a user's current badge/level from their donation
/// count. Stateless business logic — no repository needed since it only
/// transforms data already loaded elsewhere (profile/user controller).
class BadgeController extends ChangeNotifier {
  BadgeModel? badgeForDonationCount(int donationCount) {
    String? earnedName;
    for (final entry in AppConstants.badgeThresholds.entries) {
      if (donationCount >= entry.value) {
        if (earnedName == null ||
            entry.value > AppConstants.badgeThresholds[earnedName]!) {
          earnedName = entry.key;
        }
      }
    }
    if (earnedName == null) return null;
    return BadgeModel(
      name: earnedName,
      requiredDonations: AppConstants.badgeThresholds[earnedName]!,
      level: AppConstants.badgeLevels[earnedName]!,
    );
  }

  /// The next badge still to earn, or null once every badge is earned.
  BadgeModel? nextBadge(int donationCount) {
    final upcoming = AppConstants.badgeThresholds.entries
        .where((entry) => donationCount < entry.value)
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    if (upcoming.isEmpty) return null;
    final next = upcoming.first;
    return BadgeModel(
      name: next.key,
      requiredDonations: next.value,
      level: AppConstants.badgeLevels[next.key]!,
    );
  }

  int donationsToNextBadge(int donationCount) {
    final sortedThresholds = AppConstants.badgeThresholds.values.toList()
      ..sort();
    for (final threshold in sortedThresholds) {
      if (donationCount < threshold) {
        return threshold - donationCount;
      }
    }
    return 0;
  }
}
