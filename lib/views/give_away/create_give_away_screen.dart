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

/// View: form to publish a new Give Away post (photos, details, category,
/// condition, location). Opened from the Home "Give" card and nav tab.
///
/// Always uses the light brand theme, like the home shell it opens from.
class CreateGiveAwayScreen extends StatelessWidget {
  const CreateGiveAwayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(data: AppTheme.lightTheme, child: const _GiveForm());
  }
}

class _GiveForm extends StatefulWidget {
  const _GiveForm();

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
  final List<_PickedPhoto> _photos = [];
  String _condition = AppConstants.itemConditions[1];
  String? _category;
  String? _district;
  bool _submitting = false;

  /// Errors only show live once the user has tried to publish.
  bool _attemptedSubmit = false;

  @override
  void initState() {
    super.initState();
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
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      builder: (sheetContext) => Theme(
        data: AppTheme.lightTheme,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.deepGreen,
                ),
                title: Text(l10n.giveTakePhoto),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.deepGreen,
                ),
                title: Text(l10n.giveChooseFromGallery),
                onTap: () =>
                    Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final remaining = _maxPhotos - _photos.length;
    final List<XFile> picked;
    // pickMultiImage needs a limit of at least 2.
    if (source == ImageSource.gallery && remaining > 1) {
      picked = await picker.pickMultiImage(
        limit: remaining,
        maxWidth: 1600,
        imageQuality: 85,
      );
    } else {
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      picked = file == null ? const [] : [file];
    }
    final photos = [
      for (final file in picked.take(remaining))
        _PickedPhoto(file, await file.readAsBytes()),
    ];
    if (!mounted || photos.isEmpty) return;
    setState(() => _photos.addAll(photos));
  }

  Future<void> _submit() async {
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
          photoPaths: _photos.map((p) => p.file.path).toList(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.givePublished)));
      Navigator.of(context).pop();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                _Header(title: l10n.giveTitle, subtitle: l10n.giveSubtitle),
                const SizedBox(height: 24),
                _FieldLabel(
                  l10n.givePhotos,
                  trailing: '${_photos.length}/$_maxPhotos',
                ),
                _PhotoPicker(
                  photos: _photos,
                  maxPhotos: _maxPhotos,
                  onAdd: _addPhotos,
                  onRemove: (index) =>
                      setState(() => _photos.removeAt(index)),
                ),
                const SizedBox(height: 20),
                _FieldLabel(l10n.giveItemTitle),
                TextFormField(
                  controller: _titleController,
                  maxLength: _titleMaxLength,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(hint: l10n.giveItemTitleHint)
                      .copyWith(counterText: ''),
                  validator: (v) => required(v, l10n.giveItemTitleRequired),
                ),
                const SizedBox(height: 20),
                _FieldLabel(l10n.giveDescription),
                TextFormField(
                  controller: _descriptionController,
                  maxLength: _descriptionMaxLength,
                  minLines: 3,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration:
                      _inputDecoration(hint: l10n.giveDescriptionHint),
                  validator: (v) =>
                      required(v, l10n.giveDescriptionRequired),
                ),
                const SizedBox(height: 12),
                _FieldLabel(l10n.giveCategory),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  isExpanded: true,
                  hint: Text(
                    l10n.giveCategoryHint,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  decoration: _inputDecoration(),
                  dropdownColor: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                  items: AppConstants.itemCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) => setState(() => _category = value),
                  validator: (v) => required(v, l10n.giveCategoryRequired),
                ),
                const SizedBox(height: 20),
                _FieldLabel(l10n.giveCondition),
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
                          _FieldLabel(l10n.district),
                          DropdownButtonFormField<String>(
                            initialValue: _district,
                            isExpanded: true,
                            hint: Text(
                              l10n.giveDistrictHint,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            decoration: _inputDecoration(),
                            dropdownColor: AppColors.white,
                            borderRadius: BorderRadius.circular(14),
                            menuMaxHeight: 320,
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: AppColors.textSecondary,
                            ),
                            items: AppConstants.sriLankanDistricts
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(
                                      d,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
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
                          _FieldLabel(l10n.cityTown),
                          TextFormField(
                            controller: _cityController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.done,
                            decoration:
                                _inputDecoration(hint: l10n.giveCityHint),
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
      bottomNavigationBar: _PublishBar(
        label: l10n.givePublish,
        isLoading: _submitting,
        onPressed: _submit,
      ),
    );
  }
}

/// A chosen photo plus its bytes, read once for the preview thumbnail
/// (works on web too, where [XFile.path] is not a real file).
class _PickedPhoto {
  const _PickedPhoto(this.file, this.bytes);

  final XFile file;
  final Uint8List bytes;
}

/// White rounded field with a light outline, green when focused.
InputDecoration _inputDecoration({String? hint}) {
  OutlineInputBorder border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textSecondary),
    filled: true,
    fillColor: AppColors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border(AppColors.border),
    enabledBorder: border(AppColors.border),
    focusedBorder: border(AppColors.deepGreen, width: 1.5),
    errorBorder: border(AppColors.error),
    focusedErrorBorder: border(AppColors.error, width: 1.5),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Material(
          color: AppColors.white,
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.softMint),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: AppColors.ink,
            ),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

/// Large drop zone while empty; then a row of thumbnails (first is the
/// cover) with "add" slots for the rest.
class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.photos,
    required this.maxPhotos,
    required this.onAdd,
    required this.onRemove,
  });

  final List<_PickedPhoto> photos;
  final int maxPhotos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (photos.isEmpty) {
      return _EmptyPhotoZone(
        title: l10n.giveAddPhotos,
        hint: l10n.giveAddPhotosHint,
        onTap: onAdd,
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
                  : _AddPhotoTile(tooltip: l10n.giveAddPhoto, onTap: onAdd),
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
    required this.onTap,
  });

  final String title;
  final String hint;
  final VoidCallback onTap;

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
                  child: const Icon(
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
  const _AddPhotoTile({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

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
            child: const Center(
              child: Icon(Icons.add, size: 28, color: AppColors.deepGreen),
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

/// White bar pinned to the bottom holding the full-width publish button.
class _PublishBar extends StatelessWidget {
  const _PublishBar({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepGreen,
              foregroundColor: AppColors.white,
              disabledBackgroundColor:
                  AppColors.deepGreen.withValues(alpha: 0.6),
              elevation: 0,
              minimumSize: const Size.fromHeight(54),
              shape: const StadiumBorder(),
              textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            child: isLoading
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(label, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
