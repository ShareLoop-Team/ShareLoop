import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/backend_config.dart';
import '../../core/errors/app_exception.dart';
import '../../models/item_post_model.dart';
import '../../models/photo_upload.dart';
import '../../services/backend_service.dart';
import '../item_post_repository.dart';
import 'supabase_rows.dart';

/// [ItemPostRepository] backed by the Supabase `items` table, with photos
/// in the private `item-images` bucket under `<donor uid>/`.
class SupabaseItemPostRepository implements ItemPostRepository {
  SupabaseClient get _client => BackendService.client;

  StorageFileApi get _bucket =>
      _client.storage.from(BackendConfig.itemImagesBucket);

  @override
  Future<List<ItemPostModel>> getAllPosts({
    int limit = BackendConfig.pageSize,
    int offset = 0,
  }) {
    return BackendService.guard(() async {
      final rows = await _client
          .from('items')
          .select(SupabaseRows.itemSelect)
          .eq('is_hidden', false)
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .range(offset, offset + limit - 1);
      return SupabaseRows.items(rows);
    });
  }

  @override
  Future<List<ItemPostModel>> getPostsByDonor(String donorId) {
    return BackendService.guard(() async {
      final rows = await _client
          .from('items')
          .select(SupabaseRows.itemSelect)
          .eq('donor_id', donorId)
          .order('created_at', ascending: false)
          .limit(100);
      return SupabaseRows.items(rows);
    });
  }

  @override
  Future<ItemPostModel?> getPostById(String id) {
    return BackendService.guard(() async {
      final row = await _client
          .from('items')
          .select(SupabaseRows.itemSelect)
          .eq('id', id)
          .maybeSingle();
      if (row == null) return null;
      return (await SupabaseRows.items([row])).first;
    });
  }

  @override
  Future<ItemPostModel> createPost(
    ItemPostModel post, {
    List<PhotoUpload> photos = const [],
  }) {
    return BackendService.guard(() async {
      final uid = BackendService.requireUid();
      final prepared = [for (final photo in photos) _prepare(photo)];

      final uploaded = <String>[];
      try {
        for (final (photo, contentType, extension) in prepared) {
          final path = '$uid/${_randomName()}.$extension';
          await _bucket.uploadBinary(
            path,
            photo.bytes,
            fileOptions: FileOptions(contentType: contentType),
          );
          uploaded.add(path);
        }
        final row = await _client
            .from('items')
            .insert({
              'donor_id': uid,
              'title': post.title,
              'description': post.description,
              'condition': post.condition,
              'category': post.category,
              'district': post.district,
              'city': post.city,
              'image_paths': uploaded,
            })
            .select(SupabaseRows.itemSelect)
            .single();
        return (await SupabaseRows.items([row])).first;
      } catch (_) {
        // Don't leave orphaned photos behind when publishing fails.
        if (uploaded.isNotEmpty) {
          await _bucket.remove(uploaded).catchError((_) => <FileObject>[]);
        }
        rethrow;
      }
    });
  }

  @override
  Future<void> deletePost(String id) {
    return BackendService.guard(() async {
      // Requests for the item are removed by the database (on delete cascade).
      final deleted = await _client
          .from('items')
          .delete()
          .eq('id', id)
          .select('image_paths');
      if (deleted.isEmpty) {
        throw const AppException(
          "This post can't be deleted while a handover is in progress.",
        );
      }
      final paths =
          (deleted.first['image_paths'] as List? ?? const []).cast<String>();
      if (paths.isNotEmpty) {
        await _bucket.remove(paths).catchError((_) => <FileObject>[]);
      }
    });
  }

  /// Validates a photo against the bucket's limits and picks its content
  /// type and file extension.
  static (PhotoUpload, String, String) _prepare(PhotoUpload photo) {
    if (photo.bytes.length > BackendConfig.maxImageBytes) {
      throw const AppException('Each photo must be 5 MB or smaller.');
    }
    final name = photo.name.toLowerCase();
    final contentType = photo.mimeType ??
        (name.endsWith('.png')
            ? 'image/png'
            : name.endsWith('.webp')
                ? 'image/webp'
                : 'image/jpeg');
    if (!BackendConfig.allowedImageTypes.contains(contentType)) {
      throw const AppException('Photos must be JPEG, PNG or WebP.');
    }
    final extension = switch (contentType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
    return (photo, contentType, extension);
  }

  static final Random _random = Random.secure();

  static String _randomName() => [
        for (var i = 0; i < 16; i++)
          _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ].join();
}
