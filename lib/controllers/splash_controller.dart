import 'package:flutter/foundation.dart';

import '../core/routes/app_routes.dart';
import 'auth_controller.dart';

/// Controller: decides how long the splash screen is shown and which route
/// to continue to. Holds no widgets — the View owns animation and navigation.
class SplashController {
  /// Minimum time the splash stays visible, counted from the moment
  /// [resolveNextRoute] is called — initialization runs inside this window,
  /// not after it.
  static const Duration minimumDisplayDuration = Duration(seconds: 1);

  /// A restored session goes straight to home; otherwise the splash hands
  /// off to the onboarding/welcome screen, which offers Get started
  /// (register) and Sign in (login).
  ///
  /// Resolves after both session restoration has finished and
  /// [minimumDisplayDuration] has elapsed, whichever is later.
  Future<String> resolveNextRoute(AuthController auth) async {
    final minimumDisplay = Future<void>.delayed(minimumDisplayDuration);
    try {
      await auth.restoreSession();
    } catch (error, stackTrace) {
      // A failed restore just means signing in again, so it must not strand
      // the user on the splash. Report it rather than hiding it.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'splash controller',
          context: ErrorDescription('while restoring the session'),
        ),
      );
    }
    await minimumDisplay;
    return auth.currentUser != null ? AppRoutes.home : AppRoutes.onboarding;
  }
}
