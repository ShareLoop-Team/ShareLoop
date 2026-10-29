import 'package:flutter/widgets.dart';

import '../core/routes/app_routes.dart';

/// Controller: navigation for the intro pages shown after the splash.
/// Skip and the last page's button both continue to the welcome screen,
/// replacing the intro so Back does not return to it.
class IntroController {
  const IntroController();

  void finish(NavigatorState navigator) {
    navigator.pushReplacementNamed(AppRoutes.onboarding);
  }
}
