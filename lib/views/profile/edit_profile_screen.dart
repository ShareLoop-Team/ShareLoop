import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/profile_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/custom_button.dart';

/// View: edit the signed-in user's profile details.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;
  String? _district;
  bool _initialized = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final success = await context.read<ProfileController>().updateProfile(
          name: _nameController.text,
          phone: _phoneController.text,
          district: _district ?? '',
          city: _cityController.text,
        );
    setState(() => _submitting = false);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check the form and try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ProfileController>().user;
    if (!_initialized && user != null) {
      _nameController = TextEditingController(text: user.name);
      _phoneController = TextEditingController(text: user.phone);
      _cityController = TextEditingController(text: user.city);
      _district = user.district;
      _initialized = true;
    }
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Phone is required' : null,
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
              const SizedBox(height: 24),
              CustomButton(
                label: 'Save Changes',
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
