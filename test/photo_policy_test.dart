import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';

import 'package:shareloop/services/photo_check/photo_content_checker.dart';
import 'package:shareloop/services/photo_check/photo_findings.dart';

// These tests feed the policy the kind of detector output each scene
// produces (MediaPipe-style boxes on the web, ML Kit labels on phones).
// They check the decision rules, not how well the models see real photos.

const _bookOnTable = Detection(
  score: 0.8,
  box: Rect.fromLTWH(0.2, 0.15, 0.6, 0.7),
);

bool _rejects(PhotoFindings f) => PhotoPolicy.containsPerson(f);

class _FakeChecker extends FindingsPhotoChecker {
  _FakeChecker(this.byFirstByte);

  /// Findings to report, chosen by the photo's first byte.
  final Map<int, PhotoFindings> byFirstByte;

  @override
  Future<PhotoFindings> analyse(Uint8List bytes, {String? mimeType}) async {
    final findings = byFirstByte[bytes.first];
    if (findings == null) throw StateError('model not loaded');
    return findings;
  }
}

void main() {
  group('reject: a person or body part is in the scene', () {
    test('a hand holding books', () {
      expect(
        _rejects(
          const PhotoFindings(
            hands: [Detection(score: 0.93)],
            printSurfaces: [_bookOnTable],
          ),
        ),
        isTrue,
      );
      // Phone (ML Kit) version of the same scene.
      expect(
        _rejects(const PhotoFindings(labels: {'Book': 0.9, 'Hand': 0.81})),
        isTrue,
      );
    });

    test('fingers holding an object, no face anywhere', () {
      expect(
        _rejects(const PhotoFindings(hands: [Detection(score: 0.62)])),
        isTrue,
      );
      expect(
        _rejects(const PhotoFindings(labels: {'Nail': 0.7, 'Bottle': 0.9})),
        isTrue,
      );
    });

    test('a face or body in the background', () {
      expect(
        _rejects(
          const PhotoFindings(
            faces: [Detection(score: 0.7, box: Rect.fromLTWH(0.8, 0.05, 0.1, 0.1))],
            printSurfaces: [_bookOnTable],
          ),
        ),
        isTrue,
      );
      // Someone with their back turned: a person box and a body pose.
      expect(
        _rejects(
          const PhotoFindings(
            people: [Detection(score: 0.8, box: Rect.fromLTWH(0.7, 0, 0.3, 1))],
            poses: [
              PoseFinding(
                visibleLandmarks: 12,
                box: Rect.fromLTWH(0.72, 0.05, 0.25, 0.9),
              ),
            ],
          ),
        ),
        isTrue,
      );
      // ML Kit faces have no score or box: any face counts.
      expect(
        _rejects(const PhotoFindings(faces: [Detection(score: 1)])),
        isTrue,
      );
    });

    test('part of an arm at the edge of a cropped photo', () {
      // Shoulder, elbow and wrist along the left edge, with skin seen.
      expect(
        _rejects(
          const PhotoFindings(
            poses: [
              PoseFinding(
                visibleLandmarks: 3,
                box: Rect.fromLTWH(0, 0.3, 0.12, 0.5),
              ),
            ],
            labels: {'Skin': 0.45},
          ),
        ),
        isTrue,
      );
      expect(_rejects(const PhotoFindings(labels: {'Skin': 0.66})), isTrue);
      // The arm's hand at the edge.
      expect(
        _rejects(const PhotoFindings(hands: [Detection(score: 0.7)])),
        isTrue,
      );
    });

    test('a hand on a book cover is never excused as printed', () {
      expect(
        _rejects(
          const PhotoFindings(
            hands: [Detection(score: 0.8)],
            printSurfaces: [_bookOnTable],
          ),
        ),
        isTrue,
      );
    });
  });

  group('accept: the item alone', () {
    test('books alone on a table', () {
      expect(
        _rejects(const PhotoFindings(printSurfaces: [_bookOnTable])),
        isFalse,
      );
      expect(
        _rejects(const PhotoFindings(labels: {'Book': 0.92, 'Table': 0.7})),
        isFalse,
      );
    });

    test('a person printed on the cover is not refused for that alone', () {
      // Face, body and "person" all lie inside the book's box.
      expect(
        _rejects(
          const PhotoFindings(
            printSurfaces: [_bookOnTable],
            faces: [
              Detection(score: 0.9, box: Rect.fromLTWH(0.4, 0.25, 0.15, 0.15)),
            ],
            people: [
              Detection(score: 0.6, box: Rect.fromLTWH(0.3, 0.2, 0.4, 0.6)),
            ],
            poses: [
              PoseFinding(
                visibleLandmarks: 8,
                box: Rect.fromLTWH(0.32, 0.22, 0.35, 0.55),
              ),
            ],
          ),
        ),
        isFalse,
      );
    });

    test('a face partly outside the book counts as real', () {
      expect(
        _rejects(
          const PhotoFindings(
            printSurfaces: [_bookOnTable],
            faces: [
              Detection(score: 0.9, box: Rect.fromLTWH(0.7, 0.05, 0.2, 0.2)),
            ],
          ),
        ),
        isTrue,
      );
    });

    test('a lone pose or person box is not enough', () {
      // What the models reported on item-only sample photos.
      expect(
        _rejects(
          const PhotoFindings(
            poses: [
              PoseFinding(
                visibleLandmarks: 24,
                box: Rect.fromLTWH(0.34, 0.42, 0.45, 0.25),
              ),
            ],
          ),
        ),
        isFalse,
        reason: 'pose drawn on a book cover',
      );
      expect(
        _rejects(
          const PhotoFindings(
            people: [
              Detection(score: 0.75, box: Rect.fromLTWH(0.2, 0.1, 0.6, 0.8)),
            ],
          ),
        ),
        isFalse,
        reason: '"person" on a T-shirt',
      );
    });

    test('weak signals below the thresholds', () {
      expect(
        _rejects(
          const PhotoFindings(
            hands: [Detection(score: 0.3)],
            labels: {'Hand': 0.45},
            poses: [PoseFinding(visibleLandmarks: 2)],
          ),
        ),
        isFalse,
      );
    });
  });

  group('real MediaPipe output (headless Chrome, web/photo_check.js)', () {
    // Recorded by running the app's web detector on the app's bundled
    // images. Each entry is decided from what the models saw, not its name.
    final recorded = (jsonDecode(
      File('test/fixtures/mediapipe_sample_results.json').readAsStringSync(),
    ) as Map<String, dynamic>)
        .map((name, v) => MapEntry(name, jsonEncode(v)));

    const itemOnly = [
      'item_grade10_science.jpg',
      'item_grey_cap.jpg',
      'item_leather_backpack.jpg',
      'item_leather_brogues.jpg',
      'item_pressure_cooker.jpg',
      'item_slip_on_sneakers.jpg',
      'item_smartphone.jpg',
      'item_white_tshirt.jpg',
    ];
    // Illustrations of people handing items over, hands and faces visible.
    const withPeople = [
      'login_hero.jpg',
      'onboarding_give.jpg',
      'onboarding_share.jpg',
    ];

    for (final name in itemOnly) {
      test('accepts the item-only photo $name', () {
        expect(_rejects(PhotoFindings.fromSummaryJson(recorded[name]!)), isFalse);
      });
    }
    for (final name in withPeople) {
      test('rejects $name, which shows people and hands', () {
        expect(_rejects(PhotoFindings.fromSummaryJson(recorded[name]!)), isTrue);
      });
    }
  });

  test('reads the web detector summary', () {
    final f = PhotoFindings.fromSummaryJson(
      '{"hands":[{"score":0.9}],'
      '"poses":[{"visible":5,"box":[0,0.1,0.2,0.3]}],'
      '"faces":[],"people":[{"score":0.5,"box":[0.5,0,0.5,1]}],'
      '"surfaces":[{"score":0.8,"box":[0.2,0.15,0.6,0.7]}]}',
    );
    expect(f.hands.single.score, 0.9);
    expect(f.poses.single.visibleLandmarks, 5);
    expect(f.poses.single.box, const Rect.fromLTWH(0, 0.1, 0.2, 0.3));
    expect(f.people.single.box, const Rect.fromLTWH(0.5, 0, 0.5, 1));
    expect(f.printSurfaces, hasLength(1));
    expect(PhotoPolicy.containsPerson(f), isTrue);
  });

  group('checking several photos', () {
    final checker = _FakeChecker({
      1: const PhotoFindings(printSurfaces: [_bookOnTable]),
      2: const PhotoFindings(hands: [Detection(score: 0.9)]),
    });
    ({Uint8List bytes, String? mimeType}) photo(int id) =>
        (bytes: Uint8List.fromList([id, 0, 0]), mimeType: 'image/jpeg');

    test('each photo gets its own outcome', () async {
      expect(await checkPhotos(checker, [photo(1), photo(2), photo(1)]), [
        PhotoCheckOutcome.clear,
        PhotoCheckOutcome.containsPerson,
        PhotoCheckOutcome.clear,
      ]);
    });

    test('a detector failure is never a pass', () async {
      // Photo 9 makes the fake detector throw, like a model that won't load.
      expect(await checkPhotos(checker, [photo(1), photo(9)]), [
        PhotoCheckOutcome.clear,
        PhotoCheckOutcome.failed,
      ]);
    });

    test('a device without a detector refuses every photo', () async {
      expect(
        await checkPhotos(const UnsupportedPhotoChecker(), [photo(1)]),
        [PhotoCheckOutcome.unsupported],
      );
    });
  });
}
