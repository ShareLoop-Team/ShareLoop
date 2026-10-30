import 'generated/app_localizations.dart';

/// Display names for the app's fixed data values (categories, item
/// conditions, badges and badge levels). The stored values stay English;
/// only what is shown changes with the language. User-written content
/// (titles, descriptions, names) is never translated.
///
/// An unknown value (e.g. an old category) is shown as stored.
extension DataLabels on AppLocalizations {
  String category(String value) => switch (value) {
    'Educational Books' => categoryEducationalBooks,
    'School Supplies' => categorySchoolSupplies,
    'Clothes' => categoryClothes,
    'Shoes' => categoryShoes,
    'Electronics' => categoryElectronics,
    'Household Items' => categoryHouseholdItems,
    'Other' => categoryOther,
    _ => value,
  };

  String condition(String value) => switch (value) {
    'New' => conditionNew,
    'Good' => conditionGood,
    'Used' => conditionUsed,
    _ => value,
  };

  String badge(String value) => switch (value) {
    'Bronze' => badgeBronze,
    'Silver' => badgeSilver,
    'Gold' => badgeGold,
    'Platinum' => badgePlatinum,
    _ => value,
  };

  String badgeLevel(String value) => switch (value) {
    'New Contributor' => badgeLevelNew,
    'Active Contributor' => badgeLevelActive,
    'Trusted Contributor' => badgeLevelTrusted,
    'Community Champion' => badgeLevelChampion,
    _ => value,
  };
}
