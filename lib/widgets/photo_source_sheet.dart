import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/localization/generated/app_localizations.dart';
import '../core/theme/sl_tokens.dart';

/// Bottom sheet asking where a photo should come from: the camera or the
/// gallery. Returns null when dismissed.
///
/// Takes the theme of the screen that opens it (light or dark).
Future<ImageSource?> showPhotoSourceSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final sl = sheetContext.sl;
      Widget option(IconData icon, String label, ImageSource source) {
        return ListTile(
          leading: Icon(icon, color: sl.accentText),
          title: Text(label, style: sheetContext.slType.body),
          onTap: () => Navigator.of(sheetContext).pop(source),
        );
      }

      return SafeArea(
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
            const SizedBox(height: SLSpace.s),
          ],
        ),
      );
    },
  );
}
