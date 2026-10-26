import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/item_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../models/item_post_model.dart';
import '../../widgets/custom_button.dart';

/// View: full details of a Give Away post with a "Request this item" action
/// for non-owners, or a link to incoming requests for the donor.
class ItemDetailsScreen extends StatelessWidget {
  const ItemDetailsScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    final itemController = context.watch<ItemController>();
    final currentUser = context.watch<AuthController>().currentUser;
    final ItemPostModel? post =
        itemController.posts.where((p) => p.id == postId).firstOrNull ??
            itemController.postsByDonor(currentUser?.id ?? '')
                .where((p) => p.id == postId)
                .firstOrNull;

    if (post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Item Details')),
        body: const Center(child: Text('This item is no longer available.')),
      );
    }

    final isOwner = currentUser != null && currentUser.id == post.donorId;

    return Scaffold(
      appBar: AppBar(title: Text(post.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(post.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text(post.category)),
                Chip(label: Text(post.condition)),
                Chip(label: Text('${post.district}, ${post.city}')),
              ],
            ),
            const SizedBox(height: 16),
            Text(post.description),
            const SizedBox(height: 16),
            Text('Posted by ${post.donorName}',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            if (isOwner)
              CustomButton(
                label: 'View Incoming Requests',
                onPressed: () => Navigator.of(context).pushNamed(
                  AppRoutes.incomingRequests,
                  arguments: post.id,
                ),
              )
            else if (post.status == ItemPostStatus.active)
              CustomButton(
                label: 'Request this item',
                onPressed: () => Navigator.of(context).pushNamed(
                  AppRoutes.createRequest,
                  arguments: post.id,
                ),
              )
            else
              const Text('This item is no longer available for requests.'),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
