import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'photo_content_checker.dart';
import 'photo_findings.dart';

@JS('shareloopPhotoCheck')
external JSPromise<JSString> _shareloopPhotoCheck(
  JSUint8Array bytes,
  JSString mimeType,
);

/// Web: MediaPipe Tasks Vision in the browser (web/photo_check.js) — hand
/// landmarks, body pose, faces, and COCO objects ("person", plus books and
/// screens for telling printed pictures apart). Runs on the device; the
/// first check downloads the library and models, so it allows extra time.
class MediaPipeWebPhotoChecker extends FindingsPhotoChecker {
  static const Duration _timeout = Duration(seconds: 90);

  @override
  Future<PhotoFindings> analyse(Uint8List bytes, {String? mimeType}) async {
    if (!globalContext.has('shareloopPhotoCheck')) {
      throw StateError('photo_check.js is not loaded');
    }
    final json = await _shareloopPhotoCheck(
      bytes.toJS,
      (mimeType ?? 'image/jpeg').toJS,
    ).toDart.timeout(_timeout);
    return PhotoFindings.fromSummaryJson(json.toDart);
  }
}
