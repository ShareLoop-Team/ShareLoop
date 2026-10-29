import 'package:firebase_auth/firebase_auth.dart';

import '../../core/errors/app_exception.dart';
import '../../models/photo_upload.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/mock_data_service.dart';
import '../mock/mock_user_repository.dart';
import '../user_repository.dart';

/// [UserRepository] backed by Firebase Authentication for accounts,
/// sessions and password reset. There is no app database, so the profile
/// details Firebase doesn't hold (phone, district, city, photo) live in
/// [MockDataService] for the current run only.
class FirebaseUserRepository implements UserRepository {
  FirebaseUserRepository({FirebaseAuth? auth})
      : _auth = auth ?? AuthService.auth;

  final FirebaseAuth _auth;
  final MockDataService _data = MockDataService.instance;

  /// Profile lookups, edits and photos work the same as in mock mode.
  final MockUserRepository _profiles = MockUserRepository();

  /// The in-memory profile for [firebaseUser], created from what Firebase
  /// knows when this run hasn't seen the account yet (e.g. after a restart).
  UserModel _profileFor(User firebaseUser) {
    final index = _data.users.indexWhere((u) => u.id == firebaseUser.uid);
    if (index != -1) return _data.users[index];
    final email = firebaseUser.email ?? '';
    final displayName = firebaseUser.displayName;
    final user = UserModel(
      id: firebaseUser.uid,
      name: displayName != null && displayName.isNotEmpty
          ? displayName
          : email.split('@').first,
      email: email,
      phone: '',
      district: '',
      city: '',
    );
    _data.users.add(user);
    return user;
  }

  /// Makes [firebaseUser] the signed-in user, refusing suspended profiles.
  Future<UserModel> _signIn(User firebaseUser) async {
    final profile = _profileFor(firebaseUser);
    if (profile.isSuspended) {
      await _auth.signOut();
      throw const AppException('This account has been suspended.');
    }
    _data.currentUserId = profile.id;
    return profile;
  }

  @override
  Future<UserModel?> login(String email, String password) {
    return AuthService.guard(() async {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _signIn(credential.user!);
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
    return AuthService.guard(() async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = credential.user!;
      try {
        // Kept by Firebase, so the name survives a restart.
        await firebaseUser.updateDisplayName(name);
      } catch (_) {
        // Optional; the in-memory profile below has the name anyway.
      }
      try {
        await firebaseUser.sendEmailVerification();
      } catch (_) {
        // Verification is optional; registration has already succeeded.
      }

      final user = UserModel(
        id: firebaseUser.uid,
        name: name,
        email: email,
        phone: phone,
        district: district,
        city: city,
      );
      _data.users
        ..removeWhere((u) => u.id == user.id)
        ..add(user);
      _data.currentUserId = user.id;
      return user;
    });
  }

  @override
  Future<UserModel?> getCurrentUser() {
    return AuthService.guard(() async {
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
      try {
        return await _signIn(_auth.currentUser ?? firebaseUser);
      } on AppException {
        return null;
      }
    });
  }

  @override
  Future<UserModel?> getUserById(String id) => _profiles.getUserById(id);

  @override
  Future<List<UserModel>> getAllUsers() => _profiles.getAllUsers();

  @override
  Future<void> updateUser(UserModel user) {
    return AuthService.guard(() async {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null || user.id != firebaseUser.uid) {
        throw const AppException('You can only edit your own profile.');
      }
      if (user.name != firebaseUser.displayName) {
        await firebaseUser.updateDisplayName(user.name);
      }
      await _profiles.updateUser(user);
    });
  }

  @override
  Future<String?> updateAvatar(String userId, PhotoUpload photo) async {
    if (userId != _auth.currentUser?.uid) {
      throw const AppException('You can only edit your own profile.');
    }
    return _profiles.updateAvatar(userId, photo);
  }

  @override
  bool get supportsPasswordReset => true;

  @override
  Future<void> sendPasswordReset(String email) {
    return AuthService.guard(() async {
      try {
        await _auth.sendPasswordResetEmail(email: email);
      } on FirebaseAuthException catch (e) {
        // Don't reveal whether an account exists for the address.
        if (e.code != 'user-not-found') rethrow;
      }
    });
  }

  @override
  Future<void> logout() async {
    _data.currentUserId = null;
    await _auth.signOut();
  }
}
