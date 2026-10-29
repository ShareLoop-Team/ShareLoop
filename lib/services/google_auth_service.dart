import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/config/backend_config.dart';

/// Service: "Sign in with Google" on the device. Produces Google ID tokens
/// (which the backend verifies); it never sees or stores a password.
///
/// On web the sign-in must start from Google's own button (see
/// GoogleSignInButton); on Android/iOS [signIn] opens the account picker.
/// Either way the result arrives on [idTokens].
class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService instance = GoogleAuthService._();

  final _idTokens = StreamController<String>.broadcast();
  final _errors = StreamController<String>.broadcast();
  Future<void>? _initialization;

  /// ID tokens from completed sign-ins.
  Stream<String> get idTokens => _idTokens.stream;

  /// User-facing messages for failed sign-ins (not for a closed popup).
  Stream<String> get errors => _errors.stream;

  Future<void> ensureInitialized() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    final signIn = GoogleSignIn.instance;
    await signIn.initialize(
      // Web uses the client ID directly; Android/iOS ask Google for a token
      // meant for the web (server) client, which the backend accepts.
      clientId: kIsWeb ? BackendConfig.googleClientId : null,
      serverClientId: kIsWeb ? null : BackendConfig.googleClientId,
    );
    signIn.authenticationEvents.listen(
      (event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          final token = event.user.authentication.idToken;
          if (token == null || token.isEmpty) {
            _errors.add('Google did not return a sign-in token. Please try again.');
          } else {
            _idTokens.add(token);
          }
        }
      },
      onError: (Object error) {
        if (error is GoogleSignInException &&
            error.code == GoogleSignInExceptionCode.canceled) {
          return; // the person closed the popup
        }
        _errors.add('Google sign-in failed. Please try again.');
      },
    );
  }

  /// Android/iOS: opens Google's account picker. (Not used on web.)
  Future<void> signIn() async {
    await ensureInitialized();
    try {
      await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled) {
        _errors.add('Google sign-in failed. Please try again.');
      }
    }
  }

  /// Forgets the Google account on this device so the next sign-in can pick
  /// a different one. Safe to call when Google sign-in isn't set up.
  Future<void> signOut() async {
    if (!BackendConfig.isGoogleConfigured || _initialization == null) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Signing out of ShareLoop is what matters.
    }
  }
}
