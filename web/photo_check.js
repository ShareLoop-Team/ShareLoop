// On-device check of donation photos for people and body parts, using
// MediaPipe Tasks Vision in the browser (WebAssembly). The photo never
// leaves the device: only the library and model files are downloaded, once.
//
// Exposes window.shareloopPhotoCheck(bytes, mimeType) -> Promise<string>,
// a JSON summary the Dart side turns into PhotoFindings.

const VERSION = '0.10.14';
const LIB = `https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@${VERSION}`;
const MODELS = 'https://storage.googleapis.com/mediapipe-models';

// Objects whose surface can carry a printed or displayed picture of a person.
const PRINT_SURFACES = new Set(['book', 'tv', 'laptop', 'cell phone']);

let detectorsPromise = null;

function loadDetectors() {
  if (!detectorsPromise) {
    detectorsPromise = (async () => {
      const vision = await import(`${LIB}/vision_bundle.mjs`);
      const files = await vision.FilesetResolver.forVisionTasks(`${LIB}/wasm`);
      const base = (path) => ({ modelAssetPath: `${MODELS}/${path}` });
      const [hands, poses, faces, objects] = await Promise.all([
        vision.HandLandmarker.createFromOptions(files, {
          baseOptions: base('hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task'),
          runningMode: 'IMAGE',
          numHands: 4,
          minHandDetectionConfidence: 0.4,
        }),
        vision.PoseLandmarker.createFromOptions(files, {
          baseOptions: base('pose_landmarker/pose_landmarker_lite/float16/1/pose_landmarker_lite.task'),
          runningMode: 'IMAGE',
          numPoses: 4,
        }),
        vision.FaceDetector.createFromOptions(files, {
          baseOptions: base('face_detector/blaze_face_short_range/float16/1/blaze_face_short_range.tflite'),
          runningMode: 'IMAGE',
          minDetectionConfidence: 0.5,
        }),
        vision.ObjectDetector.createFromOptions(files, {
          baseOptions: base('object_detector/efficientdet_lite0/float16/1/efficientdet_lite0.tflite'),
          runningMode: 'IMAGE',
          scoreThreshold: 0.3,
          maxResults: 25,
        }),
      ]);
      return { hands, poses, faces, objects };
    })();
    // A failed load (e.g. offline) may succeed on the next try.
    detectorsPromise.catch(() => { detectorsPromise = null; });
  }
  return detectorsPromise;
}

function decode(bytes, mimeType) {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(new Blob([bytes], { type: mimeType || 'image/jpeg' }));
    const img = new Image();
    img.onload = () => { URL.revokeObjectURL(url); resolve(img); };
    img.onerror = () => { URL.revokeObjectURL(url); reject(new Error('Photo could not be decoded')); };
    img.src = url;
  });
}

window.shareloopPhotoCheck = async function (bytes, mimeType) {
  const d = await loadDetectors();
  const img = await decode(bytes, mimeType);
  const w = img.naturalWidth;
  const h = img.naturalHeight;
  if (!w || !h) throw new Error('Photo has no size');
  // Pixel box -> [left, top, width, height] as fractions of the image.
  const norm = (b) => [b.originX / w, b.originY / h, b.width / w, b.height / h];

  const handResult = d.hands.detect(img);
  const handedness = handResult.handedness || handResult.handednesses || [];
  const hands = (handResult.landmarks || []).map((_, i) => ({
    score: handedness[i] && handedness[i][0] ? handedness[i][0].score : 1,
  }));

  const poses = (d.poses.detect(img).landmarks || []).map((points) => {
    const visible = points.filter((p) => (p.visibility ?? 1) >= 0.5);
    const xs = visible.map((p) => p.x);
    const ys = visible.map((p) => p.y);
    return {
      visible: visible.length,
      box: visible.length
        ? [Math.min(...xs), Math.min(...ys),
           Math.max(...xs) - Math.min(...xs), Math.max(...ys) - Math.min(...ys)]
        : null,
    };
  });

  const faces = (d.faces.detect(img).detections || []).map((det) => ({
    score: det.categories && det.categories[0] ? det.categories[0].score : 1,
    box: det.boundingBox ? norm(det.boundingBox) : null,
  }));

  const people = [];
  const surfaces = [];
  for (const det of d.objects.detect(img).detections || []) {
    const top = det.categories && det.categories[0];
    if (!top || !det.boundingBox) continue;
    const entry = { score: top.score, box: norm(det.boundingBox) };
    if (top.categoryName === 'person') people.push(entry);
    else if (PRINT_SURFACES.has(top.categoryName)) surfaces.push(entry);
  }

  return JSON.stringify({ hands, poses, faces, people, surfaces });
};
