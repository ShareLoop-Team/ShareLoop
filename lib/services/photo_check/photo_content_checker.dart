import 'dart:typed_data';

import 'photo_checker_factory_stub.dart'
    if (dart.library.js_interop) 'photo_checker_factory_web.dart'
    if (dart.library.io) 'photo_checker_factory_io.dart';
import 'photo_findings.dart';

/// Outcome of checking one donation photo.
enum PhotoCheckOutcome {
  /// No person or body part detected: the photo may be used.
  clear,

  /// A person or body part was detected: the photo is refused.
  containsPerson,

  /// This device has no detector, so photos can't be checked (or used).
  unsupported,

  /// The check itself failed (e.g. the model didn't load). Never treated
  /// as a pass.
  failed,
}

/// Service: checks donation photos on the device for people and visible
/// body parts before they are added to a post. Photos are not uploaded
/// anywhere to be checked.
abstract class PhotoContentChecker {
  /// The detector for the platform the app is running on.
  static final PhotoContentChecker platform = createPlatformPhotoChecker();

  Future<PhotoCheckOutcome> check(Uint8List bytes, {String? mimeType});
}

/// Base for detectors that report [PhotoFindings]; applies [PhotoPolicy]
/// and turns any error into [PhotoCheckOutcome.failed].
abstract class FindingsPhotoChecker implements PhotoContentChecker {
  Future<PhotoFindings> analyse(Uint8List bytes, {String? mimeType});

  @override
  Future<PhotoCheckOutcome> check(Uint8List bytes, {String? mimeType}) async {
    try {
      final findings = await analyse(bytes, mimeType: mimeType);
      return PhotoPolicy.containsPerson(findings)
          ? PhotoCheckOutcome.containsPerson
          : PhotoCheckOutcome.clear;
    } catch (_) {
      return PhotoCheckOutcome.failed;
    }
  }
}

/// For platforms with no detector (e.g. Windows): every photo is refused
/// as uncheckable rather than let through unchecked.
class UnsupportedPhotoChecker implements PhotoContentChecker {
  const UnsupportedPhotoChecker();

  @override
  Future<PhotoCheckOutcome> check(Uint8List bytes, {String? mimeType}) async =>
      PhotoCheckOutcome.unsupported;
}

/// Checks [photos] one by one. A checker that throws counts as
/// [PhotoCheckOutcome.failed] for that photo only.
Future<List<PhotoCheckOutcome>> checkPhotos(
  PhotoContentChecker checker,
  List<({Uint8List bytes, String? mimeType})> photos,
) async {
  final outcomes = <PhotoCheckOutcome>[];
  for (final photo in photos) {
    try {
      outcomes.add(await checker.check(photo.bytes, mimeType: photo.mimeType));
    } catch (_) {
      outcomes.add(PhotoCheckOutcome.failed);
    }
  }
  return outcomes;
}
