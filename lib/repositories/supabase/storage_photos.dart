import 'dart:math';

import '../../core/config/backend_config.dart';
import '../../core/errors/app_exception.dart';
import '../../models/photo_upload.dart';

/// Photo upload helpers shared by item photos and profile photos, which
/// both live in the [BackendConfig.itemImagesBucket] under the user's folder.
class StoragePhotos {
  StoragePhotos._();

  /// Validates a photo against the bucket's limits and picks its content
  /// type and file extension.
  static (String contentType, String extension) prepare(PhotoUpload photo) {
    if (photo.bytes.length > BackendConfig.maxImageBytes) {
      throw const AppException('Each photo must be 5 MB or smaller.');
    }
    final name = photo.name.toLowerCase();
    final contentType = photo.mimeType ??
        (name.endsWith('.png')
            ? 'image/png'
            : name.endsWith('.webp')
                ? 'image/webp'
                : 'image/jpeg');
    if (!BackendConfig.allowedImageTypes.contains(contentType)) {
      throw const AppException('Photos must be JPEG, PNG or WebP.');
    }
    final extension = switch (contentType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
    return (contentType, extension);
  }

  static final Random _random = Random.secure();

  /// Unguessable file name, so photo URLs can't be enumerated.
  static String randomName() => [
        for (var i = 0; i < 16; i++)
          _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ].join();
}
