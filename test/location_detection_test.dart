import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:shareloop/core/constants/app_constants.dart';
import 'package:shareloop/core/constants/sri_lanka_locations.dart';
import 'package:shareloop/services/location/place_matcher.dart';
import 'package:shareloop/services/location_service.dart';

import 'support/fake_location_service.dart';

void main() {
  group('SriLankaPlaceMatcher', () {
    test('Negombo in Gampaha District, as Android reports it', () {
      final match = SriLankaPlaceMatcher.match(const [
        PlaceNames(
          isoCountryCode: 'LK',
          administrativeArea: 'Western Province',
          subAdministrativeArea: 'Gampaha District',
          locality: 'Negombo',
        ),
      ]);
      expect(match?.district, 'Gampaha');
      expect(match?.city, 'Negombo');
    });

    test('a district without "District", and the town as a suburb', () {
      final match = SriLankaPlaceMatcher.match(const [
        PlaceNames(subAdministrativeArea: 'Gampaha', subLocality: 'Negombo'),
      ]);
      expect(match?.district, 'Gampaha');
      expect(match?.city, 'Negombo');
    });

    test('an unlisted town keeps the district and leaves the city open', () {
      final match = SriLankaPlaceMatcher.match(const [
        PlaceNames(
          subAdministrativeArea: 'Gampaha District',
          locality: 'Katana',
        ),
      ]);
      expect(match?.district, 'Gampaha');
      expect(match?.city, isNull);
    });

    test('a town alone fixes its district from the table', () {
      final match = SriLankaPlaceMatcher.match(const [
        PlaceNames(isoCountryCode: 'LK', locality: 'Negombo'),
      ]);
      expect(match?.district, 'Gampaha');
      expect(match?.city, 'Negombo');
    });

    test('a town from another district is never taken as the city', () {
      final match = SriLankaPlaceMatcher.match(const [
        PlaceNames(subAdministrativeArea: 'Colombo', locality: 'Negombo'),
      ]);
      expect(match?.district, 'Colombo');
      expect(match?.city, isNull);
    });

    test('towns from two districts without a district name: no guess', () {
      expect(
        SriLankaPlaceMatcher.match(const [
          PlaceNames(locality: 'Negombo'),
          PlaceNames(locality: 'Nugegoda'),
        ]),
        isNull,
      );
    });

    test('nothing recognisable gives no match', () {
      expect(
        SriLankaPlaceMatcher.match(const [
          PlaceNames(administrativeArea: 'Western Province', locality: 'X'),
        ]),
        isNull,
      );
      expect(SriLankaPlaceMatcher.match(const []), isNull);
    });

    test('spelling variants map to the table', () {
      expect(SriLankaPlaceMatcher.district('Kaluthara District'), 'Kalutara');
      expect(SriLankaPlaceMatcher.district('Moneragala'), 'Monaragala');
      expect(SriLankaPlaceMatcher.district('NUWARA-ELIYA'), 'Nuwara Eliya');
      expect(SriLankaPlaceMatcher.city('Ja Ela')?.city, 'Ja-Ela');
      expect(
        SriLankaPlaceMatcher.city('Mount Lavinia')?.city,
        'Dehiwala-Mount Lavinia',
      );
      expect(
        SriLankaPlaceMatcher.city('Sri Jayewardenepura Kotte')?.city,
        'Sri Jayawardenepura Kotte',
      );
    });

    test('every listed district and town matches itself, and only itself', () {
      for (final district in AppConstants.sriLankanDistricts) {
        expect(SriLankaPlaceMatcher.district(district), district);
        for (final city in SriLankaLocations.citiesFor(district)) {
          final found = SriLankaPlaceMatcher.city(city);
          expect(found?.city, city);
          expect(found?.district, district);
        }
      }
    });

    test('a country other than Sri Lanka is recognised', () {
      expect(
        SriLankaPlaceMatcher.isOutsideSriLanka(const [
          PlaceNames(isoCountryCode: 'IN', locality: 'Chennai'),
        ]),
        isTrue,
      );
      expect(
        SriLankaPlaceMatcher.isOutsideSriLanka(const [
          PlaceNames(isoCountryCode: 'LK'),
        ]),
        isFalse,
      );
      expect(
        SriLankaPlaceMatcher.isOutsideSriLanka(const [PlaceNames()]),
        isFalse,
      );
    });
  });

  group('LocationService.detect', () {
    Future<LocationResult> detect(FakeLocationService service) =>
        service.detect();

    LocationFailure failureOf(LocationResult result) =>
        (result as LocationNotFound).failure;

    test('a precise fix in Negombo gives Gampaha and Negombo', () async {
      final result = await detect(FakeLocationService.negombo());
      final match = (result as LocationFound).match;
      expect(match.district, 'Gampaha');
      expect(match.city, 'Negombo');
    });

    test('an approximate fix keeps only the district', () async {
      final result = await detect(FakeLocationService.negombo(accuracy: 2500));
      final match = (result as LocationFound).match;
      expect(match.district, 'Gampaha');
      expect(match.city, isNull);
    });

    test('a very coarse fix is not used', () async {
      final service = FakeLocationService.negombo(accuracy: 20000);
      expect(failureOf(await detect(service)), LocationFailure.inaccurate);
      expect(service.geocodeCalls, 0);
    });

    test('permission and location-service problems', () async {
      expect(
        failureOf(
          await detect(
            FakeLocationService.negombo(access: LocationAccess.askable),
          ),
        ),
        LocationFailure.permissionDenied,
      );
      expect(
        failureOf(
          await detect(
            FakeLocationService.negombo(access: LocationAccess.blocked),
          ),
        ),
        LocationFailure.permissionBlocked,
      );
      expect(
        failureOf(
          await detect(FakeLocationService.negombo(serviceEnabled: false)),
        ),
        LocationFailure.serviceDisabled,
      );
    });

    test('no geocoder on this platform', () async {
      final service = FakeLocationService.negombo(supported: false);
      expect(failureOf(await detect(service)), LocationFailure.unsupported);
    });

    test('a fix that times out', () async {
      final service = FakeLocationService.negombo(
        fixError: TimeoutException('no fix'),
      );
      expect(failureOf(await detect(service)), LocationFailure.timeout);
    });

    test('a fix that fails', () async {
      final service = FakeLocationService.negombo(fixError: StateError('gps'));
      expect(failureOf(await detect(service)), LocationFailure.positionFailed);
    });

    test('a reverse-geocoding error', () async {
      final service = FakeLocationService.negombo(
        geocodeError: StateError('IO_ERROR'),
      );
      expect(failureOf(await detect(service)), LocationFailure.geocodingFailed);
    });

    test('a reverse-geocoding timeout', () async {
      final service = FakeLocationService.negombo(
        geocodeError: TimeoutException('slow'),
      );
      expect(failureOf(await detect(service)), LocationFailure.timeout);
    });

    test('coordinates outside Sri Lanka are not geocoded', () async {
      final service = FakeLocationService(
        fix: (latitude: 13.0827, longitude: 80.2707, accuracy: 10),
        places: const [],
      );
      expect(failureOf(await detect(service)), LocationFailure.outsideSriLanka);
      expect(service.geocodeCalls, 0);
    });

    test('a geocoder naming another country', () async {
      final service = FakeLocationService.negombo(
        places: const [
          PlaceNames(isoCountryCode: 'IN', locality: 'Rameswaram'),
        ],
      );
      expect(failureOf(await detect(service)), LocationFailure.outsideSriLanka);
    });

    test('an answer with no listed district or town', () async {
      final service = FakeLocationService.negombo(
        places: const [PlaceNames(isoCountryCode: 'LK')],
      );
      expect(failureOf(await detect(service)), LocationFailure.notMatched);
    });
  });
}
