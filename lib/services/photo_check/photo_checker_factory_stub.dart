import 'photo_content_checker.dart';

/// Neither dart:io nor the web: nothing can check photos.
PhotoContentChecker createPlatformPhotoChecker() =>
    const UnsupportedPhotoChecker();
