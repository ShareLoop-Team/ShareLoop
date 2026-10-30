import 'package:flutter/material.dart';

import '../core/constants/sri_lanka_locations.dart';
import '../core/localization/generated/app_localizations.dart';
import '../core/theme/sl_tokens.dart';

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
    this.iconColor,
    this.textStyle,
  });

  final String? district;

  /// The chosen city; ignored unless it belongs to [district].
  final String? value;
  final InputDecoration decoration;
  final ValueChanged<String?> onChanged;

  /// Defaults to the theme's muted text colour.
  final Color? iconColor;

  /// Style of the chosen city and the hint (the hint in the muted colour).
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sl = context.sl;
    final cities = SriLankaLocations.citiesFor(district);
    return DropdownButtonFormField<String>(
      // A new district starts a fresh field, so a city from the old one
      // never lingers as the selection.
      key: ValueKey('city-$district'),
      initialValue: SriLankaLocations.validCity(district, value),
      decoration: decoration,
      style: textStyle,
      hint: Text(
        cities.isEmpty ? l10n.locationCityNeedsDistrict : l10n.locationCityHint,
        overflow: TextOverflow.ellipsis,
        style: textStyle?.copyWith(color: sl.inkMuted),
      ),
      isExpanded: true,
      menuMaxHeight: 320,
      borderRadius: BorderRadius.circular(16),
      dropdownColor: sl.surface,
      icon: Icon(Icons.keyboard_arrow_down, color: iconColor ?? sl.inkMuted),
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
