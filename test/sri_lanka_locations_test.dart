import 'package:flutter_test/flutter_test.dart';

import 'package:shareloop/controllers/register_controller.dart';
import 'package:shareloop/core/constants/app_constants.dart';
import 'package:shareloop/core/constants/sri_lanka_locations.dart';

void main() {
  group('SriLankaLocations', () {
    test('covers exactly the 25 districts, each with cities', () {
      expect(AppConstants.sriLankanDistricts, hasLength(25));
      expect(
        SriLankaLocations.citiesByDistrict.keys.toSet(),
        AppConstants.sriLankanDistricts.toSet(),
      );
      for (final cities in SriLankaLocations.citiesByDistrict.values) {
        expect(cities, isNotEmpty);
      }
    });

    test('lists each city under one district only', () {
      final seen = <String, String>{};
      for (final MapEntry(key: district, value: cities)
          in SriLankaLocations.citiesByDistrict.entries) {
        for (final city in cities) {
          expect(seen[city], isNull, reason: '$city is in ${seen[city]}');
          seen[city] = district;
        }
      }
    });

    test('Gampaha offers its own towns, not other districts\'', () {
      final gampaha = SriLankaLocations.citiesFor('Gampaha');
      expect(gampaha, containsAll(['Negombo', 'Gampaha', 'Ja-Ela']));
      expect(gampaha, isNot(contains('Nugegoda')));
      expect(gampaha, isNot(contains('Kandy')));
      expect(SriLankaLocations.citiesFor(null), isEmpty);
      expect(SriLankaLocations.citiesFor('Atlantis'), isEmpty);
    });

    test('validCity keeps only a city of the given district', () {
      expect(SriLankaLocations.validCity('Gampaha', 'Negombo'), 'Negombo');
      expect(SriLankaLocations.validCity('Colombo', 'Negombo'), isNull);
      expect(SriLankaLocations.validCity('Gampaha', ''), isNull);
      // A district is never accepted as a city of another district.
      expect(SriLankaLocations.validCity('Colombo', 'Gampaha'), isNull);
    });
  });

  group('RegisterController location', () {
    test('selecting Negombo under Gampaha keeps it', () {
      final controller = RegisterController()
        ..selectDistrict('Gampaha')
        ..selectCity('Negombo');
      expect(controller.district, 'Gampaha');
      expect(controller.city, 'Negombo');
    });

    test('changing the district clears a city that is not in it', () {
      final controller = RegisterController()
        ..selectDistrict('Gampaha')
        ..selectCity('Negombo')
        ..selectDistrict('Colombo');
      expect(controller.city, isNull);

      controller.selectCity('Negombo');
      expect(controller.city, isNull, reason: 'Negombo is not in Colombo');
      controller.selectCity('Nugegoda');
      expect(controller.city, 'Nugegoda');
    });
  });
}
