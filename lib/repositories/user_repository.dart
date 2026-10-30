import '../core/config/backend_config.dart';
import '../models/email_code.dart';
import '../models/photo_upload.dart';
import '../models/user_model.dart';
import 'mock/mock_user_repository.dart';
import 'api/api_user_repository.dart';

/// Repository: accounts and profiles. Backed by the ShareLoop Laravel API
/// when [BackendConfig.isConfigured], otherwise by in-memory mock data. Failures the user can act on are thrown as AppException.
abstract class UserRepository {
  factory UserRepository() => BackendConfig.isConfigured
      ? ApiUserRepository()
      : MockUserRepository();

  /// Signs in and returns the profile, or null when no account matches.
  Future<UserModel?> login(String email, String password);

  /// Emails a one-time code. For [EmailCodePurpose.register], [registration]
  /// lets the backend check the form before sending.
  Future<EmailCodeTicket> requestEmailCode(
    String email,
    EmailCodePurpose purpose, {
    PendingRegistration? registration,
  });

  /// Creates the account; [code] is the one emailed for registration.
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String district,
    required String city,
    required String code,
  });

  /// Signs in with an emailed code instead of the password.
  Future<UserModel> loginWithCode(String email, String code);

  /// Sets a new password with an emailed code (signs out other devices).
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  /// The signed-in user from a previous session, or null.
  /// Signs in with a Google ID token. Returns the user, or
  /// [GoogleSignUpNeeded] when this is a new person (call again with
  /// [phone] and [district] to create the account).
  Future<Object> signInWithGoogle(
    String idToken, {
    String? name,
    String? phone,
    String? district,
    String? city,
  });

  /// Signs in with a Facebook user access token. Same contract as
  /// [signInWithGoogle] (the pending result has provider facebook).
  Future<Object> signInWithFacebook(
    String accessToken, {
    String? name,
    String? phone,
    String? district,
    String? city,
  });

  Future<UserModel?> getCurrentUser();

  /// Phone and email are only filled in when the caller may see them
  /// (themselves, an admin, or the other party of a handover).
  Future<UserModel?> getUserById(String id);

  Future<List<UserModel>> getAllUsers();

  /// Saves the signed-in user's editable details (name, phone, location).
  Future<void> updateUser(UserModel user);

  /// Replaces the signed-in user's profile photo and returns its new
  /// displayable URL (null if it saved but can't be shown right now).
  Future<String?> updateAvatar(String userId, PhotoUpload photo);
  Future<void> logout();
}
