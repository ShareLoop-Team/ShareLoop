import '../models/user_model.dart';
import '../services/mock_data_service.dart';

/// Repository: mock data access for users. Mimics the async, nullable-result
/// shape of a future REST API so controllers don't change when a real
/// backend replaces [MockDataService].
class UserRepository {
  final MockDataService _data = MockDataService.instance;

  Future<UserModel?> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _data.users.firstWhere((u) => u.email == email);
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> register({
    required String name,
    required String email,
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
    return user;
  }

  Future<UserModel?> getCurrentUser() async {
    final id = _data.currentUserId;
    if (id == null) return null;
    return getUserById(id);
  }

  Future<UserModel?> getUserById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      return _data.users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_data.users);
  }

  Future<void> updateUser(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _data.users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _data.users[index] = user;
    }
  }

  void setCurrentUser(String id) {
    _data.currentUserId = id;
  }
}
