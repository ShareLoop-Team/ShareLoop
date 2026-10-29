import '../../core/config/backend_config.dart';
import '../../core/errors/app_exception.dart';
import '../../models/item_post_model.dart';
import '../../models/photo_upload.dart';
import '../../services/api_client.dart';
import '../item_post_repository.dart';
import 'api_rows.dart';

/// [ItemPostRepository] backed by the Laravel API. Photos are uploaded with
/// the post in one multipart request and come back as short-lived URLs.
class ApiItemPostRepository implements ItemPostRepository {
  ApiClient get _api => ApiClient.instance;

  List<ItemPostModel> _items(dynamic body) =>
      [for (final row in ApiRows.list(body)) ApiRows.item(row)];

  @override
  Future<List<ItemPostModel>> getAllPosts({
    int limit = BackendConfig.pageSize,
    int offset = 0,
  }) async {
    return _items(
      await _api.get('/items', query: {'limit': limit, 'offset': offset}),
    );
  }

  @override
  Future<List<ItemPostModel>> getPostsByDonor(String donorId) async {
    return _items(await _api.get('/items', query: {'donor_id': donorId}));
  }

  @override
  Future<ItemPostModel?> getPostById(String id) async {
    try {
      return ApiRows.item(ApiRows.object(await _api.get('/items/$id')));
    } on AppException catch (e) {
      if (e.message == 'Item not found.') return null;
      rethrow;
    }
  }

  @override
  Future<ItemPostModel> createPost(
    ItemPostModel post, {
    List<PhotoUpload> photos = const [],
  }) async {
    for (final photo in photos) {
      if (photo.bytes.length > BackendConfig.maxImageBytes) {
        throw const AppException('Each photo must be 5 MB or smaller.');
      }
      final type = photo.mimeType;
      if (type != null && !BackendConfig.allowedImageTypes.contains(type)) {
        throw const AppException('Photos must be JPEG, PNG or WebP.');
      }
    }
    final body = await _api.postMultipart(
      '/items',
      fields: {
        'title': post.title,
        'description': post.description,
        'condition': post.condition,
        'category': post.category,
        'district': post.district,
        'city': post.city,
      },
      photos: photos,
    );
    return ApiRows.item(ApiRows.object(body));
  }

  @override
  Future<void> deletePost(String id) async {
    await _api.delete('/items/$id');
  }
}
