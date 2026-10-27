import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
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
  String? errorMessage;

  /// Runs [action] with loading state, keeping its error for the View.
  Future<void> _run(Future<void> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUsers() =>
      _run(() async => users = await _repository.getAllUsers());

  Future<void> loadPosts() =>
      _run(() async => posts = await _repository.getAllPosts());

  Future<void> loadCategories() =>
      _run(() async => categories = await _repository.getAllCategories());

  Future<void> removeUser(String id) => _run(() async {
        await _repository.removeUser(id);
        users = await _repository.getAllUsers();
      });

  Future<void> removePost(String id) => _run(() async {
        await _repository.removePost(id);
        posts = await _repository.getAllPosts();
      });

  Future<void> addCategory(String name, String iconName) => _run(() async {
        await _repository.addCategory(
          CategoryModel(
            id: 'c${DateTime.now().microsecondsSinceEpoch}',
            name: name,
            iconName: iconName,
          ),
        );
        categories = await _repository.getAllCategories();
      });

  Future<void> removeCategory(String id) => _run(() async {
        await _repository.removeCategory(id);
        categories = await _repository.getAllCategories();
      });
}
