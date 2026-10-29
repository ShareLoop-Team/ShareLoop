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
import '../../models/item_request_model.dart';
import '../../widgets/post_form_widgets.dart';
import '../../widgets/unsaved_changes_guard.dart';

/// View: create an item request. If [postId] is supplied, this request
/// targets that specific Give Away post ("Request this item") and only
/// asks why it's needed; otherwise it is a standalone need post.
///
/// With [editRequest], edits the user's own request instead, starting from
/// its current details.
///
/// Always uses the light brand theme, like the home shell it opens from.
class CreateRequestScreen extends StatelessWidget {
  const CreateRequestScreen({super.key, this.postId, this.editRequest});

  final String? postId;
  final ItemRequestModel? editRequest;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: _RequestForm(
        postId: editRequest?.itemPostId ?? postId,
        editRequest: editRequest,
      ),
    );
  }
}

class _RequestForm extends StatefulWidget {
  const _RequestForm({this.postId, this.editRequest});

  final String? postId;
  final ItemRequestModel? editRequest;

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

  /// Changes that leaving would throw away.
  bool _hasInput = false;

  /// The text fields as the form opened: empty, or the edited request's.
  late final List<String> _initialText;
  String? _initialCategory;
  String? _initialDistrict;

  List<TextEditingController> get _textControllers => [
        _itemNameController,
        _descriptionController,
        _reasonController,
        _cityController,
        _notesController,
      ];

  void _updateHasInput() {
    final controllers = _textControllers;
    final hasInput = _category != _initialCategory ||
        _district != _initialDistrict ||
        [
          for (var i = 0; i < controllers.length; i++)
            controllers[i].text.trim() != _initialText[i].trim(),
        ].any((changed) => changed);
    if (hasInput != _hasInput) setState(() => _hasInput = hasInput);
  }

  @override
  void initState() {
    super.initState();
    final postId = widget.postId;
    if (postId != null) {
      // Not `posts`: that list is narrowed by the Home search and filters.
      _post = context.read<ItemController>().postById(postId);
    }
    if (widget.editRequest case final request?) {
      // Older requests have no item name; their cards show the description
      // as the title, so start from that.
      _itemNameController.text = request.itemName.isEmpty
          ? request.description
          : request.itemName;
      _descriptionController.text = request.description;
      _reasonController.text = request.reason;
      _notesController.text = request.notes;
      _cityController.text = request.city;
      if (AppConstants.itemCategories.contains(request.category)) {
        _category = request.category;
      }
      if (AppConstants.sriLankanDistricts.contains(request.district)) {
        _district = request.district;
      }
    } else {
      // Most people ask from where they live, so start from their profile.
      final user = context.read<AuthController>().currentUser;
      if (user != null) {
        if (AppConstants.sriLankanDistricts.contains(user.district)) {
          _district = user.district;
        }
        _cityController.text = user.city;
      }
    }
    _initialText = [for (final c in _textControllers) c.text];
    _initialCategory = _category;
    _initialDistrict = _district;
    for (final controller in _textControllers) {
      controller.addListener(_updateHasInput);
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
    final editing = widget.editRequest;
    final requests = context.read<RequestController>();

    setState(() => _submitting = true);
    final String? error;
    if (editing != null) {
      // A request for a post only says why; the item comes from the post.
      error = await requests.updateRequest(
        editing.itemPostId != null
            ? editing.copyWith(
                reason: _reasonController.text,
                notes: _notesController.text,
              )
            : editing.copyWith(
                itemName: _itemNameController.text,
                description: _descriptionController.text,
                reason: _reasonController.text,
                notes: _notesController.text,
                category: _category,
                district: _district,
                city: _cityController.text,
              ),
      );
    } else {
      error = await requests.createRequest(
        requesterId: user.id,
        requesterName: user.name,
        requesterAvatarUrl: user.avatarUrl,
        itemPostId: widget.postId,
        itemName: post?.title ?? _itemNameController.text,
        description: post?.title ?? _descriptionController.text,
        reason: _reasonController.text,
        notes: _notesController.text,
        category: post?.category ?? _category!,
        district: post?.district ?? _district!,
        city: post?.city ?? _cityController.text,
      );
    }
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            editing != null ? l10n.requestUpdated : l10n.requestSubmitted,
          ),
        ),
      );
      Navigator.of(context).pop();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final post = _post;
    final editing = widget.editRequest;
    // Opened for a post that no longer exists: fall back to the full form.
    // An edited request for a post keeps its item, loaded or not.
    final isTargeted = post != null || editing?.itemPostId != null;
    String? required(String? value, String message) =>
        (value == null || value.trim().isEmpty) ? message : null;

    final page = Scaffold(
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
                  title:
                      editing != null ? l10n.requestEditTitle : l10n.requestTitle,
                  subtitle: editing != null
                      ? l10n.requestEditSubtitle
                      : l10n.requestSubtitle,
                ),
                const SizedBox(height: 16),
                _InfoBanner(
                  title: l10n.requestInfoTitle,
                  body: l10n.requestInfoBody,
                ),
                const SizedBox(height: 20),
                if (isTargeted) ...[
                  PostFieldLabel(l10n.requestYouAreRequesting),
                  if (post != null)
                    _RequestedItemCard(
                      title: post.title,
                      details:
                          '${post.category} · ${post.city}, ${post.district}',
                    )
                  else
                    _RequestedItemCard(
                      title: editing!.itemName.isEmpty
                          ? editing.description
                          : editing.itemName,
                      details: '${editing.category} · '
                          '${editing.city}, ${editing.district}',
                    ),
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
                    onChanged: (value) {
                      setState(() => _category = value);
                      _updateHasInput();
                    },
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
                              onChanged: (value) {
                                setState(() => _district = value);
                                _updateHasInput();
                              },
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
        label: editing != null ? l10n.editProfileSave : l10n.submitRequest,
        icon: editing != null ? Icons.check : Icons.near_me_outlined,
        isLoading: _submitting,
        onPressed: _submit,
      ),
    );
    return UnsavedChangesGuard(hasChanges: _hasInput, child: page);
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
  const _RequestedItemCard({required this.title, required this.details});

  final String title;

  /// Category and place, e.g. "Shoes · Negombo, Gampaha".
  final String details;

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
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  details,
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
