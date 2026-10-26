import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/item_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_button.dart';

/// View: shown once a donor has selected a requester — reveals the other
/// party's contact details so handover can be arranged in person.
class ContactSharedScreen extends StatefulWidget {
  const ContactSharedScreen({super.key, required this.postId});

  final String postId;

  @override
  State<ContactSharedScreen> createState() => _ContactSharedScreenState();
}

class _ContactSharedScreenState extends State<ContactSharedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadContact());
  }

  Future<void> _loadContact() async {
    final post = context
        .read<ItemController>()
        .posts
        .where((p) => p.id == widget.postId)
        .firstOrNull;
    final requesterId = post?.selectedRequesterId;
    if (requesterId != null) {
      await context.read<ProfileController>().loadProfile(requesterId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final user = profile.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Details')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.handshake_outlined,
                size: 56, color: AppColors.deepGreen),
            const SizedBox(height: 16),
            Text(
              'You can now contact the other party to arrange handover.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (user != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.phone, size: 18),
                        const SizedBox(width: 8),
                        Text(user.phone),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.location_on_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text('${user.city}, ${user.district}'),
                      ]),
                    ],
                  ),
                ),
              )
            else
              const CircularProgressIndicator(),
            const SizedBox(height: 32),
            CustomButton(
              label: 'Mark as Handed Over',
              onPressed: () => Navigator.of(context).pushNamed(
                AppRoutes.handoverConfirmation,
                arguments: widget.postId,
              ),
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
