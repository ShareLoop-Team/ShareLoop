import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/item_controller.dart';
import '../../controllers/request_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../models/item_request_model.dart';
import '../../widgets/empty_state.dart';

/// View: lets a donor review each requester's stated reason and select
/// exactly one requester for the item.
class IncomingRequestsScreen extends StatelessWidget {
  const IncomingRequestsScreen({super.key, required this.postId});

  final String postId;

  Future<void> _select(BuildContext context, String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select this requester?'),
        content: const Text(
            'The requester\'s contact details will be shared with you so you can arrange handover.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final requestController = context.read<RequestController>();
    final messenger = ScaffoldMessenger.of(context);
    final error =
        await context.read<ItemController>().selectRequester(postId, requestId);
    // Statuses changed server-side (selected approved), so refresh either way.
    await requestController.loadRequests();
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.contactShared,
      arguments: postId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final requests =
        context.watch<RequestController>().requestsForPost(postId);
    return Scaffold(
      appBar: AppBar(title: const Text('Incoming Requests')),
      body: requests.isEmpty
          ? const EmptyState(message: 'No one has requested this item yet.')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(request.requesterName,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text('Reason: ${request.reason}'),
                        if (request.notes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Notes: ${request.notes}'),
                        ],
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: switch (request.status) {
                            ItemRequestStatus.pending => FilledButton(
                                onPressed: () =>
                                    _select(context, request.id),
                                child: const Text('Select Requester'),
                              ),
                            ItemRequestStatus.approved =>
                              const Text('Selected'),
                            ItemRequestStatus.rejected =>
                              const Text('Declined'),
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
