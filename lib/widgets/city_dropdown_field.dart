import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/sri_lanka_locations.dart';
import '../core/localization/generated/app_localizations.dart';

/// City / town picker that offers only [district]'s cities, from
/// [SriLankaLocations]. Disabled until a district is chosen. Used by both
/// registration and Edit Profile so they validate the same way.
class CityDropdownField extends StatelessWidget {
  const CityDropdownField({
    super.key,
    required this.district,
    required this.value,
    required this.decoration,
    required this.onChanged,
    this.iconColor = AppColors.textSecondary,
  });

  final String? district;

  /// The chosen city; ignored unless it belongs to [district].
  final String? value;
  final InputDecoration decoration;
  final ValueChanged<String?> onChanged;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cities = SriLankaLocations.citiesFor(district);
    return DropdownButtonFormField<String>(
      // A new district starts a fresh field, so a city from the old one
      // never lingers as the selection.
      key: ValueKey('city-$district'),
      initialValue: SriLankaLocations.validCity(district, value),
      decoration: decoration,
      hint: Text(
        cities.isEmpty ? l10n.locationCityNeedsDistrict : l10n.locationCityHint,
        overflow: TextOverflow.ellipsis,
      ),
      isExpanded: true,
      menuMaxHeight: 320,
      borderRadius: BorderRadius.circular(16),
      dropdownColor: AppColors.white,
      icon: Icon(Icons.keyboard_arrow_down, color: iconColor),
      items: [
        for (final city in cities)
          DropdownMenuItem(
            value: city,
            child: Text(city, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: cities.isEmpty ? null : onChanged,
      validator: (value) => SriLankaLocations.isCityIn(district, value)
          ? null
          : l10n.registerCityRequired,
    );
  }
}
