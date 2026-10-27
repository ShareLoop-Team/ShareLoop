import '../core/config/backend_config.dart';
import '../models/user_model.dart';
import 'mock/mock_user_repository.dart';
import 'supabase/supabase_user_repository.dart';

/// Repository: accounts and profiles. Backed by Firebase Authentication +
/// Supabase when [BackendConfig.isConfigured], otherwise by in-memory mock
/// data. Failures the user can act on are thrown as AppException.
abstract class UserRepository {
  factory UserRepository() => BackendConfig.isConfigured
      ? SupabaseUserRepository()
      : MockUserRepository();

  /// Signs in and returns the profile, or null when no account matches.
  Future<UserModel?> login(String email, String password);

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String district,
    required String city,
  });

  /// The signed-in user from a previous session, or null.
  Future<UserModel?> getCurrentUser();

  /// Phone and email are only filled in when the caller may see them
  /// (themselves, an admin, or the other party of a handover).
  Future<UserModel?> getUserById(String id);

  Future<List<UserModel>> getAllUsers();

  /// Saves the signed-in user's editable details (name, phone, location).
  Future<void> updateUser(UserModel user);

  /// Whether [sendPasswordReset] can actually send an email.
  bool get supportsPasswordReset;

  Future<void> sendPasswordReset(String email);

  Future<void> logout();
}
