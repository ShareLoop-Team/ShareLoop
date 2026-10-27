import '../core/config/backend_config.dart';
import '../models/item_post_model.dart';
import '../models/photo_upload.dart';
import 'mock/mock_item_post_repository.dart';
import 'supabase/supabase_item_post_repository.dart';

/// Repository: "Give Away" posts and their photos.
abstract class ItemPostRepository {
  factory ItemPostRepository() => BackendConfig.isConfigured
      ? SupabaseItemPostRepository()
      : MockItemPostRepository();

  /// Newest first, one page at a time.
  Future<List<ItemPostModel>> getAllPosts({
    int limit = BackendConfig.pageSize,
    int offset = 0,
  });

  Future<List<ItemPostModel>> getPostsByDonor(String donorId);

  Future<ItemPostModel?> getPostById(String id);

  /// Uploads [photos] and publishes the post; the returned post carries the
  /// stored photo paths.
  Future<ItemPostModel> createPost(
    ItemPostModel post, {
    List<PhotoUpload> photos = const [],
  });

  /// Also drops requests made for this post, so requesters aren't left
  /// waiting on an item that's gone.
  Future<void> deletePost(String id);
}
