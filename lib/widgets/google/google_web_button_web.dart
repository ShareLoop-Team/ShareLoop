import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

/// Google's own "Sign in with Google" button; on web, sign-in has to start
/// from this button.
/// [width] is clamped to the 200-400 px Google allows; [locale] is the
/// app's language (otherwise Google uses the browser's).
Widget buildGoogleWebButton(double width, String locale) => web.renderButton(
      configuration: web.GSIButtonConfiguration(
        type: web.GSIButtonType.standard,
        theme: web.GSIButtonTheme.outline,
        size: web.GSIButtonSize.large,
        text: web.GSIButtonText.continueWith,
        shape: web.GSIButtonShape.rectangular,
        minimumWidth: width.clamp(200, 400),
        locale: locale,
      ),
    );
