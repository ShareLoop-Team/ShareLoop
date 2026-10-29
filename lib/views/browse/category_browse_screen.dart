import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/item_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/item_card.dart';
import '../../widgets/loading_indicator.dart';

/// View: Give Away posts filtered to a single category.
class CategoryBrowseScreen extends StatefulWidget {
  const CategoryBrowseScreen({super.key, required this.category});

  final String category;

  @override
  State<CategoryBrowseScreen> createState() => _CategoryBrowseScreenState();
}

class _CategoryBrowseScreenState extends State<CategoryBrowseScreen> {
  @override
  Widget build(BuildContext context) {
    final itemController = context.watch<ItemController>();
    final items = itemController.availablePosts
        .where((p) => p.category == widget.category)
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(widget.category)),
      body: itemController.isLoading
          ? const LoadingIndicator()
          : items.isEmpty
              ? const EmptyState(message: 'No items in this category yet.')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final post = items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ItemCard(
                        post: post,
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.itemDetails,
                          arguments: post.id,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
