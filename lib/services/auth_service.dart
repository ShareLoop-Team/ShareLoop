import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../firebase_options.dart';

/// Service: starts Firebase Authentication and turns its errors into
/// [AppException]s with user-facing text.
///
/// Firebase is configured for Android and web only (see
/// `firebase_options.dart`). Elsewhere — and in tests, which never call
/// [initialize] — [isAvailable] stays false and sign-in uses the in-memory
/// mock accounts instead.
class AuthService {
  AuthService._();

  static bool _initialized = false;

  static bool get isAvailable => _initialized;

  static bool get _isPlatformConfigured =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.android;

  static Future<void> initialize() async {
    if (!_isPlatformConfigured) return;
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _initialized = true;
  }

  static FirebaseAuth get auth => FirebaseAuth.instance;

  /// Runs [body], converting any failure into an [AppException].
  static Future<T> guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on AppException {
      rethrow;
    } catch (error) {
      throw describe(error);
    }
  }

  static AppException describe(Object error) {
    if (error is AppException) return error;
    if (error is FirebaseAuthException) {
      return AppException(firebaseAuthMessage(error));
    }
    return const AppException(
      'Could not reach ShareLoop. Check your connection and try again.',
    );
  }

  static String firebaseAuthMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'email-already-in-use':
        return 'An account already exists for that email. Please sign in.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No connection. Check your internet and try again.';
      case 'operation-not-allowed':
        return 'Email sign-in is not enabled for ShareLoop yet.';
      default:
        return 'Sign-in failed. Please try again.';
    }
  }
}
