import '../core/config/backend_config.dart';
import '../models/category_model.dart';
import '../models/item_post_model.dart';
import '../models/user_model.dart';
import 'mock/mock_admin_repository.dart';
import 'api/api_admin_repository.dart';

/// Repository: admin moderation (users, posts, categories). The backend
/// only allows these for admin accounts.
abstract class AdminRepository {
  factory AdminRepository() => BackendConfig.isConfigured
      ? ApiAdminRepository()
      : MockAdminRepository();

  /// Active (not suspended) users.
  Future<List<UserModel>> getAllUsers();

  /// Suspends the account; it can be restored from the database.
  Future<void> removeUser(String id);

  /// Posts not hidden by moderation.
  Future<List<ItemPostModel>> getAllPosts();

  /// Hides the post from everyone but its donor.
  Future<void> removePost(String id);

  Future<List<CategoryModel>> getAllCategories();

  Future<CategoryModel> addCategory(CategoryModel category);

  /// Retires the category; posts already using it keep it.
  Future<void> removeCategory(String id);
}
