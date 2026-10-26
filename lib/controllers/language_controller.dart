import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

/// Controller: coordinates the app's active language/Locale selection for
/// Settings. Views read [locale] via Provider and rebuild on change.
class LanguageController extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void setLanguage(String languageCode) {
    if (!AppConstants.supportedLanguageCodes.contains(languageCode)) return;
    _locale = Locale(languageCode);
    notifyListeners();
  }
}
