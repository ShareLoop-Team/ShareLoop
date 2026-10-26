import 'package:flutter/widgets.dart';

import '../core/routes/app_routes.dart';
import 'auth_controller.dart';

/// Controller: state and navigation for the register screen. Creating the
/// account is delegated to [AuthController].
class RegisterController extends ChangeNotifier {
  /// Passwords need at least this many characters.
  static const int minPasswordLength = 6;

  bool obscurePassword = true;
  String? district;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void selectDistrict(String? value) {
    district = value;
    notifyListeners();
  }

  /// Registers and replaces the register screen with home on success. On
  /// failure [AuthController.errorMessage] is set for the View to show.
  ///
  /// The password is validated by the View but not stored: the user
  /// repository has no password field yet.
  Future<void> submit({
    required AuthController auth,
    required NavigatorState navigator,
    required String name,
    required String email,
    required String phone,
    required String city,
  }) async {
    final success = await auth.register(
      name: name,
      email: email,
      phone: phone,
      district: district ?? '',
      city: city,
    );
    if (success && navigator.mounted) {
      navigator.pushReplacementNamed(AppRoutes.home);
    }
  }

  void openLogin(NavigatorState navigator) {
    navigator.pushReplacementNamed(AppRoutes.login);
  }
}
