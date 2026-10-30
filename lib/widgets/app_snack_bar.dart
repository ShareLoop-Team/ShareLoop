import 'package:flutter/material.dart';

/// Shows [message] at once, replacing any snack bar still on screen, so
/// fresh feedback never waits behind an older message.
void showAppSnackBar(
  ScaffoldMessengerState messenger,
  String message, {
  SnackBarAction? action,
  Duration duration = const Duration(milliseconds: 4000),
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), action: action, duration: duration),
    );
}
