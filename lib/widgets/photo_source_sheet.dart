import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/app_colors.dart';
import '../core/localization/generated/app_localizations.dart';
import '../core/theme/app_theme.dart';

/// Bottom sheet asking where a photo should come from: the camera or the
/// gallery. Returns null when dismissed.
///
/// Always light, like the screens that open it, so the options stay
/// readable when the device is in dark mode.
Future<ImageSource?> showPhotoSourceSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.white,
    builder: (sheetContext) {
      Widget option(IconData icon, String label, ImageSource source) {
        return ListTile(
          leading: Icon(icon, color: AppColors.deepGreen),
          title: Text(label),
          textColor: AppColors.ink,
          onTap: () => Navigator.of(sheetContext).pop(source),
        );
      }

      return Theme(
        data: AppTheme.lightTheme,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              option(
                Icons.photo_camera_outlined,
                l10n.giveTakePhoto,
                ImageSource.camera,
              ),
              option(
                Icons.photo_library_outlined,
                l10n.giveChooseFromGallery,
                ImageSource.gallery,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}
