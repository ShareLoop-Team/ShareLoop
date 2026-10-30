import '../../core/errors/app_exception.dart';
import '../../models/item_post_model.dart';
import '../../models/photo_upload.dart';
import '../../services/mock_data_service.dart';
import '../item_post_repository.dart';

/// [ItemPostRepository] over in-memory mock data. Photos are kept in memory
/// for the current run only.
class MockItemPostRepository implements ItemPostRepository {
  final MockDataService _data = MockDataService.instance;

  /// Fills in the donor's current name, photo, donation count and rating
  /// from their profile, so a new profile photo shows on every post.
  ItemPostModel _withDonor(ItemPostModel post) {
    for (final user in _data.users) {
      if (user.id == post.donorId) {
        return post.copyWith(
          donorName: user.name,
          donorAvatarUrl: user.avatarUrl,
          donorDonationCount: user.donationCount,
          donorRating: user.averageRating,
        );
      }
    }
    return post;
  }

  @override
  Future<List<ItemPostModel>> getAllPosts({
    int limit = 50,
    int offset = 0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(
      _data.itemPosts.reversed.skip(offset).take(limit).map(_withDonor),
    );
  }

  @override
  Future<List<ItemPostModel>> getPostsByDonor(String donorId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _data.itemPosts
        .where((p) => p.donorId == donorId)
        .map(_withDonor)
        .toList();
  }

  @override
  Future<ItemPostModel?> getPostById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _withDonor(_data.itemPosts.firstWhere((p) => p.id == id));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ItemPostModel> createPost(
    ItemPostModel post, {
    List<PhotoUpload> photos = const [],
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final stored = ItemPostModel(
      id: post.id,
      donorId: post.donorId,
      donorName: post.donorName,
      title: post.title,
      description: post.description,
      condition: post.condition,
      category: post.category,
      district: post.district,
      city: post.city,
      photoPaths: [for (final photo in photos) photo.name],
      // Kept in memory as data: URLs so they show without a backend, like
      // profile photos.
      photoUrls: [
        for (final photo in photos)
          Uri.dataFromBytes(
            photo.bytes,
            mimeType: photo.mimeType ?? 'image/jpeg',
          ).toString(),
      ],
      createdAt: post.createdAt,
    );
    _data.itemPosts.add(stored);
    return _withDonor(stored);
  }

  @override
  Future<ItemPostModel> updatePost(
    ItemPostModel post, {
    List<PhotoUpload> newPhotos = const [],
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _data.itemPosts.indexWhere((p) => p.id == post.id);
    if (index == -1) {
      throw const AppException('This item is no longer available.');
    }
    final stored = post.copyWith(
      photoPaths: [
        ...post.photoPaths,
        for (final photo in newPhotos) photo.name,
      ],
      photoUrls: [
        ...post.photoUrls,
        for (final photo in newPhotos)
          Uri.dataFromBytes(
            photo.bytes,
            mimeType: photo.mimeType ?? 'image/jpeg',
          ).toString(),
      ],
    );
    _data.itemPosts[index] = stored;
    return _withDonor(stored);
  }

  @override
  Future<void> deletePost(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _data.itemPosts.removeWhere((p) => p.id == id);
    _data.itemRequests.removeWhere((r) => r.itemPostId == id);
  }
}
