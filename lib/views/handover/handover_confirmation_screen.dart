import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/item_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/custom_button.dart';

/// View: each party confirms the physical handover. The transaction only
/// completes once both the donor and the requester have confirmed; either
/// way the user then goes on to rate the exchange.
class HandoverConfirmationScreen extends StatefulWidget {
  const HandoverConfirmationScreen({super.key, required this.postId});

  final String postId;

  @override
  State<HandoverConfirmationScreen> createState() =>
      _HandoverConfirmationScreenState();
}

class _HandoverConfirmationScreenState
    extends State<HandoverConfirmationScreen> {
  bool _submitting = false;

  Future<void> _confirm() async {
    final itemController = context.read<ItemController>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _submitting = true);
    final error = await itemController.confirmHandover(widget.postId);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final completed =
        itemController.exchangeFor(widget.postId)?.isCompleted ?? false;
    messenger.showSnackBar(SnackBar(
      content: Text(completed
          ? 'Transaction completed. Thank you for contributing to the '
              'ShareLoop community!'
          : 'Thanks! The exchange completes once the other party confirms '
              'too.'),
    ));
    navigator.pushReplacementNamed(
      AppRoutes.ratingReview,
      arguments: widget.postId,
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
              'Has the item changed hands?',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Both of you confirm once the handover is done. The '
              'transaction completes when you both have.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              label: 'Confirm & Rate this Exchange',
              isLoading: _submitting,
              onPressed: _confirm,
            ),
          ],
        ),
      ),
    );
  }
}
