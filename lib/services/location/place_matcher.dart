import '../../core/constants/app_constants.dart';
import '../../core/constants/sri_lanka_locations.dart';

/// The names a reverse geocoder gave for one place near the user. Only
/// these fields are matched; street-level detail is never used.
class PlaceNames {
  const PlaceNames({
    this.isoCountryCode,
    this.administrativeArea,
    this.subAdministrativeArea,
    this.locality,
    this.subLocality,
  });

  final String? isoCountryCode;

  /// Usually the province ("Western Province"), sometimes the district.
  final String? administrativeArea;

  /// Usually the district ("Gampaha" or "Gampaha District").
  final String? subAdministrativeArea;

  /// The town or city ("Negombo").
  final String? locality;

  /// A suburb or neighbourhood, tried after [locality].
  final String? subLocality;
}

/// A district from [AppConstants.sriLankanDistricts] and, when one of its
/// listed towns was named by the geocoder, that town. Both are always the
/// table's own spelling.
class PlaceMatch {
  const PlaceMatch({required this.district, this.city});

  final String district;

  /// Null when no listed town of [district] could be confidently named.
  final String? city;
}

/// Matches reverse-geocoded names against the bundled [SriLankaLocations]
/// table. Nothing is guessed from coordinates: a district or city is only
/// returned when the geocoder named it (allowing for spelling variants).
class SriLankaPlaceMatcher {
  SriLankaPlaceMatcher._();

  /// Common romanisations that differ from the table beyond the [_key]
  /// folding (spaces, hyphens, "th"/"t").
  static const Map<String, String> _districtAliases = {
    'moneragala': 'Monaragala',
    'mullativu': 'Mullaitivu',
    'mullaittivu': 'Mullaitivu',
    'puttlam': 'Puttalam',
    'polonnaruva': 'Polonnaruwa',
    'kegalla': 'Kegalle',
    'trinco': 'Trincomalee',
  };

  static const Map<String, String> _cityAliases = {
    'dehiwala': 'Dehiwala-Mount Lavinia',
    'mountlavinia': 'Dehiwala-Mount Lavinia',
    'mtlavinia': 'Dehiwala-Mount Lavinia',
    'kotte': 'Sri Jayawardenepura Kotte',
    'srijayewardenepurakotte': 'Sri Jayawardenepura Kotte',
    'chavakacheri': 'Chavakachcheri',
  };

  /// Words geocoders add around a name ("Gampaha District").
  static final RegExp _noise = RegExp(
    r'\b(district|divisional secretariat|ds division|municipal council|'
    r'urban council|pradeshiya sabha|province)\b',
  );

  /// Case, spacing, punctuation and "th"/"t" folded away, so "Ja Ela",
  /// "Ja-Ela" and "JaEla", or "Kaluthara" and "Kalutara", compare equal.
  static String _key(String name) => name
      .toLowerCase()
      .replaceAll(_noise, ' ')
      .replaceAll(RegExp(r'[^a-z]'), '')
      .replaceAll('th', 't');

  static final Map<String, String> _districtsByKey = {
    for (final district in AppConstants.sriLankanDistricts)
      _key(district): district,
    for (final MapEntry(key: alias, value: district)
        in _districtAliases.entries)
      _key(alias): district,
  };

  /// Every listed city by key, with the district it belongs to.
  static final Map<String, ({String district, String city})> _citiesByKey = {
    for (final MapEntry(key: district, value: cities)
        in SriLankaLocations.citiesByDistrict.entries)
      for (final city in cities) _key(city): (district: district, city: city),
  };

  /// The table's district for [name], or null.
  static String? district(String? name) =>
      name == null ? null : _districtsByKey[_key(name)];

  /// The listed city for [name] with its district, or null.
  static ({String district, String city})? city(String? name) {
    if (name == null) return null;
    final key = _key(name);
    if (key.isEmpty) return null;
    final alias = _cityAliases[key];
    return _citiesByKey[alias == null ? key : _key(alias)];
  }

  /// Whether [places] name a country other than Sri Lanka.
  static bool isOutsideSriLanka(List<PlaceNames> places) {
    final codes = places
        .map((p) => p.isoCountryCode?.trim().toUpperCase())
        .whereType<String>()
        .where((code) => code.isNotEmpty)
        .toSet();
    return codes.isNotEmpty && !codes.contains('LK');
  }

  /// The district named by [places] (closest place first) and, when one of
  /// its listed towns is named as a locality or suburb, that town.
  ///
  /// A town named without any district fixes the district too, since every
  /// listed town belongs to exactly one district. A town that belongs to a
  /// different district than the one named is ignored, never guessed
  /// across. Returns null when no district can be identified.
  static PlaceMatch? match(List<PlaceNames> places) {
    final inSriLanka = places.where((p) {
      final code = p.isoCountryCode?.trim().toUpperCase();
      return code == null || code.isEmpty || code == 'LK';
    }).toList();

    String? namedDistrict;
    for (final place in inSriLanka) {
      namedDistrict =
          district(place.subAdministrativeArea) ??
          district(place.administrativeArea);
      if (namedDistrict != null) break;
    }

    final towns = [
      for (final place in inSriLanka) ...[
        ?city(place.locality),
        ?city(place.subLocality),
      ],
    ];

    if (namedDistrict == null) {
      // Only a locality-level name, and only if every named town agrees.
      final districts = towns.map((t) => t.district).toSet();
      if (districts.length != 1) return null;
      return PlaceMatch(district: districts.single, city: towns.first.city);
    }
    final town = towns.where((t) => t.district == namedDistrict).firstOrNull;
    return PlaceMatch(district: namedDistrict, city: town?.city);
  }
}
