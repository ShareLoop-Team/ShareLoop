import '../../models/photo_upload.dart';
import '../../core/errors/app_exception.dart';
import '../../models/email_code.dart';
import '../../models/user_model.dart';
import '../../services/mock_data_service.dart';
import '../../services/profile_location_store.dart';
import '../user_repository.dart';

/// [UserRepository] over in-memory mock data. Any password is accepted, and
/// the emailed code is always [mockCode] (shown on the code screen). Each
/// user's district and city are also kept on the device
/// ([ProfileLocationStore]) and restored at sign-in.
class MockUserRepository implements UserRepository {
  MockUserRepository({ProfileLocationStore? locationStore})
    : _locationStore = locationStore ?? const ProfileLocationStore();

  final MockDataService _data = MockDataService.instance;
  final ProfileLocationStore _locationStore;

  /// [user] with the district and city last saved on this device, which
  /// also replaces the in-memory profile.
  Future<UserModel> withSavedLocation(UserModel user) async {
    final saved = await _locationStore.read(user.id);
    if (saved == null ||
        (saved.district == user.district && saved.city == user.city)) {
      return user;
    }
    final restored = user.copyWith(district: saved.district, city: saved.city);
    final index = _data.users.indexWhere((u) => u.id == user.id);
    if (index != -1) _data.users[index] = restored;
    return restored;
  }

  /// Keeps [user]'s district and city on this device.
  Future<void> rememberLocation(UserModel user) async {
    if (user.district.isEmpty) return;
    await _locationStore.write(
      user.id,
      district: user.district,
      city: user.city,
    );
  }

  static const String mockCode = '123456';

  void _checkCode(String code) {
    if (code.trim() != mockCode) {
      throw const AppException("That code isn't right.");
    }
  }

  @override
  Future<EmailCodeTicket> requestEmailCode(
    String email,
    EmailCodePurpose purpose, {
    PendingRegistration? registration,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (purpose == EmailCodePurpose.register &&
        _data.users.any((u) => u.email == email)) {
      throw const AppException(
        'An account already exists for that email. Please sign in.',
      );
    }
    return EmailCodeTicket(
      email: email,
      purpose: purpose,
      debugCode: mockCode,
    );
  }

  @override
  Future<UserModel> loginWithCode(String email, String code) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _checkCode(code);
    for (final user in _data.users) {
      if (user.email == email) {
        _data.currentUserId = user.id;
        return user;
      }
    }
    throw const AppException(
      'That code is no longer valid. Please request a new one.',
    );
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _checkCode(code);
  }

  @override
  Future<UserModel?> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
    for (final user in _data.users) {
      if (user.email == email) {
        _data.currentUserId = user.id;
        return withSavedLocation(user);
      }
    }
    return null;
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String district,
    required String city,
    required String code,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _checkCode(code);
    final user = UserModel(
      id: 'u${_data.users.length + 1}',
      name: name,
      email: email,
      phone: phone,
      district: district,
      city: city,
    );
    _data.users.add(user);
    _data.currentUserId = user.id;
    await rememberLocation(user);
    return user;
  }

  /// Mock data has no Google; treats [idToken] as the email address.
  @override
  Future<Object> signInWithGoogle(
    String idToken, {
    String? name,
    String? phone,
    String? district,
    String? city,
  }) =>
      _socialSignIn(idToken, SocialProvider.google,
          name: name, phone: phone, district: district, city: city);

  /// Mock data has no Facebook; treats [accessToken] as the email address.
  @override
  Future<Object> signInWithFacebook(
    String accessToken, {
    String? name,
    String? phone,
    String? district,
    String? city,
  }) =>
      _socialSignIn(accessToken, SocialProvider.facebook,
          name: name, phone: phone, district: district, city: city);

  Future<Object> _socialSignIn(
    String email,
    SocialProvider provider, {
    String? name,
    String? phone,
    String? district,
    String? city,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    for (final user in _data.users) {
      if (user.email == email) {
        _data.currentUserId = user.id;
        return user;
      }
    }
    if (phone == null || district == null) {
      return GoogleSignUpNeeded(
        idToken: email,
        email: email,
        name: '',
        provider: provider,
      );
    }
    final user = UserModel(
      id: 'u${_data.users.length + 1}',
      name: name ?? email,
      email: email,
      phone: phone,
      district: district,
      city: city ?? '',
    );
    _data.users.add(user);
    _data.currentUserId = user.id;
    return user;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final id = _data.currentUserId;
    if (id == null) return null;
    return getUserById(id);
  }

  @override
  Future<UserModel?> getUserById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      return _data.users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_data.users);
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _data.users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _data.users[index] = user;
    }
    await rememberLocation(user);
  }

  /// Keeps the photo in memory as a data: URL, so it shows without a
  /// backend.
  @override
  Future<String?> updateAvatar(String userId, PhotoUpload photo) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final url = Uri.dataFromBytes(
      photo.bytes,
      mimeType: photo.mimeType ?? 'image/jpeg',
    ).toString();
    final index = _data.users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _data.users[index] = _data.users[index].copyWith(avatarUrl: url);
    }
    return url;
  }

  @override
  Future<void> logout() async {
    _data.currentUserId = null;
  }
}
