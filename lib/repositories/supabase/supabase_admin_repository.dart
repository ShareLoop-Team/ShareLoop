import '../../models/category_model.dart';
import '../../models/item_post_model.dart';
import '../../models/user_model.dart';
import '../../services/backend_service.dart';
import '../admin_repository.dart';
import 'supabase_rows.dart';

/// [AdminRepository] backed by the admin_* functions and admin-only RLS
/// policies. Moderation is reversible: users are suspended and posts
/// hidden rather than deleted.
class SupabaseAdminRepository implements AdminRepository {
  @override
  Future<List<UserModel>> getAllUsers() {
    return BackendService.guard(() async {
      final rows = await BackendService.client
          .from('profiles')
          .select(SupabaseRows.profileSelect)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(500);
      return [for (final row in rows) SupabaseRows.user(row)];
    });
  }

  @override
  Future<void> removeUser(String id) {
    return BackendService.guard(() => BackendService.client.rpc(
          'admin_set_user_status',
          params: {'p_user_id': id, 'p_status': 'suspended'},
        ));
  }

  @override
  Future<List<ItemPostModel>> getAllPosts() {
    return BackendService.guard(() async {
      final rows = await BackendService.client
          .from('items')
          .select(SupabaseRows.itemSelect)
          .eq('is_hidden', false)
          .order('created_at', ascending: false)
          .limit(200);
      return SupabaseRows.items(rows);
    });
  }

  @override
  Future<void> removePost(String id) {
    return BackendService.guard(() => BackendService.client.rpc(
          'admin_set_item_hidden',
          params: {
            'p_item_id': id,
            'p_hidden': true,
            'p_reason': 'Removed by an admin',
          },
        ));
  }

  @override
  Future<List<CategoryModel>> getAllCategories() {
    return BackendService.guard(() async {
      final rows = await BackendService.client
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('sort_order')
          .order('name');
      return [
        for (final row in rows)
          CategoryModel(
            id: row['id'] as String,
            name: row['name'] as String,
            iconName: row['icon_name'] as String,
          ),
      ];
    });
  }

  @override
  Future<CategoryModel> addCategory(CategoryModel category) {
    return BackendService.guard(() async {
      await BackendService.client.from('categories').insert({
        'id': category.id,
        'name': category.name,
        'icon_name': category.iconName,
        'sort_order': 1000,
      });
      return category;
    });
  }

  @override
  Future<void> removeCategory(String id) {
    return BackendService.guard(() => BackendService.client
        .from('categories')
        .update({'is_active': false}).eq('id', id));
  }
}
