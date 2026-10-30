import '../core/config/backend_config.dart';
import '../models/category_model.dart';
import '../models/item_post_model.dart';
import '../models/user_model.dart';
import 'mock/mock_admin_repository.dart';
import 'api/api_admin_repository.dart';

/// Repository: admin moderation (users, posts, categories), over in-memory
/// data.
abstract class AdminRepository {
  factory AdminRepository() => BackendConfig.isConfigured
      ? ApiAdminRepository()
      : MockAdminRepository();

  /// Active (not suspended) users.
  Future<List<UserModel>> getAllUsers();

  Future<void> removeUser(String id);

  Future<List<ItemPostModel>> getAllPosts();

  Future<void> removePost(String id);

  Future<List<CategoryModel>> getAllCategories();

  Future<CategoryModel> addCategory(CategoryModel category);

  /// Retires the category; posts already using it keep it.
  Future<void> removeCategory(String id);
}
