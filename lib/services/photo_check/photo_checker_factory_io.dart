import 'dart:io';

import 'mlkit_photo_checker.dart';
import 'photo_content_checker.dart';

/// ML Kit on Android and iOS; no on-device detector on desktop.
PhotoContentChecker createPlatformPhotoChecker() =>
    Platform.isAndroid || Platform.isIOS
        ? MlKitPhotoChecker()
        : const UnsupportedPhotoChecker();
