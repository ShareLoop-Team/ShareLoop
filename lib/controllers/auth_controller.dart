import 'package:flutter/foundation.dart';

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

    final user = await _userRepository.login(email.trim(), password);
    isLoading = false;
    if (user == null) {
      errorMessage = 'No account found for that email.';
      notifyListeners();
      return false;
    }
    currentUser = user;
    _userRepository.setCurrentUser(user.id);
    notifyListeners();
    return true;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String district,
    required String city,
  }) async {
    if (name.trim().isEmpty ||
        email.trim().isEmpty ||
        phone.trim().isEmpty ||
        district.isEmpty) {
      errorMessage = 'Please fill in all required fields.';
      notifyListeners();
      return false;
    }
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final user = await _userRepository.register(
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      district: district,
      city: city.trim(),
    );
    isLoading = false;
    currentUser = user;
    _userRepository.setCurrentUser(user.id);
    notifyListeners();
    return true;
  }

  Future<void> restoreSession() async {
    currentUser = await _userRepository.getCurrentUser();
    notifyListeners();
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }
}
