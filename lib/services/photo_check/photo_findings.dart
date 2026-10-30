import 'dart:convert';
import 'dart:ui' show Rect;

/// What the on-device detectors saw in one photo, in a form shared by every
/// platform (ML Kit on phones, MediaPipe on the web). Boxes are normalised
/// to 0–1 of the image size; null when the detector gives no position.
class PhotoFindings {
  const PhotoFindings({
    this.hands = const [],
    this.faces = const [],
    this.poses = const [],
    this.people = const [],
    this.printSurfaces = const [],
    this.labels = const {},
  });

  /// One entry per detected hand.
  final List<Detection> hands;
  final List<Detection> faces;

  /// One entry per detected body pose.
  final List<PoseFinding> poses;

  /// Object-detector "person" boxes.
  final List<Detection> people;

  /// Books, screens and similar objects whose surface can show a printed
  /// or displayed picture of a person (e.g. a textbook cover).
  final List<Detection> printSurfaces;

  /// Whole-image labels with their confidence, e.g. {'Hand': 0.82}.
  final Map<String, double> labels;

  /// Reads the JSON summary from web/photo_check.js. Boxes there are
  /// [left, top, width, height] fractions.
  factory PhotoFindings.fromSummaryJson(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    Rect? box(Object? value) {
      if (value is! List || value.length != 4) return null;
      final [l, t, w, h] = [for (final v in value) (v as num).toDouble()];
      return Rect.fromLTWH(l, t, w, h);
    }

    List<Detection> detections(String key) => [
          for (final d in (data[key] as List? ?? const []).cast<Map>())
            Detection(
              score: (d['score'] as num).toDouble(),
              box: box(d['box']),
            ),
        ];

    return PhotoFindings(
      hands: detections('hands'),
      faces: detections('faces'),
      people: detections('people'),
      printSurfaces: detections('surfaces'),
      poses: [
        for (final p in (data['poses'] as List? ?? const []).cast<Map>())
          PoseFinding(
            visibleLandmarks: (p['visible'] as num).toInt(),
            box: box(p['box']),
          ),
      ],
    );
  }
}

class Detection {
  const Detection({required this.score, this.box});

  final double score;
  final Rect? box;
}

class PoseFinding {
  const PoseFinding({required this.visibleLandmarks, this.box});

  /// Body landmarks (shoulders, wrists, knees, …) the model is reasonably
  /// sure are in the frame.
  final int visibleLandmarks;
  final Rect? box;
}

/// The donation-photo rule: reject the photo if any real person or visible
/// body part is detected.
///
/// Hands, faces and body-part labels are strong signals and reject on
/// their own. Body poses and "person" boxes are weak: run on real item-only
/// photos, the pose model drew bodies on a book cover and on sneakers, and
/// the person class fired on a T-shirt and a cap. So those two reject only
/// when they back each other up (or a person/body label backs up a pose).
/// Thresholds were checked against a handful of sample photos, not
/// measured on a labelled test set.
class PhotoPolicy {
  PhotoPolicy._();

  static const double handScore = 0.5;
  static const double faceScore = 0.5;
  static const double personScore = 0.6;
  static const double labelScore = 0.6;

  /// Lower bar for a label that only backs up a detected pose.
  static const double supportingLabelScore = 0.4;
  static const int poseLandmarks = 3;

  /// Image labels (ML Kit) that mean a body part or skin is in the photo.
  /// These have no position, so they always count.
  static const Set<String> bodyPartLabels = {
    'Hand',
    'Nail',
    'Skin',
    'Flesh',
    'Foot',
    'Toe',
    'Muscle',
    'Tattoo',
    'Selfie',
    'Hair',
    'Bangs',
    'Beard',
    'Moustache',
    'Ear',
    'Eyelash',
    'Mouth',
  };

  /// Image labels that mean a whole person is in the photo.
  static const Set<String> personLabels = {
    'Person',
    'Baby',
    'Crowd',
    'Team',
  };

  /// Whether the photo shows a person or a visible body part.
  ///
  /// A face, pose or person box lying wholly inside a book or screen is
  /// treated as a printed or displayed picture, not a person in the scene,
  /// so a textbook with a face on its cover isn't refused for that alone.
  /// Hands and body-part labels are never excused this way.
  static bool containsPerson(PhotoFindings f) {
    if (f.hands.any((h) => h.score >= handScore)) return true;
    for (final MapEntry(key: label, value: score) in f.labels.entries) {
      if (score < labelScore) continue;
      if (bodyPartLabels.contains(label) || personLabels.contains(label)) {
        return true;
      }
    }
    bool real(Rect? box) => !_insideAnyPrintSurface(box, f.printSurfaces);
    if (f.faces.any((d) => d.score >= faceScore && real(d.box))) return true;

    // Weak signals: a body pose confirmed by an overlapping person box or
    // by a person/body label.
    final people = [
      for (final d in f.people)
        if (d.score >= personScore && real(d.box)) d,
    ];
    final labelled = f.labels.entries.any(
      (e) =>
          e.value >= supportingLabelScore &&
          (bodyPartLabels.contains(e.key) || personLabels.contains(e.key)),
    );
    for (final pose in f.poses) {
      if (pose.visibleLandmarks < poseLandmarks || !real(pose.box)) continue;
      if (labelled) return true;
      if (people.any((p) => _overlap(p.box, pose.box))) return true;
    }
    return false;
  }

  /// Whether two boxes intersect; unknown positions count as overlapping.
  static bool _overlap(Rect? a, Rect? b) =>
      a == null || b == null || a.overlaps(b);

  static bool _insideAnyPrintSurface(Rect? box, List<Detection> surfaces) {
    if (box == null) return false;
    // A little slack for boxes that touch the cover's edge.
    return surfaces.any(
      (s) => s.box != null && s.box!.inflate(0.02).contains(box.topLeft) &&
          s.box!.inflate(0.02).contains(box.bottomRight),
    );
  }
}
