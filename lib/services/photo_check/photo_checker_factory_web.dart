import 'mediapipe_web_photo_checker.dart';
import 'photo_content_checker.dart';

/// MediaPipe Tasks Vision, running in the browser.
PhotoContentChecker createPlatformPhotoChecker() => MediaPipeWebPhotoChecker();
