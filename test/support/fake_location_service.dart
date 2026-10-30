import 'package:shareloop/services/location_service.dart';

/// A [LocationService] with a scripted device: permission state, one GPS
/// fix and the reverse geocoder's answer. No platform plugin is touched.
class FakeLocationService extends LocationService {
  FakeLocationService({
    required this.fix,
    required this.places,
    this.supported = true,
    this.serviceEnabled = true,
    this.access = LocationAccess.granted,
    this.accessAfterRequest = LocationAccess.granted,
    this.fixError,
    this.geocodeError,
  });

  /// Central Negombo (Gampaha District), as Android's geocoder names it.
  FakeLocationService.negombo({
    double accuracy = 12,
    List<PlaceNames>? places,
    bool supported = true,
    bool serviceEnabled = true,
    LocationAccess access = LocationAccess.granted,
    LocationAccess accessAfterRequest = LocationAccess.granted,
    Object? fixError,
    Object? geocodeError,
  }) : this(
         fix: (latitude: 7.2083, longitude: 79.8358, accuracy: accuracy),
         places:
             places ??
             const [
               PlaceNames(
                 isoCountryCode: 'LK',
                 administrativeArea: 'Western Province',
                 subAdministrativeArea: 'Gampaha District',
                 locality: 'Negombo',
               ),
             ],
         supported: supported,
         serviceEnabled: serviceEnabled,
         access: access,
         accessAfterRequest: accessAfterRequest,
         fixError: fixError,
         geocodeError: geocodeError,
       );

  final LocationFix fix;
  final List<PlaceNames> places;
  final bool supported;
  final bool serviceEnabled;
  LocationAccess access;
  final LocationAccess accessAfterRequest;
  final Object? fixError;
  final Object? geocodeError;

  int requestCalls = 0;
  int geocodeCalls = 0;

  @override
  bool get isSupported => supported;

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationAccess> checkAccess() async => access;

  @override
  Future<LocationAccess> requestAccess() async {
    requestCalls++;
    return access = accessAfterRequest;
  }

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;

  @override
  Future<LocationFix> currentFix() async {
    if (fixError case final error?) throw error;
    return fix;
  }

  @override
  Future<List<PlaceNames>> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    geocodeCalls++;
    if (geocodeError case final error?) throw error;
    return places;
  }
}
