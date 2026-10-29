import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/photo_upload.dart';
import '../../widgets/camera_capture.dart';
import '../../widgets/info_note.dart';
import '../../widgets/photo_source_sheet.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/subpage_header.dart';
import '../../widgets/user_avatar.dart';

/// View: edit the signed-in user's photo, name, phone and location. Email
/// is shown but locked. Saving goes through [ProfileController].
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  /// Same rule as the database: optional +, then 7–20 digits or spaces.
  static final RegExp _phonePattern = RegExp(r'^\+?[0-9 ]{7,20}$');

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;
  String? _district;
  bool _initialized = false;
  bool _submitting = false;

  /// A newly picked photo, uploaded only when the user saves.
  XFile? _photo;
  Uint8List? _photoBytes;

  @override
  void dispose() {
    if (_initialized) {
      _nameController.dispose();
      _phoneController.dispose();
      _cityController.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showPhotoSourceSheet(context);
    if (source == null || !mounted) return;

    // A profile photo is shown small, so 800px keeps it light.
    final file = source == ImageSource.camera
        ? await takePhoto(context, maxWidth: 800, maxHeight: 800)
        : await ImagePicker().pickImage(
            source: ImageSource.gallery,
            maxWidth: 800,
            maxHeight: 800,
            imageQuality: 85,
          );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _photo = file;
      _photoBytes = bytes;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final profile = context.read<ProfileController>();
    final auth = context.read<AuthController>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _submitting = true);
    final photo = _photo;
    final success = await profile.updateProfile(
      name: _nameController.text,
      phone: _phoneController.text,
      district: _district ?? '',
      city: _cityController.text,
      photo: photo == null
          ? null
          : PhotoUpload(
              bytes: _photoBytes!,
              mimeType: photo.mimeType,
              name: photo.name,
            ),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (success) {
      auth.updateCurrentUser(profile.user!);
      messenger.showSnackBar(SnackBar(content: Text(l10n.editProfileSaved)));
      navigator.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(profile.errorMessage ?? l10n.editProfileFailed)),
      );
    }
  }

  String? Function(String?) _required(String message) =>
      (value) => (value == null || value.trim().isEmpty) ? message : null;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ProfileController>().user;
    if (!_initialized && user != null) {
      _nameController = TextEditingController(text: user.name);
      _phoneController = TextEditingController(text: user.phone);
      _cityController = TextEditingController(text: user.city);
      _district = AppConstants.sriLankanDistricts.contains(user.district)
          ? user.district
          : null;
      _initialized = true;
    }
    if (!_initialized || user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const CircleBackButton(),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text(
                                l10n.profileEditProfile,
                                style: textTheme.headlineSmall?.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _PhotoPicker(
                        url: user.avatarUrl,
                        previewBytes: _photoBytes,
                        label: l10n.editProfileChangePhoto,
                        onTap: _submitting ? null : _pickPhoto,
                      ),
                      const SizedBox(height: 24),
                      _Field(
                        label: l10n.registerNameLabel,
                        child: TextFormField(
                          controller: _nameController,
                          decoration: _decoration(),
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          validator: _required(l10n.registerNameRequired),
                        ),
                      ),
                      _Field(
                        label: l10n.loginEmailLabel,
                        helper: l10n.editProfileEmailLocked,
                        child: TextFormField(
                          initialValue: user.email,
                          enabled: false,
                          decoration: _decoration(locked: true),
                        ),
                      ),
                      _Field(
                        label: l10n.registerPhoneLabel,
                        child: TextFormField(
                          controller: _phoneController,
                          decoration: _decoration(),
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          validator: (value) {
                            final phone = value?.trim() ?? '';
                            if (phone.isEmpty) {
                              return l10n.registerPhoneRequired;
                            }
                            if (!_phonePattern.hasMatch(phone)) {
                              return l10n.editProfilePhoneInvalid;
                            }
                            return null;
                          },
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _Field(
                              label: l10n.registerDistrictLabel,
                              child: DropdownButtonFormField<String>(
                                initialValue: _district,
                                decoration: _decoration(),
                                hint: Text(l10n.registerDistrictHint),
                                isExpanded: true,
                                borderRadius: BorderRadius.circular(16),
                                dropdownColor: AppColors.white,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: AppColors.ink,
                                ),
                                items: [
                                  for (final d
                                      in AppConstants.sriLankanDistricts)
                                    DropdownMenuItem(
                                      value: d,
                                      child: Text(
                                        d,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                                onChanged: (value) =>
                                    setState(() => _district = value),
                                validator: (value) => value == null
                                    ? l10n.registerDistrictRequired
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _Field(
                              label: l10n.registerCityLabel,
                              child: TextFormField(
                                controller: _cityController,
                                decoration: _decoration(),
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [
                                  AutofillHints.addressCity,
                                ],
                                validator: _required(l10n.registerCityRequired),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      InfoNote(text: l10n.editProfilePhoneNote),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: BottomActionBar(
          children: [
            PillButton(
              label: l10n.editProfileSave,
              isLoading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  /// White rounded field with a light border; [locked] is the grey,
  /// read-only email field with a lock icon.
  static InputDecoration _decoration({bool locked = false}) {
    OutlineInputBorder border(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      filled: true,
      fillColor: locked ? AppColors.mutedSurface : AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: locked
          ? const Icon(Icons.lock_outline, color: AppColors.textSecondary)
          : null,
      border: border(AppColors.border),
      enabledBorder: border(AppColors.border),
      disabledBorder: border(AppColors.border),
      focusedBorder: border(AppColors.deepGreen, width: 2),
      errorBorder: border(AppColors.error),
      focusedErrorBorder: border(AppColors.error, width: 2),
    );
  }
}

/// Bold label above a field, with an optional grey note below it.
class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child, this.helper});

  final String label;
  final Widget child;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.titleSmall?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          child,
          if (helper != null) ...[
            const SizedBox(height: 6),
            Text(
              helper!,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Profile photo with a green camera badge and a "Change photo" link.
class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.url,
    required this.previewBytes,
    required this.label,
    required this.onTap,
  });

  final String? url;
  final Uint8List? previewBytes;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                SizedBox.square(
                  dimension: 104,
                  child: Stack(
                    children: [
                      UserAvatar(
                        url: url,
                        previewBytes: previewBytes,
                        size: 100,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 4,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.deepGreen,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.white,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.photo_camera_outlined,
                            size: 18,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.deepGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
