import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/item_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/custom_button.dart';

/// View: confirms the physical handover is complete and marks the
/// transaction finished before prompting for a rating.
class HandoverConfirmationScreen extends StatelessWidget {
  const HandoverConfirmationScreen({super.key, required this.postId});

  final String postId;

  Future<void> _confirm(BuildContext context) async {
    await context.read<ItemController>().markCompleted(postId);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.ratingReview,
      arguments: postId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Handover')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 72, color: AppColors.deepGreen),
            const SizedBox(height: 16),
            Text(
              'Transaction Completed',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Thank you for contributing to the ShareLoop community!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              label: 'Rate this Exchange',
              onPressed: () => _confirm(context),
            ),
          ],
        ),
      ),
    );
  }
}
