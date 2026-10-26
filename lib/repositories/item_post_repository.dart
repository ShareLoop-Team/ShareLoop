import '../models/item_post_model.dart';
import '../services/mock_data_service.dart';

/// Repository: mock data access for "Give Away" posts.
class ItemPostRepository {
  final MockDataService _data = MockDataService.instance;

  Future<List<ItemPostModel>> getAllPosts() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_data.itemPosts.reversed);
  }

  Future<List<ItemPostModel>> getPostsByDonor(String donorId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _data.itemPosts.where((p) => p.donorId == donorId).toList();
  }

  Future<ItemPostModel?> getPostById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _data.itemPosts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<ItemPostModel> createPost(ItemPostModel post) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _data.itemPosts.add(post);
    return post;
  }

  Future<void> updatePost(ItemPostModel post) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _data.itemPosts.indexWhere((p) => p.id == post.id);
    if (index != -1) {
      _data.itemPosts[index] = post;
    }
  }

  Future<void> deletePost(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _data.itemPosts.removeWhere((p) => p.id == id);
  }
}
