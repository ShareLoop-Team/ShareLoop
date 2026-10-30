import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'photo_content_checker.dart';
import 'photo_findings.dart';

/// Android/iOS: Google ML Kit, fully on the device (bundled models).
///
/// - Image labeling: whole-image labels such as Hand, Skin, Nail, Foot,
///   Hair or Person — the main signal for a hand holding an item.
/// - Pose detection: a body (shoulders, arms, legs) in the scene.
/// - Face detection: faces, including small ones in the background.
///
/// ML Kit gives no book/screen boxes, so a printed face on a cover can't be
/// told apart from a real one here.
class MlKitPhotoChecker extends FindingsPhotoChecker {
  @override
  Future<PhotoFindings> analyse(Uint8List bytes, {String? mimeType}) async {
    // ML Kit reads encoded photos (JPEG/PNG) from a file.
    final dir = await Directory.systemTemp.createTemp('shareloop_check');
    final file = File('${dir.path}/photo');
    await file.writeAsBytes(bytes, flush: true);
    final input = InputImage.fromFilePath(file.path);

    final labeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.4),
    );
    final poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.single,
        model: PoseDetectionModel.accurate,
      ),
    );
    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        minFaceSize: 0.05,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
    try {
      final labels = await labeler.processImage(input);
      final poses = await poseDetector.processImage(input);
      final faces = await faceDetector.processImage(input);
      return PhotoFindings(
        labels: {for (final l in labels) l.label: l.confidence},
        poses: [
          for (final pose in poses)
            PoseFinding(
              visibleLandmarks: pose.landmarks.values
                  .where((l) => l.likelihood >= 0.5)
                  .length,
            ),
        ],
        // ML Kit reports faces without a score; each one counts.
        faces: [for (final _ in faces) const Detection(score: 1)],
      );
    } finally {
      await labeler.close();
      await poseDetector.close();
      await faceDetector.close();
      try {
        await dir.delete(recursive: true);
      } catch (_) {
        // A leftover temp file is harmless; the OS clears its cache.
      }
    }
  }
}
