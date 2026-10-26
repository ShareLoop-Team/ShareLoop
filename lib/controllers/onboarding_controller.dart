import 'package:flutter/widgets.dart';

import '../core/routes/app_routes.dart';

/// Controller: navigation for the onboarding/welcome screen. Both routes are
/// pushed on top so the user can come back to onboarding with Back.
class OnboardingController {
  const OnboardingController();

  void openLogin(NavigatorState navigator) {
    navigator.pushNamed(AppRoutes.login);
  }

  void openRegister(NavigatorState navigator) {
    navigator.pushNamed(AppRoutes.register);
  }
}
