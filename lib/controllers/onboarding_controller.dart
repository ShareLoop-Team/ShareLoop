import 'package:flutter/widgets.dart';

import '../core/routes/app_routes.dart';

/// Controller: navigation for the onboarding/welcome screen. Get started
/// opens login, which links on to registration for new users. The route is
/// pushed on top so the user can come back to onboarding with Back.
class OnboardingController {
  const OnboardingController();

  void getStarted(NavigatorState navigator) {
    navigator.pushNamed(AppRoutes.login);
  }
}
