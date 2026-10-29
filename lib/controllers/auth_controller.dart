import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../models/email_code.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

/// Controller: coordinates login/registration user actions, validation,
/// and current-session state. Views call these methods; the Model
/// (UserModel) and data access (UserRepository) stay out of the View.
class AuthController extends ChangeNotifier {
  AuthController({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepository();

  final UserRepository _userRepository;

  UserModel? currentUser;
  bool isLoading = false;
  String? errorMessage;

  Future<bool> login(String email, String password) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      errorMessage = 'Email and password are required.';
      notifyListeners();
      return false;
    }
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final user = await _userRepository.login(email.trim(), password);
      if (user == null) {
        errorMessage = 'No account found for that email.';
        return false;
      }
      currentUser = user;
      return true;
    } on AppException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Runs [action] with loading state; failures become [errorMessage].
  Future<T?> _run<T>(Future<T> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      return await action();
    } on AppException catch (e) {
      errorMessage = e.message;
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Emails a one-time code. Returns null (and sets [errorMessage]) on failure.
  Future<EmailCodeTicket?> requestEmailCode(
    String email,
    EmailCodePurpose purpose, {
    PendingRegistration? registration,
  }) {
    if (email.trim().isEmpty) {
      errorMessage = 'Email is required.';
      notifyListeners();
      return Future.value();
    }
    return _run(() => _userRepository.requestEmailCode(
          email.trim(),
          purpose,
          registration: registration,
        ));
  }

  /// Creates the account with the emailed [code] and signs in.
  Future<bool> register(PendingRegistration details, String code) async {
    if (details.name.trim().isEmpty ||
        details.email.trim().isEmpty ||
        details.password.isEmpty ||
        details.phone.trim().isEmpty ||
        details.district.isEmpty) {
      errorMessage = 'Please fill in all required fields.';
      notifyListeners();
      return false;
    }
    final user = await _run(() => _userRepository.register(
          name: details.name.trim(),
          email: details.email.trim(),
          password: details.password,
          phone: details.phone.trim(),
          district: details.district,
          city: details.city.trim(),
          code: code.trim(),
        ));
    if (user == null) return false;
    currentUser = user;
    notifyListeners();
    return true;
  }

  /// Signs in with an emailed code instead of the password.
  Future<bool> loginWithCode(String email, String code) async {
    final user = await _run(
      () => _userRepository.loginWithCode(email.trim(), code.trim()),
    );
    if (user == null) return false;
    currentUser = user;
    notifyListeners();
    return true;
  }

  /// Sets a new password with an emailed code. Returns whether it worked.
  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final done = await _run(() async {
      await _userRepository.resetPassword(
        email: email.trim(),
        code: code.trim(),
        newPassword: newPassword,
      );
      return true;
    });
    return done ?? false;
  }

  /// Signs in with a Google ID token. Returns the signed-in user, a
  /// [GoogleSignUpNeeded] for a new person, or null (see [errorMessage]).
  Future<Object?> signInWithGoogle(String idToken) async {
    final result = await _run(() => _userRepository.signInWithGoogle(idToken));
    if (result is UserModel) {
      currentUser = result;
      notifyListeners();
    }
    return result;
  }

  /// Creates the account for a new Google user with their phone/district.
  Future<bool> completeGoogleSignUp(
    GoogleSignUpNeeded pending, {
    required String name,
    required String phone,
    required String district,
    required String city,
  }) async {
    final result = await _run(() => _userRepository.signInWithGoogle(
          pending.idToken,
          name: name.trim(),
          phone: phone.trim(),
          district: district,
          city: city.trim(),
        ));
    if (result is! UserModel) {
      if (result is GoogleSignUpNeeded) {
        errorMessage = 'Please fill in all required fields.';
        notifyListeners();
      }
      return false;
    }
    currentUser = result;
    notifyListeners();
    return true;
  }

  /// Shows an error from outside the repositories (e.g. Google's popup).
  void reportError(String message) {
    errorMessage = message;
    notifyListeners();
  }

  /// Clears an error left by a previous screen.
  void clearError() {
    if (errorMessage == null) return;
    errorMessage = null;
    notifyListeners();
  }

  /// Restores a signed-in session from a previous launch, if any.
  Future<void> restoreSession() async {
    currentUser = await _userRepository.getCurrentUser();
    notifyListeners();
  }

  Future<void> logout() async {
    currentUser = null;
    notifyListeners();
    await _userRepository.logout();
  }
}
