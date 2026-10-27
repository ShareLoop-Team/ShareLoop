import 'package:firebase_auth/firebase_auth.dart';

import '../../core/errors/app_exception.dart';
import '../../models/user_model.dart';
import '../../services/backend_service.dart';
import '../user_repository.dart';
import 'supabase_rows.dart';

/// [UserRepository] backed by Firebase Authentication (accounts, sessions,
/// password reset) and the Supabase `profiles` / `profile_contacts` tables.
/// A Firebase account without a profile row is an unfinished registration.
class SupabaseUserRepository implements UserRepository {
  FirebaseAuth get _auth => BackendService.auth;

  Future<UserModel?> _fetchProfile(String id) async {
    final row = await BackendService.client
        .from('profiles')
        .select(SupabaseRows.profileSelect)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : SupabaseRows.user(row);
  }

  /// Returns the signed-in user's profile, signing them out if it is missing
  /// or suspended.
  Future<UserModel> _requireUsableProfile(User firebaseUser) async {
    final profile = await _fetchProfile(firebaseUser.uid);
    if (profile == null) {
      await _auth.signOut();
      throw const AppException(
        'Your registration was not finished. Please register again with '
        'the same email and password.',
      );
    }
    if (profile.isSuspended) {
      await _auth.signOut();
      throw const AppException('This account has been suspended.');
    }
    return profile;
  }

  @override
  Future<UserModel?> login(String email, String password) {
    return BackendService.guard(() async {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _requireUsableProfile(credential.user!);
    });
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String district,
    required String city,
  }) {
    return BackendService.guard(() async {
      UserCredential credential;
      var createdNow = true;
      try {
        credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code != 'email-already-in-use') rethrow;
        // A previous registration may have created the Firebase account but
        // not the profile; finish it if the password proves ownership.
        credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        createdNow = false;
        if (await _fetchProfile(credential.user!.uid) != null) {
          await _auth.signOut();
          throw const AppException(
            'An account already exists for that email. Please sign in.',
          );
        }
      }

      final firebaseUser = credential.user!;
      try {
        await BackendService.client.rpc('create_my_profile', params: {
          'p_display_name': name,
          'p_district': district,
          'p_city': city,
          'p_phone': phone,
        });
      } catch (_) {
        // Don't leave a Firebase account behind that has no profile.
        if (createdNow) {
          await firebaseUser.delete().catchError((_) => _auth.signOut());
        } else {
          await _auth.signOut();
        }
        rethrow;
      }

      try {
        await firebaseUser.sendEmailVerification();
      } catch (_) {
        // Verification is optional; registration has already succeeded.
      }
      return (await _fetchProfile(firebaseUser.uid))!;
    });
  }

  @override
  Future<UserModel?> getCurrentUser() {
    return BackendService.guard(() async {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return null;
      try {
        // Fails if the account was disabled or deleted since last time.
        await firebaseUser.reload();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'network-request-failed') rethrow;
        await _auth.signOut();
        return null;
      }
      final profile = await _fetchProfile(firebaseUser.uid);
      if (profile == null || profile.isSuspended) {
        await _auth.signOut();
        return null;
      }
      return profile;
    });
  }

  @override
  Future<UserModel?> getUserById(String id) {
    return BackendService.guard(() => _fetchProfile(id));
  }

  @override
  Future<List<UserModel>> getAllUsers() {
    return BackendService.guard(() async {
      final rows = await BackendService.client
          .from('profiles')
          .select(SupabaseRows.profileSelect)
          .order('created_at', ascending: false)
          .limit(500);
      return [for (final row in rows) SupabaseRows.user(row)];
    });
  }

  @override
  Future<void> updateUser(UserModel user) {
    return BackendService.guard(() async {
      if (user.id != BackendService.requireUid()) {
        throw const AppException('You can only edit your own profile.');
      }
      final client = BackendService.client;
      await client.from('profiles').update({
        'display_name': user.name,
        'district': user.district,
        'city': user.city,
      }).eq('id', user.id);
      await client
          .from('profile_contacts')
          .update({'phone': user.phone}).eq('user_id', user.id);
    });
  }

  @override
  bool get supportsPasswordReset => true;

  @override
  Future<void> sendPasswordReset(String email) {
    return BackendService.guard(() async {
      try {
        await _auth.sendPasswordResetEmail(email: email);
      } on FirebaseAuthException catch (e) {
        // Don't reveal whether an account exists for the address.
        if (e.code != 'user-not-found') rethrow;
      }
    });
  }

  @override
  Future<void> logout() => _auth.signOut();
}
