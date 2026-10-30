import 'package:flutter/widgets.dart';

/// Non-web builds use the app's own button (see GoogleSignInButton).
Widget buildGoogleWebButton(double width, String locale) => const SizedBox.shrink();
