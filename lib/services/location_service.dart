import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'location/place_matcher.dart';

export 'location/place_matcher.dart' show PlaceMatch, PlaceNames;

/// Whether the app may read the device location right now.
enum LocationAccess {
  granted,

  /// Not granted, but the system will still show its prompt.
  askable,

  /// Denied for good; only the system settings can change it.
  blocked,
}

/// Why "Use my location" found no district.
enum LocationFailure {
  /// No reverse geocoder on this platform (web, desktop).
  unsupported,
  serviceDisabled,
  permissionDenied,
  permissionBlocked,
  timeout,

  /// The fix was too coarse to name even a district.
  inaccurate,
  outsideSriLanka,

  /// The geocoder answered, but with no listed district or town.
  notMatched,

  /// No GPS fix could be read.
  positionFailed,

  /// The reverse geocoder failed (offline, rate-limited, no service).
  geocodingFailed,
}

/// One position fix: where, and how sure (radius in metres).
typedef LocationFix = ({double latitude, double longitude, double accuracy});

sealed class LocationResult {
  const LocationResult();
}

/// A district was identified; [PlaceMatch.city] is null when no listed
/// town could be confidently named, so the user picks one.
class LocationFound extends LocationResult {
  const LocationFound(this.match);

  final PlaceMatch match;
}

class LocationNotFound extends LocationResult {
  const LocationNotFound(this.failure);

  final LocationFailure failure;
}

/// Service: one-off foreground location lookup for "Use my location".
///
/// Reads a single GPS fix with geolocator, reverse-geocodes it with the
/// phone's own geocoder (Android Geocoder / Apple CLGeocoder, via the
/// geocoding package) and matches the names against the bundled district
/// and town table. Nothing runs in the background and nothing is tracked.
///
/// The platform calls are overridable so tests can stand in a fake device.
class LocationService {
  /// Fixes less certain than this keep the district but not the town.
  static const double cityAccuracyMeters = 1000;

  /// Fixes less certain than this are not used at all.
  static const double districtAccuracyMeters = 10000;

  static const Duration fixTimeLimit = Duration(seconds: 20);
  static const Duration geocodeTimeLimit = Duration(seconds: 15);

  /// Mainland Sri Lanka and its islands, with a small margin.
  static bool isInSriLanka(double latitude, double longitude) =>
      latitude >= 5.7 &&
      latitude <= 10.1 &&
      longitude >= 79.4 &&
      longitude <= 82.1;

  /// Reverse geocoding needs the phone's geocoder: Android and iOS only.
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  Future<LocationAccess> checkAccess() async =>
      _access(await Geolocator.checkPermission());

  /// Shows the system prompt for foreground ("while in use") location.
  Future<LocationAccess> requestAccess() async =>
      _access(await Geolocator.requestPermission());

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  @protected
  Future<LocationFix> currentFix() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: fixTimeLimit,
      ),
    );
    return (
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
    );
  }

  /// English names, so they compare with the table's spelling.
  @protected
  Future<List<PlaceNames>> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    final placemarks = await Geocoding(locale: const Locale('en', 'US'))
        .placemarkFromCoordinates(latitude, longitude);
    return [
      for (final p in placemarks)
        PlaceNames(
          isoCountryCode: p.isoCountryCode,
          administrativeArea: p.administrativeArea,
          subAdministrativeArea: p.subAdministrativeArea,
          locality: p.locality,
          subLocality: p.subLocality,
        ),
    ];
  }

  /// Finds the user's district and, when it can be named with confidence,
  /// their town. Call once [checkAccess] is [LocationAccess.granted].
  Future<LocationResult> detect() async {
    if (!isSupported) {
      return const LocationNotFound(LocationFailure.unsupported);
    }
    try {
      if (!await isServiceEnabled()) {
        return const LocationNotFound(LocationFailure.serviceDisabled);
      }
      switch (await checkAccess()) {
        case LocationAccess.granted:
          break;
        case LocationAccess.askable:
          return const LocationNotFound(LocationFailure.permissionDenied);
        case LocationAccess.blocked:
          return const LocationNotFound(LocationFailure.permissionBlocked);
      }
    } catch (e) {
      debugPrint('Location access check failed: $e');
      return const LocationNotFound(LocationFailure.positionFailed);
    }

    final LocationFix fix;
    try {
      fix = await currentFix().timeout(
        fixTimeLimit + const Duration(seconds: 5),
      );
    } on TimeoutException {
      return const LocationNotFound(LocationFailure.timeout);
    } on LocationServiceDisabledException {
      return const LocationNotFound(LocationFailure.serviceDisabled);
    } on PermissionDeniedException {
      return const LocationNotFound(LocationFailure.permissionDenied);
    } catch (e) {
      debugPrint('Location fix failed: $e');
      return const LocationNotFound(LocationFailure.positionFailed);
    }

    if (!fix.accuracy.isFinite || fix.accuracy > districtAccuracyMeters) {
      return const LocationNotFound(LocationFailure.inaccurate);
    }
    if (!isInSriLanka(fix.latitude, fix.longitude)) {
      return const LocationNotFound(LocationFailure.outsideSriLanka);
    }

    final List<PlaceNames> places;
    try {
      places = await reverseGeocode(
        fix.latitude,
        fix.longitude,
      ).timeout(geocodeTimeLimit);
    } on TimeoutException {
      return const LocationNotFound(LocationFailure.timeout);
    } catch (e) {
      debugPrint('Reverse geocoding failed: $e');
      return const LocationNotFound(LocationFailure.geocodingFailed);
    }

    if (SriLankaPlaceMatcher.isOutsideSriLanka(places)) {
      return const LocationNotFound(LocationFailure.outsideSriLanka);
    }
    final match = SriLankaPlaceMatcher.match(places);
    if (match == null) {
      return const LocationNotFound(LocationFailure.notMatched);
    }
    // A coarse fix may sit across a town boundary: keep only the district.
    if (fix.accuracy > cityAccuracyMeters) {
      return LocationFound(PlaceMatch(district: match.district));
    }
    return LocationFound(match);
  }

  static LocationAccess _access(LocationPermission permission) =>
      switch (permission) {
        LocationPermission.whileInUse ||
        LocationPermission.always => LocationAccess.granted,
        LocationPermission.deniedForever => LocationAccess.blocked,
        LocationPermission.denied ||
        LocationPermission.unableToDetermine => LocationAccess.askable,
      };
}
