import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/item_controller.dart';
import '../../controllers/rating_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/rating_stars.dart';

/// View: star rating and comment submitted after a completed handover.
class RatingReviewScreen extends StatefulWidget {
  const RatingReviewScreen({super.key, required this.postId});

  final String postId;

  @override
  State<RatingReviewScreen> createState() => _RatingReviewScreenState();
}

class _RatingReviewScreenState extends State<RatingReviewScreen> {
  int _stars = 0;
  final _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final currentUser = context.read<AuthController>().currentUser;
    final post = context
        .read<ItemController>()
        .posts
        .where((p) => p.id == widget.postId)
        .firstOrNull;
    if (currentUser == null || post == null) return;

    final rateeId = currentUser.id == post.donorId
        ? post.selectedRequesterId
        : post.donorId;
    if (rateeId == null) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _submitting = true);
    final error = await context.read<RatingController>().submitRating(
          itemPostId: widget.postId,
          raterId: currentUser.id,
          rateeId: rateeId,
          stars: _stars,
          comment: _commentController.text,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate & Review')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Center(
              child: RatingStars(
                rating: _stars.toDouble(),
                size: 40,
                onChanged: (value) => setState(() => _stars = value),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Leave a comment (optional)',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Submit Review',
              isLoading: _submitting,
              onPressed: _stars == 0 ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
