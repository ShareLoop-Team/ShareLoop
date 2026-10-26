import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/admin_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';

/// View: admin moderation of registered users.
class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => context.read<AdminController>().loadUsers());
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: admin.isLoading
          ? const LoadingIndicator()
          : admin.users.isEmpty
              ? const EmptyState(message: 'No users found.')
              : ListView.builder(
                  itemCount: admin.users.length,
                  itemBuilder: (context, index) {
                    final user = admin.users[index];
                    return ListTile(
                      leading: CircleAvatar(
                          child: Text(user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?')),
                      title: Text(user.name),
                      subtitle: Text('${user.email} · ${user.district}'),
                      trailing: user.isAdmin
                          ? const Chip(label: Text('Admin'))
                          : IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.error),
                              onPressed: () => context
                                  .read<AdminController>()
                                  .removeUser(user.id),
                            ),
                    );
                  },
                ),
    );
  }
}
