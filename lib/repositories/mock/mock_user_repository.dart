import '../../models/user_model.dart';
import '../../services/mock_data_service.dart';
import '../user_repository.dart';

/// [UserRepository] over in-memory mock data. Any password is accepted.
class MockUserRepository implements UserRepository {
  final MockDataService _data = MockDataService.instance;

  @override
  Future<UserModel?> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
    for (final user in _data.users) {
      if (user.email == email) {
        _data.currentUserId = user.id;
        return user;
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
