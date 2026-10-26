import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/admin_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/item_card.dart';
import '../../widgets/loading_indicator.dart';

/// View: admin moderation of Give Away posts (removal only in this mock).
class ModeratePostsScreen extends StatefulWidget {
  const ModeratePostsScreen({super.key});

  @override
  State<ModeratePostsScreen> createState() => _ModeratePostsScreenState();
}

class _ModeratePostsScreenState extends State<ModeratePostsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => context.read<AdminController>().loadPosts());
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Moderate Posts')),
      body: admin.isLoading
          ? const LoadingIndicator()
          : admin.posts.isEmpty
              ? const EmptyState(message: 'No posts to moderate.')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: admin.posts.length,
                  itemBuilder: (context, index) {
                    final post = admin.posts[index];
                    return Dismissible(
                      key: ValueKey(post.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        color: AppColors.error,
                        child: const Icon(Icons.delete, color: AppColors.white),
                      ),
                      onDismissed: (_) =>
                          context.read<AdminController>().removePost(post.id),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ItemCard(post: post, onTap: () {}),
                      ),
                    );
                  },
                ),
    );
  }
}
