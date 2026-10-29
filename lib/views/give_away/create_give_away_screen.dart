import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/item_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/item_request_model.dart';
import '../../models/photo_upload.dart';
import '../../services/photo_check/photo_content_checker.dart';
import '../../widgets/camera_capture.dart';
import '../../widgets/photo_source_sheet.dart';
import '../../widgets/post_form_widgets.dart';
import '../../widgets/unsaved_changes_guard.dart';

/// View: form to publish a new Give Away post (photos, details, category,
/// condition, location). Shown as the home shell's Give tab, or pushed as
/// its own route from "I can help" on a community request ([forRequest]),
/// which pre-fills the item name and category.
///
/// Always uses the light brand theme, like the home shell it opens from.
class CreateGiveAwayScreen extends StatelessWidget {
  const CreateGiveAwayScreen({
    super.key,
    this.forRequest,
    this.onClose,
    this.hasUnsavedInput,
  });

  final ItemRequestModel? forRequest;

  /// Called on back and after publishing instead of popping the route,
  /// for when the form is a tab rather than a pushed page.
  final VoidCallback? onClose;

  /// As a tab, tells the parent whether leaving would lose typed input, so
  /// it can ask first. (A pushed page guards its own back navigation.)
  final ValueNotifier<bool>? hasUnsavedInput;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: _GiveForm(
        forRequest: forRequest,
        onClose: onClose,
        hasUnsavedInput: hasUnsavedInput,
      ),
    );
  }
}

class _GiveForm extends StatefulWidget {
  const _GiveForm({this.forRequest, this.onClose, this.hasUnsavedInput});

  final ItemRequestModel? forRequest;
  final VoidCallback? onClose;
  final ValueNotifier<bool>? hasUnsavedInput;

  @override
  State<_GiveForm> createState() => _GiveFormState();
}

class _GiveFormState extends State<_GiveForm> {
  static const int _maxPhotos = 3;
  static const int _titleMaxLength = 60;
  static const int _descriptionMaxLength = 300;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();

  /// Only photos the people/body-part check has cleared.
  final List<_PickedPhoto> _photos = [];
  bool _checkingPhotos = false;
  String _condition = AppConstants.itemConditions[1];
  String? _category;
  String? _district;
  bool _submitting = false;

  /// Errors only show live once the user has tried to publish.
  bool _attemptedSubmit = false;

  /// The title prefilled from a request, so it alone doesn't count as input.
  String _initialTitle = '';
  bool _hasInput = false;

  /// Typed text or picked photos that leaving would throw away.
  void _updateHasInput() {
    final hasInput = _photos.isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        _titleController.text.trim() != _initialTitle;
    widget.hasUnsavedInput?.value = hasInput;
    if (hasInput != _hasInput && mounted) {
      setState(() => _hasInput = hasInput);
    }
  }

  @override
  void initState() {
    super.initState();
    final request = widget.forRequest;
    if (request != null) {
      _titleController.text =
          request.itemName.isEmpty ? request.description : request.itemName;
      _initialTitle = _titleController.text.trim();
      if (AppConstants.itemCategories.contains(request.category)) {
        _category = request.category;
      }
    }
    _titleController.addListener(_updateHasInput);
    _descriptionController.addListener(_updateHasInput);
    widget.hasUnsavedInput?.value = false;
    // Most people give from where they live, so start from their profile.
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
    _titleController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _addPhotos() async {
    final source = await showPhotoSourceSheet(context);
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final remaining = _maxPhotos - _photos.length;
    final List<XFile> picked;
    if (source == ImageSource.camera) {
      final file = await takePhoto(context, maxWidth: 1600);
      picked = file == null ? const [] : [file];
    } else if (remaining > 1) {
      // pickMultiImage needs a limit of at least 2.
      picked = await picker.pickMultiImage(
        limit: remaining,
        maxWidth: 1600,
        imageQuality: 85,
      );
    } else {
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      picked = file == null ? const [] : [file];
    }
    final candidates = [
      for (final file in picked.take(remaining))
        _PickedPhoto(file, await file.readAsBytes()),
    ];
    if (!mounted || candidates.isEmpty) return;
    await _checkAndAdd(candidates);
  }

  /// Adds only photos the on-device check clears of people and body parts.
  /// Refused or uncheckable photos are dropped, with a message saying why.
  Future<void> _checkAndAdd(List<_PickedPhoto> candidates) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final checker =
        context.read<PhotoContentChecker?>() ?? PhotoContentChecker.platform;
    setState(() => _checkingPhotos = true);
    final outcomes = await checkPhotos(checker, [
      for (final c in candidates) (bytes: c.bytes, mimeType: c.file.mimeType),
    ]);
    if (!mounted) return;
    setState(() {
      _checkingPhotos = false;
      for (var i = 0; i < candidates.length; i++) {
        if (outcomes[i] == PhotoCheckOutcome.clear &&
            _photos.length < _maxPhotos) {
          _photos.add(candidates[i]);
        }
      }
    });
    _updateHasInput();

    final String? message;
    if (outcomes.contains(PhotoCheckOutcome.containsPerson)) {
      message = l10n.photoHasPerson;
    } else if (outcomes.contains(PhotoCheckOutcome.unsupported)) {
      message = l10n.photoCheckUnsupported;
    } else if (outcomes.contains(PhotoCheckOutcome.failed)) {
      message = l10n.photoCheckFailed;
    } else {
      message = null;
    }
    if (message != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 6),
          ),
        );
    }
  }

  Future<void> _submit() async {
    // Photos still being checked aren't in the post yet.
    if (_checkingPhotos) return;
    setState(() => _attemptedSubmit = true);
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<AuthController>().currentUser;
    if (user == null) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _submitting = true);
    final error = await context.read<ItemController>().createPost(
          donorId: user.id,
          donorName: user.name,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          condition: _condition,
          category: _category!,
          district: _district!,
          city: _cityController.text.trim(),
          photos: [
            for (final photo in _photos)
              PhotoUpload(
                bytes: photo.bytes,
                mimeType: photo.file.mimeType,
                name: photo.file.name,
              ),
          ],
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error == null) {
      // Published, so leaving now loses nothing.
      widget.hasUnsavedInput?.value = false;
      messenger.showSnackBar(SnackBar(content: Text(l10n.givePublished)));
      if (widget.onClose case final onClose?) {
        onClose();
      } else {
        Navigator.of(context).pop();
      }
    } else {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                  title: l10n.giveTitle,
                  subtitle: l10n.giveSubtitle,
                  onBack: widget.onClose,
                ),
                const SizedBox(height: 24),
                PostFieldLabel(
                  l10n.givePhotos,
                  trailing: '${_photos.length}/$_maxPhotos',
                ),
                _PhotoPicker(
                  photos: _photos,
                  maxPhotos: _maxPhotos,
                  checking: _checkingPhotos,
                  onAdd: _addPhotos,
                  onRemove: (index) {
                    setState(() => _photos.removeAt(index));
                    _updateHasInput();
                  },
                ),
                const SizedBox(height: 20),
                PostFieldLabel(l10n.giveItemTitle),
                TextFormField(
                  controller: _titleController,
                  maxLength: _titleMaxLength,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: postInputDecoration(hint: l10n.giveItemTitleHint)
                      .copyWith(counterText: ''),
                  validator: (v) => required(v, l10n.giveItemTitleRequired),
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
                      postInputDecoration(hint: l10n.giveDescriptionHint),
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
                const SizedBox(height: 20),
                PostFieldLabel(l10n.giveCondition),
                _ConditionSelector(
                  selected: _condition,
                  onChanged: (value) => setState(() => _condition = value),
                ),
                const SizedBox(height: 20),
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
                            textInputAction: TextInputAction.done,
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
            ),
          ),
        ),
      ),
      bottomNavigationBar: PostSubmitBar(
        label: l10n.givePublish,
        icon: Icons.check,
        isLoading: _submitting,
        onPressed: _submit,
      ),
    );
    // As a tab the parent asks before leaving (see hasUnsavedInput).
    if (widget.onClose != null) return page;
    return UnsavedChangesGuard(hasChanges: _hasInput, child: page);
  }
}

/// A chosen photo plus its bytes, read once for the preview thumbnail
/// (works on web too, where [XFile.path] is not a real file).
class _PickedPhoto {
  const _PickedPhoto(this.file, this.bytes);

  final XFile file;
  final Uint8List bytes;
}

/// Large drop zone while empty; then a row of thumbnails (first is the
/// cover) with "add" slots for the rest.
class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.photos,
    required this.maxPhotos,
    required this.checking,
    required this.onAdd,
    required this.onRemove,
  });

  final List<_PickedPhoto> photos;
  final int maxPhotos;

  /// New photos are being checked; adding more waits until it's done.
  final bool checking;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (photos.isEmpty) {
      return _EmptyPhotoZone(
        title: checking ? l10n.photoChecking : l10n.giveAddPhotos,
        hint: l10n.givePhotosItemOnly,
        checking: checking,
        onTap: checking ? null : onAdd,
      );
    }
    return Row(
      children: [
        for (var i = 0; i < maxPhotos; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: i < photos.length
                  ? _PhotoTile(
                      bytes: photos[i].bytes,
                      coverLabel: i == 0 ? l10n.giveCover : null,
                      removeTooltip: l10n.giveRemovePhoto,
                      onRemove: () => onRemove(i),
                    )
                  : _AddPhotoTile(
                      tooltip: checking ? l10n.photoChecking : l10n.giveAddPhoto,
                      checking: checking && i == photos.length,
                      onTap: checking ? null : onAdd,
                    ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyPhotoZone extends StatelessWidget {
  const _EmptyPhotoZone({
    required this.title,
    required this.hint,
    required this.checking,
    required this.onTap,
  });

  final String title;
  final String hint;
  final bool checking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return CustomPaint(
      foregroundPainter: const _DashedBorderPainter(radius: 16),
      child: Material(
        color: AppColors.paleMint,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: checking
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.deepGreen,
                          ),
                        )
                      : const Icon(
                          Icons.photo_camera_outlined,
                          color: AppColors.deepGreen,
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
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

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.bytes,
    required this.coverLabel,
    required this.removeTooltip,
    required this.onRemove,
  });

  final Uint8List bytes;

  /// Shown on the first photo only, which becomes the post's cover.
  final String? coverLabel;
  final String removeTooltip;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(bytes, fit: BoxFit.cover),
          Positioned(
            top: 6,
            right: 6,
            child: Tooltip(
              message: removeTooltip,
              child: Material(
                color: AppColors.ink.withValues(alpha: 0.75),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(Icons.close, size: 16, color: AppColors.white),
                  ),
                ),
              ),
            ),
          ),
          if (coverLabel != null)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.deepGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  coverLabel!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({
    required this.tooltip,
    required this.checking,
    required this.onTap,
  });

  final String tooltip;

  /// Shows a spinner in place of the plus while new photos are checked.
  final bool checking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: CustomPaint(
        foregroundPainter: const _DashedBorderPainter(radius: 14),
        child: Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: checking
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.deepGreen,
                      ),
                    )
                  : const Icon(Icons.add, size: 28, color: AppColors.deepGreen),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashed rounded-rectangle outline for the photo upload slots.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.radius});

  final double radius;

  static const double _dash = 6;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.brightGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius))
            .deflate(0.6),
      );
    for (final metric in outline.computeMetrics()) {
      for (double d = 0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.radius != radius;
}

class _ConditionSelector extends StatelessWidget {
  const _ConditionSelector({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final condition in AppConstants.itemConditions)
          Semantics(
            button: true,
            selected: condition == selected,
            child: Material(
              color:
                  condition == selected ? AppColors.deepGreen : AppColors.white,
              shape: StadiumBorder(
                side: BorderSide(
                  color: condition == selected
                      ? AppColors.deepGreen
                      : AppColors.softMint,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onChanged(condition),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                  child: Text(
                    condition,
                    style: textTheme.bodyMedium?.copyWith(
                      color: condition == selected
                          ? AppColors.white
                          : AppColors.ink,
                      fontWeight: condition == selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
