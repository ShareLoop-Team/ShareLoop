import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/item_controller.dart';
import '../../controllers/request_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/item_post_model.dart';
import '../../widgets/post_form_widgets.dart';

/// View: create an item request. If [postId] is supplied, this request
/// targets that specific Give Away post ("Request this item") and only
/// asks why it's needed; otherwise it is a standalone need post.
///
/// Always uses the light brand theme, like the home shell it opens from.
class CreateRequestScreen extends StatelessWidget {
  const CreateRequestScreen({super.key, this.postId});

  final String? postId;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: _RequestForm(postId: postId),
    );
  }
}

class _RequestForm extends StatefulWidget {
  const _RequestForm({this.postId});

  final String? postId;

  @override
  State<_RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends State<_RequestForm> {
  static const int _itemNameMaxLength = 60;
  static const int _descriptionMaxLength = 300;
  static const int _reasonMaxLength = 300;
  static const int _notesMaxLength = 200;

  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _reasonController = TextEditingController();
  final _cityController = TextEditingController();
  final _notesController = TextEditingController();
  String? _category;
  String? _district;
  bool _submitting = false;

  /// Errors only show live once the user has tried to submit.
  bool _attemptedSubmit = false;

  /// The Give Away post being requested, when opened from its details.
  ItemPostModel? _post;

  @override
  void initState() {
    super.initState();
    final postId = widget.postId;
    if (postId != null) {
      _post = context
          .read<ItemController>()
          .posts
          .where((p) => p.id == postId)
          .firstOrNull;
    }
    // Most people ask from where they live, so start from their profile.
    final user = context.read<AuthController>().currentUser;
    if (user != null) {
      if (AppConstants.sriLankanDistricts.contains(user.district)) {
        _district = user.district;
      }
      _cityController.text = user.city;
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    _reasonController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _attemptedSubmit = true);
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<AuthController>().currentUser;
    if (user == null) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final post = _post;

    setState(() => _submitting = true);
    final error = await context.read<RequestController>().createRequest(
          requesterId: user.id,
          requesterName: user.name,
          itemPostId: widget.postId,
          itemName: post?.title ?? _itemNameController.text,
          description: post?.title ?? _descriptionController.text,
          reason: _reasonController.text,
          notes: _notesController.text,
          category: post?.category ?? _category!,
          district: post?.district ?? _district!,
          city: post?.city ?? _cityController.text,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.requestSubmitted)));
      Navigator.of(context).pop();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final post = _post;
    // Opened for a post that no longer exists: fall back to the full form.
    final isTargeted = post != null;
    String? required(String? value, String message) =>
        (value == null || value.trim().isEmpty) ? message : null;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        // Not a ListView: lazily built fields would skip validation.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            autovalidateMode: _attemptedSubmit
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PostFormHeader(
                  title: l10n.requestTitle,
                  subtitle: l10n.requestSubtitle,
                ),
                const SizedBox(height: 16),
                _InfoBanner(
                  title: l10n.requestInfoTitle,
                  body: l10n.requestInfoBody,
                ),
                const SizedBox(height: 20),
                if (isTargeted) ...[
                  PostFieldLabel(l10n.requestYouAreRequesting),
                  _RequestedItemCard(post: post),
                ] else ...[
                  PostFieldLabel(l10n.requestItemName),
                  TextFormField(
                    controller: _itemNameController,
                    maxLength: _itemNameMaxLength,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    decoration:
                        postInputDecoration(hint: l10n.requestItemNameHint)
                            .copyWith(counterText: ''),
                    validator: (v) =>
                        required(v, l10n.requestItemNameRequired),
                  ),
                  const SizedBox(height: 20),
                  PostFieldLabel(l10n.giveDescription),
                  TextFormField(
                    controller: _descriptionController,
                    maxLength: _descriptionMaxLength,
                    minLines: 3,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    decoration:
                        postInputDecoration(hint: l10n.requestDescriptionHint),
                    validator: (v) =>
                        required(v, l10n.giveDescriptionRequired),
                  ),
                  const SizedBox(height: 12),
                  PostFieldLabel(l10n.giveCategory),
                  PostDropdownField(
                    value: _category,
                    hint: l10n.giveCategoryHint,
                    options: AppConstants.itemCategories,
                    onChanged: (value) => setState(() => _category = value),
                    validator: (v) => required(v, l10n.giveCategoryRequired),
                  ),
                ],
                const SizedBox(height: 20),
                PostFieldLabel(l10n.requestReason),
                TextFormField(
                  controller: _reasonController,
                  maxLength: _reasonMaxLength,
                  minLines: 3,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: postInputDecoration(
                    hint: l10n.requestReasonHint,
                    helper: l10n.requestReasonHelper,
                  ),
                  validator: (v) => required(v, l10n.requestReasonRequired),
                ),
                if (!isTargeted) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PostFieldLabel(l10n.district),
                            PostDropdownField(
                              value: _district,
                              hint: l10n.giveDistrictHint,
                              options: AppConstants.sriLankanDistricts,
                              menuMaxHeight: 320,
                              onChanged: (value) =>
                                  setState(() => _district = value),
                              validator: (v) =>
                                  required(v, l10n.giveDistrictRequired),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PostFieldLabel(l10n.cityTown),
                            TextFormField(
                              controller: _cityController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration:
                                  postInputDecoration(hint: l10n.giveCityHint),
                              validator: (v) =>
                                  required(v, l10n.giveCityRequired),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                PostFieldLabel(
                  l10n.requestNotes,
                  suffix: l10n.requestOptional,
                ),
                TextFormField(
                  controller: _notesController,
                  maxLength: _notesMaxLength,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  decoration: postInputDecoration(hint: l10n.requestNotesHint)
                      .copyWith(counterText: ''),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: PostSubmitBar(
        label: l10n.submitRequest,
        icon: Icons.near_me_outlined,
        isLoading: _submitting,
        onPressed: _submit,
      ),
    );
  }
}

/// Mint card reminding requesters that donors read their reason.
class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paleMint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softMint),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border,
              size: 22,
              color: AppColors.deepGreen,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ' $body'),
                ],
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.ink,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Summary of the Give Away post a targeted request is for.
class _RequestedItemCard extends StatelessWidget {
  const _RequestedItemCard({required this.post});

  final ItemPostModel post;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.paleMint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.card_giftcard_outlined,
              color: AppColors.deepGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${post.category} · ${post.city}, ${post.district}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
