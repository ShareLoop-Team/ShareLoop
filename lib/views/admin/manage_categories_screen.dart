import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/admin_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';

/// View: admin management of browsing categories.
class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() =>
      _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<AdminController>().loadCategories());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'New category name',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (_nameController.text.trim().isEmpty) return;
                    context
                        .read<AdminController>()
                        .addCategory(_nameController.text.trim(), 'category');
                    _nameController.clear();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: admin.isLoading
                ? const LoadingIndicator()
                : admin.categories.isEmpty
                    ? const EmptyState(message: 'No categories found.')
                    : ListView.builder(
                        itemCount: admin.categories.length,
                        itemBuilder: (context, index) {
                          final category = admin.categories[index];
                          return ListTile(
                            leading: const Icon(Icons.category_outlined),
                            title: Text(category.name),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.error),
                              onPressed: () => context
                                  .read<AdminController>()
                                  .removeCategory(category.id),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
