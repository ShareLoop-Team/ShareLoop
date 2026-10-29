import 'package:flutter/widgets.dart';

import '../core/routes/app_routes.dart';
import '../models/email_code.dart';
import 'auth_controller.dart';

/// Controller: state and navigation for the register screen. Creating the
/// account is delegated to [AuthController].
class RegisterController extends ChangeNotifier {
  /// Passwords need at least this many characters.
  static const int minPasswordLength = 6;

  bool obscurePassword = true;
  String? district;
  bool agreedToTerms = false;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void setAgreedToTerms(bool value) {
    agreedToTerms = value;
    notifyListeners();
  }

  void selectDistrict(String? value) {
    district = value;
    notifyListeners();
  }

  /// Emails a confirmation code and opens the code screen, which creates
  /// the account. On failure [AuthController.errorMessage] is set.
  Future<void> submit({
    required AuthController auth,
    required NavigatorState navigator,
    required String name,
    required String email,
    required String password,
    required String phone,
    required String city,
  }) async {
    final details = PendingRegistration(
      name: name.trim(),
      email: email.trim(),
      password: password,
      phone: phone.trim(),
      district: district ?? '',
      city: city.trim(),
    );
    final ticket = await auth.requestEmailCode(
      details.email,
      EmailCodePurpose.register,
      registration: details,
    );
    if (ticket != null && navigator.mounted) {
      navigator.pushNamed(
        AppRoutes.verifyCode,
        arguments: VerifyCodeArgs(ticket: ticket, registration: details),
      );
    }
  }

  void openLogin(NavigatorState navigator) {
    navigator.pushReplacementNamed(AppRoutes.login);
  }
}
