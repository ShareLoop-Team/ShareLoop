import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
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
      _completeSignIn(user);
      return true;
    } on AppException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String district,
    required String city,
  }) async {
    if (name.trim().isEmpty ||
        email.trim().isEmpty ||
        password.isEmpty ||
        phone.trim().isEmpty ||
        district.isEmpty) {
      errorMessage = 'Please fill in all required fields.';
      notifyListeners();
      return false;
    }
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _completeSignIn(
        await _userRepository.register(
          name: name.trim(),
          email: email.trim(),
          password: password,
          phone: phone.trim(),
          district: district,
          city: city.trim(),
        ),
      );
      return true;
    } on AppException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool _justSignedIn = false;

  /// Every successful sign-in ends here (email login and registration
  /// today; Google / Facebook sign-in should call it too once they exist),
  /// so Home knows to run its after-sign-in steps.
  void _completeSignIn(UserModel user) {
    currentUser = user;
    _justSignedIn = true;
  }

  /// True once after each sign-in, then false: lets Home show its
  /// after-sign-in prompt exactly once, never for a restored session.
  bool takeJustSignedIn() {
    final value = _justSignedIn;
    _justSignedIn = false;
    return value;
  }

  /// Restores a signed-in session from a previous launch, if any.
  Future<void> restoreSession() async {
    currentUser = await _userRepository.getCurrentUser();
    notifyListeners();
  }

  /// Replaces the signed-in user after their profile was saved elsewhere
  /// (e.g. a new name or photo), so every screen showing them updates.
  void updateCurrentUser(UserModel user) {
    if (currentUser?.id != user.id) return;
    currentUser = user;
    notifyListeners();
  }

  bool get supportsPasswordReset => _userRepository.supportsPasswordReset;

  /// Emails a password reset link. Returns an error message, or null once
  /// the request has been sent.
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _userRepository.sendPasswordReset(email.trim());
      return null;
    } on AppException catch (e) {
      return e.message;
    }
  }

  Future<void> logout() async {
    currentUser = null;
    _justSignedIn = false;
    notifyListeners();
    await _userRepository.logout();
  }
}
