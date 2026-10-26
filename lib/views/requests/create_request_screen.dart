import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/item_controller.dart';
import '../../controllers/request_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/custom_button.dart';

/// View: create an item request. If [postId] is supplied, this request
/// targets that specific Give Away post ("Request this item"); otherwise
/// it is a standalone need post.
class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key, this.postId});

  final String? postId;

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _reasonController = TextEditingController();
  final _cityController = TextEditingController();
  String _category = AppConstants.itemCategories.first;
  String? _district;
  bool _submitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _reasonController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<AuthController>().currentUser;
    if (user == null) return;

    String category = _category;
    String district = _district ?? user.district;
    String city = _cityController.text.isEmpty ? user.city : _cityController.text;

    if (widget.postId != null) {
      final post = context
          .read<ItemController>()
          .posts
          .where((p) => p.id == widget.postId)
          .firstOrNull;
      if (post != null) {
        category = post.category;
        district = post.district;
        city = post.city;
      }
    } else if (_district == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a district')),
      );
      return;
    }

    setState(() => _submitting = true);
    final error = await context.read<RequestController>().createRequest(
          requesterId: user.id,
          requesterName: user.name,
          itemPostId: widget.postId,
          description: _descriptionController.text,
          reason: _reasonController.text,
          category: category,
          district: district,
          city: city,
        );
    setState(() => _submitting = false);
    if (!mounted) return;
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted.')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTargeted = widget.postId != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Request an Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'What do you need?',
                  hintText: 'e.g. Grade 10 science textbook',
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for needing this item',
                ),
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Reason is required' : null,
              ),
              if (!isTargeted) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: AppConstants.itemCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _category = value ?? _category),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _district,
                  decoration: const InputDecoration(labelText: 'District'),
                  items: AppConstants.sriLankanDistricts
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (value) => setState(() => _district = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'City / Town'),
                ),
              ],
              const SizedBox(height: 24),
              CustomButton(
                label: 'Submit Request',
                isLoading: _submitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
