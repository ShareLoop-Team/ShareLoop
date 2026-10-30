import '../core/config/backend_config.dart';
import '../models/item_post_model.dart';
import '../models/photo_upload.dart';
import 'mock/mock_item_post_repository.dart';
import 'api/api_item_post_repository.dart';

/// Repository: "Give Away" posts and their photos, held in memory.
abstract class ItemPostRepository {
  factory ItemPostRepository() => BackendConfig.isConfigured
      ? ApiItemPostRepository()
      : MockItemPostRepository();

  /// Posts fetched per feed page.
  static const int pageSize = BackendConfig.pageSize;

  /// Newest first, one page at a time.
  Future<List<ItemPostModel>> getAllPosts({
    int limit = pageSize,
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

  /// Saves the donor's edits to [post]. Its photo lists are the photos
  /// kept; [newPhotos] are uploaded and added after them.
  Future<ItemPostModel> updatePost(
    ItemPostModel post, {
    List<PhotoUpload> newPhotos = const [],
  });

  /// Also drops requests made for this post, so requesters aren't left
  /// waiting on an item that's gone.
  Future<void> deletePost(String id);
}
