import '../../models/category_model.dart';
import '../../models/item_post_model.dart';
import '../../models/user_model.dart';
import '../../services/mock_data_service.dart';
import '../admin_repository.dart';

/// [AdminRepository] over in-memory mock data. Removal is permanent here;
/// the real backend suspends users and hides posts instead.
class MockAdminRepository implements AdminRepository {
  final MockDataService _data = MockDataService.instance;

  @override
  Future<List<UserModel>> getAllUsers() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_data.users);
  }

  @override
  Future<void> removeUser(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _data.users.removeWhere((u) => u.id == id);
  }

  @override
  Future<List<ItemPostModel>> getAllPosts() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_data.itemPosts);
  }

  @override
  Future<void> removePost(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _data.itemPosts.removeWhere((p) => p.id == id);
  }

  @override
  Future<List<CategoryModel>> getAllCategories() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_data.categories);
  }

  @override
  Future<CategoryModel> addCategory(CategoryModel category) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _data.categories.add(category);
    return category;
  }

  @override
  Future<void> removeCategory(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _data.categories.removeWhere((c) => c.id == id);
  }
}
