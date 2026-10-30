import '../../models/category_model.dart';
import '../../models/item_post_model.dart';
import '../../models/user_model.dart';
import '../../services/api_client.dart';
import '../admin_repository.dart';
import 'api_rows.dart';

/// [AdminRepository] backed by the Laravel API's /admin routes (admins
/// only). Moderation is reversible: users are suspended, posts hidden.
class ApiAdminRepository implements AdminRepository {
  ApiClient get _api => ApiClient.instance;

  @override
  Future<List<UserModel>> getAllUsers() async {
    final body = await _api.get('/admin/users');
    return [for (final row in ApiRows.list(body)) ApiRows.user(row)];
  }

  @override
  Future<void> removeUser(String id) async {
    await _api.patch('/admin/users/$id/status', {'status': 'suspended'});
  }

  @override
  Future<List<ItemPostModel>> getAllPosts() async {
    final body = await _api.get('/admin/items');
    return [for (final row in ApiRows.list(body)) ApiRows.item(row)];
  }

  @override
  Future<void> removePost(String id) async {
    await _api.patch('/admin/items/$id/hidden', {
      'hidden': true,
      'reason': 'Removed by an admin',
    });
  }

  @override
  Future<List<CategoryModel>> getAllCategories() async {
    final body = await _api.get('/categories');
    return [for (final row in ApiRows.list(body)) ApiRows.category(row)];
  }

  @override
  Future<CategoryModel> addCategory(CategoryModel category) async {
    final body = await _api.post('/admin/categories', {
      'name': category.name,
      'icon_name': category.iconName,
    });
    return ApiRows.category(ApiRows.object(body));
  }

  @override
  Future<void> removeCategory(String id) async {
    await _api.delete('/admin/categories/$id');
  }
}
