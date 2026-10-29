import 'package:flutter/widgets.dart';

import '../core/constants/sri_lanka_locations.dart';
import '../core/routes/app_routes.dart';
import 'auth_controller.dart';

/// Controller: state and navigation for the register screen. Creating the
/// account is delegated to [AuthController].
class RegisterController extends ChangeNotifier {
  /// Passwords need at least this many characters.
  static const int minPasswordLength = 6;

  bool obscurePassword = true;
  String? district;

  /// Always one of [district]'s cities, or null.
  String? city;
  bool agreedToTerms = false;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void setAgreedToTerms(bool value) {
    agreedToTerms = value;
    notifyListeners();
  }

  /// Picking another district drops a city that isn't in it.
  void selectDistrict(String? value) {
    district = value;
    city = SriLankaLocations.validCity(value, city);
    notifyListeners();
  }

  void selectCity(String? value) {
    city = SriLankaLocations.validCity(district, value);
    notifyListeners();
  }

  /// Registers and replaces the register screen with home on success. On
  /// failure [AuthController.errorMessage] is set for the View to show.
  Future<void> submit({
    required AuthController auth,
    required NavigatorState navigator,
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    final success = await auth.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
      district: district ?? '',
      city: city ?? '',
    );
    if (success && navigator.mounted) {
      navigator.pushReplacementNamed(AppRoutes.home);
    }
  }

  void openLogin(NavigatorState navigator) {
    navigator.pushReplacementNamed(AppRoutes.login);
  }
}
