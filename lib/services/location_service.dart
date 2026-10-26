import '../core/constants/app_constants.dart';

/// Service stub: location/proximity lookups. Returns static district data
/// today; swap the method bodies for a geolocation/maps API later without
/// touching controllers or views.
class LocationService {
  List<String> getDistricts() => AppConstants.sriLankanDistricts;

  /// Placeholder for future "nearest district" detection via GPS.
  Future<String?> detectCurrentDistrict() async => null;
}
