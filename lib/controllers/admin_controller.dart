import 'package:flutter/foundation.dart';

import '../models/category_model.dart';
import '../models/item_post_model.dart';
import '../models/user_model.dart';
import '../repositories/admin_repository.dart';

/// Controller: coordinates admin moderation actions (users, posts,
/// categories).
class AdminController extends ChangeNotifier {
  AdminController({AdminRepository? repository})
      : _repository = repository ?? AdminRepository();

  final AdminRepository _repository;

  List<UserModel> users = [];
  List<ItemPostModel> posts = [];
  List<CategoryModel> categories = [];
  bool isLoading = false;

  Future<void> loadUsers() async {
    isLoading = true;
    notifyListeners();
    users = await _repository.getAllUsers();
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadPosts() async {
    isLoading = true;
    notifyListeners();
    posts = await _repository.getAllPosts();
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    isLoading = true;
    notifyListeners();
    categories = await _repository.getAllCategories();
    isLoading = false;
    notifyListeners();
  }

  Future<void> removeUser(String id) async {
    await _repository.removeUser(id);
    await loadUsers();
  }

  Future<void> removePost(String id) async {
    await _repository.removePost(id);
    await loadPosts();
  }

  Future<void> addCategory(String name, String iconName) async {
    await _repository.addCategory(
      CategoryModel(
        id: 'c${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        iconName: iconName,
      ),
    );
    await loadCategories();
  }

  Future<void> removeCategory(String id) async {
    await _repository.removeCategory(id);
    await loadCategories();
  }
}
