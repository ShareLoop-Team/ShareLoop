/// Static reference data shared across the app (categories, districts,
/// item conditions, badge thresholds). Not a Model in the MVC sense —
/// these are fixed app configuration values, not domain records.
library;

class AppConstants {
  AppConstants._();

  static const List<String> itemCategories = [
    'Educational Books',
    'School Supplies',
    'Clothes',
    'Shoes',
    'Electronics',
    'Household Items',
    'Other',
  ];

  static const List<String> itemConditions = ['New', 'Good', 'Used'];

  static const List<String> sriLankanDistricts = [
    'Ampara',
    'Anuradhapura',
    'Badulla',
    'Batticaloa',
    'Colombo',
    'Galle',
    'Gampaha',
    'Hambantota',
    'Jaffna',
    'Kalutara',
    'Kandy',
    'Kegalle',
    'Kilinochchi',
    'Kurunegala',
    'Mannar',
    'Matale',
    'Matara',
    'Monaragala',
    'Mullaitivu',
    'Nuwara Eliya',
    'Polonnaruwa',
    'Puttalam',
    'Ratnapura',
    'Trincomalee',
    'Vavuniya',
  ];

  /// Badge name -> minimum donation count required.
  static const Map<String, int> badgeThresholds = {
    'Bronze': 5,
    'Silver': 10,
    'Gold': 25,
    'Platinum': 50,
  };

  /// Badge name -> recognition level shown on profile.
  static const Map<String, String> badgeLevels = {
    'Bronze': 'New Contributor',
    'Silver': 'Active Contributor',
    'Gold': 'Trusted Contributor',
    'Platinum': 'Community Champion',
  };

  static const List<String> supportedLanguageCodes = ['en', 'si', 'ta'];

  /// Language code -> name shown in the language pickers.
  static const Map<String, String> languageNames = {
    'en': 'English',
    'si': 'Sinhala (සිංහල)',
    'ta': 'Tamil (தமிழ்)',
  };
}
