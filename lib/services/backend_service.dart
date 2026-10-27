import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/backend_config.dart';
import '../core/errors/app_exception.dart';
import '../firebase_options.dart';

/// Service: starts Firebase and Supabase and links them — every Supabase
/// request carries the signed-in user's Firebase ID token, which Supabase
/// verifies (Firebase third-party auth) before Row Level Security sees it.
/// Also turns backend errors into [AppException]s with user-facing text.
class BackendService {
  BackendService._();

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await Supabase.initialize(
      url: BackendConfig.supabaseUrl,
      publishableKey: BackendConfig.supabasePublishableKey,
      // getIdToken() refreshes the token itself once it is close to expiry.
      accessToken: () async => FirebaseAuth.instance.currentUser?.getIdToken(),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  static FirebaseAuth get auth => FirebaseAuth.instance;

  /// The signed-in user's Firebase UID; throws if nobody is signed in.
  static String requireUid() {
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      throw const AppException('Please sign in again.');
    }
    return uid;
  }

  /// Runs [body], converting any backend failure into an [AppException].
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
    if (error is PostgrestException) return _describePostgrest(error);
    if (error is StorageException) {
      final status = error.statusCode;
      if (status == '413') {
        return const AppException('That photo is too large (max 5 MB).');
      }
      if (status == '415') {
        return const AppException('Photos must be JPEG, PNG or WebP.');
      }
      if (status == '401' || status == '403') {
        return const AppException('You are not allowed to do that.');
      }
      return const AppException('Could not upload the photo. Please try again.');
    }
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

  // Messages raised by our own SQL functions and triggers are written for
  // users; constraint and permission errors from Postgres itself are not.
  static AppException _describePostgrest(PostgrestException error) {
    final message = error.message;
    final code = error.code;
    if (code == 'PGRST301' || code == 'PGRST303' || message.contains('JWT')) {
      return const AppException('Your session has expired. Please sign in again.');
    }
    if (code == '23505') {
      if (message.contains('item_requests_one_per_item')) {
        return const AppException('You have already requested this item.');
      }
      if (message.contains('reports_one_open')) {
        return const AppException('You have already reported this.');
      }
      if (message.contains('profiles_pkey')) {
        return const AppException('Your profile already exists. Please sign in.');
      }
      return AppException(
        message.startsWith('duplicate key') ? 'That already exists.' : message,
      );
    }
    final isGeneric = message.contains('row-level security') ||
        message.contains('permission denied') ||
        message.contains('violates');
    if (code == '42501' && isGeneric) {
      return const AppException('You are not allowed to do that.');
    }
    if ((code == '23514' || code == '23503' || code == '22P02') && isGeneric) {
      return const AppException('Some of the details are not valid.');
    }
    if (code == 'P0001' ||
        code == 'P0002' ||
        code == '42501' ||
        code == '23514' ||
        code == '23503') {
      return AppException(message);
    }
    return const AppException('Something went wrong. Please try again.');
  }
}
