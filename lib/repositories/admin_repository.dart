import '../models/category_model.dart';
import '../models/item_post_model.dart';
import '../models/user_model.dart';
import '../services/mock_data_service.dart';

/// Repository: mock data access for admin moderation (users, posts,
/// categories).
class AdminRepository {
  final MockDataService _data = MockDataService.instance;

  Future<List<UserModel>> getAllUsers() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_data.users);
  }

  Future<void> removeUser(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _data.users.removeWhere((u) => u.id == id);
  }

  Future<List<ItemPostModel>> getAllPosts() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_data.itemPosts);
  }

  Future<void> removePost(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _data.itemPosts.removeWhere((p) => p.id == id);
  }

  Future<List<CategoryModel>> getAllCategories() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_data.categories);
  }

  Future<CategoryModel> addCategory(CategoryModel category) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _data.categories.add(category);
    return category;
  }

  Future<void> removeCategory(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _data.categories.removeWhere((c) => c.id == id);
  }
}
