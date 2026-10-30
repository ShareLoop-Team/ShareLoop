import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service: keeps each user's district and city on this device
/// (SharedPreferences), so they survive an app restart.
///
/// Device-local only: nothing is uploaded or synced, so another phone or a
/// reinstall starts without it. Failures are logged and ignored; the
/// in-memory profile still works for the current run.
class ProfileLocationStore {
  const ProfileLocationStore();

  static String _key(String userId) => 'profile_location.$userId';

  Future<({String district, String city})?> read(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(userId));
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final district = json['district'];
      final city = json['city'];
      if (district is! String || city is! String) return null;
      return (district: district, city: city);
    } catch (e) {
      debugPrint('Saved profile location not read: $e');
      return null;
    }
  }

  Future<void> write(
    String userId, {
    required String district,
    required String city,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(userId),
        jsonEncode({'district': district, 'city': city}),
      );
    } catch (e) {
      debugPrint('Profile location not saved on this device: $e');
    }
  }
}
