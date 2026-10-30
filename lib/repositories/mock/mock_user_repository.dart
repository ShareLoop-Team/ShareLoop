import '../../models/photo_upload.dart';
import '../../models/user_model.dart';
import '../../services/mock_data_service.dart';
import '../../services/profile_location_store.dart';
import '../user_repository.dart';

/// [UserRepository] over in-memory mock data. Any password is accepted.
/// Each user's district and city are also kept on the device
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
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
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
  bool get supportsPasswordReset => false;

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> logout() async {
    _data.currentUserId = null;
  }
}
