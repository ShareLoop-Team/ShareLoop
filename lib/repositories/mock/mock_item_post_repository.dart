import '../../models/item_post_model.dart';
import '../../models/photo_upload.dart';
import '../../services/mock_data_service.dart';
import '../item_post_repository.dart';

/// [ItemPostRepository] over in-memory mock data. Photos stay on the device
/// (their names are kept as paths) and are not displayed.
class MockItemPostRepository implements ItemPostRepository {
  final MockDataService _data = MockDataService.instance;

  /// Fills in the donor's donation count, as the real backend's join does.
  ItemPostModel _withDonor(ItemPostModel post) {
    for (final user in _data.users) {
      if (user.id == post.donorId) {
        return post.copyWith(donorDonationCount: user.donationCount);
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
      createdAt: post.createdAt,
    );
    _data.itemPosts.add(stored);
    return _withDonor(stored);
  }

  @override
  Future<void> deletePost(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _data.itemPosts.removeWhere((p) => p.id == id);
    _data.itemRequests.removeWhere((r) => r.itemPostId == id);
  }
}
