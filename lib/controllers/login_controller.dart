import 'package:flutter/widgets.dart';

import '../core/routes/app_routes.dart';
import '../models/email_code.dart';
import 'auth_controller.dart';

/// Controller: state and navigation for the login screen. The actual
/// credential check is delegated to [AuthController].
class LoginController extends ChangeNotifier {
  bool obscurePassword = true;

  /// UI-only: the app always keeps the session (API token) until the user
  /// logs out, so this value is not stored anywhere.
  bool rememberMe = false;

  void setRememberMe(bool value) {
    rememberMe = value;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  /// Logs in and replaces the login screen with home on success. On failure
  /// [AuthController.errorMessage] is set for the View to show.
  Future<void> submit({
    required AuthController auth,
    required NavigatorState navigator,
    required String email,
    required String password,
  }) async {
    final success = await auth.login(email, password);
    if (success && navigator.mounted) {
      navigator.pushReplacementNamed(AppRoutes.home);
    }
  }

  /// Emails a sign-in or password-reset code to [email] and opens the code
  /// screen. On failure [AuthController.errorMessage] is set.
  Future<void> requestCode({
    required AuthController auth,
    required NavigatorState navigator,
    required String email,
    required EmailCodePurpose purpose,
  }) async {
    final ticket = await auth.requestEmailCode(email, purpose);
    if (ticket != null && navigator.mounted) {
      navigator.pushNamed(
        AppRoutes.verifyCode,
        arguments: VerifyCodeArgs(ticket: ticket),
      );
    }
  }

  /// Replaces login with register (and register's "Sign In" does the reverse)
  /// so switching back and forth never stacks duplicate screens.
  void openRegister(NavigatorState navigator) {
    navigator.pushReplacementNamed(AppRoutes.register);
  }
}
