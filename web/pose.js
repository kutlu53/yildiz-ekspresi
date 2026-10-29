// Zaman Bekçisi - Faz 0 kamera köprüsü.
// MediaPipe Pose Landmarker'ı tarayıcıda çalıştırır ve omuz/bilek noktalarını
// Flutter'a iletir. Görüntü yalnızca bu cihazda işlenir; hiçbir kare diske
// veya ağa yazılmaz.

import {
  PoseLandmarker,
  FilesetResolver,
} from "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.22";

const WASM_PATH =
  "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.22/wasm";
const MODEL_PATH =
  "https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/1/pose_landmarker_lite.task";

// MediaPipe BlazePose indeksleri.
const LEFT_SHOULDER = 11;
const RIGHT_SHOULDER = 12;
const LEFT_WRIST = 15;
const RIGHT_WRIST = 16;

let landmarker = null;
let stream = null;
let video = null;
let rafId = null;
let running = false;
let lastVideoTime = -1;
let frameCount = 0;
let fpsWindowStart = 0;
let fps = 0;

async function createLandmarker(delegate) {
  const vision = await FilesetResolver.forVisionTasks(WASM_PATH);
  return PoseLandmarker.createFromOptions(vision, {
    baseOptions: { modelAssetPath: MODEL_PATH, delegate },
    runningMode: "VIDEO",
    numPoses: 1,
    minPoseDetectionConfidence: 0.5,
    minPosePresenceConfidence: 0.5,
    minTrackingConfidence: 0.5,
  });
}

async function ensureLandmarker() {
  if (landmarker) return landmarker;
  try {
    landmarker = await createLandmarker("GPU");
  } catch (e) {
    console.warn("[zamanPose] GPU delegate başarısız, CPU deneniyor", e);
    landmarker = await createLandmarker("CPU");
  }
  return landmarker;
}

/**
 * Kamerayı açar ve her karede onFrame(points, fps, width, height) çağırır.
 * points: [lsx, lsy, lsv, rsx, rsy, rsv, lwx, lwy, lwv, rwx, rwy, rwv]
 * (poz yoksa boş dizi).
 */
async function start(videoElement, onFrame) {
  if (running) return;
  video = videoElement;
  if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
    throw new Error(
      "navigator.mediaDevices yok: kamera yalnız https (güvenli bağlantı) altında açılır."
    );
  }

  // Önce kamera: izin sorusu ve önizleme hemen gelsin; model (birkaç MB)
  // sonra yüklenir. Önceki sırada yavaş ağda kamera hiç açılmıyor sanılıyordu.
  stream = await navigator.mediaDevices.getUserMedia({
    video: {
      facingMode: "user",
      width: { ideal: 640 },
      height: { ideal: 480 },
    },
    audio: false,
  });
  video.srcObject = stream;
  await new Promise((resolve) => {
    if (video.readyState >= 2) resolve();
    else video.onloadeddata = () => resolve();
  });
  await video.play();

  try {
    await ensureLandmarker();
  } catch (e) {
    for (const track of stream.getTracks()) track.stop();
    stream = null;
    video.srcObject = null;
    throw new Error("pose.js modeli yüklenemedi (internet gerekli): " + e);
  }

  running = true;
  frameCount = 0;
  fpsWindowStart = performance.now();

  const loop = () => {
    if (!running) return;
    if (video.currentTime !== lastVideoTime) {
      lastVideoTime = video.currentTime;
      const now = performance.now();
      const result = landmarker.detectForVideo(video, now);

      frameCount++;
      if (now - fpsWindowStart >= 1000) {
        fps = (frameCount * 1000) / (now - fpsWindowStart);
        frameCount = 0;
        fpsWindowStart = now;
      }

      const points = [];
      const lm = result.landmarks && result.landmarks[0];
      if (lm) {
        for (const i of [LEFT_SHOULDER, RIGHT_SHOULDER, LEFT_WRIST, RIGHT_WRIST]) {
          const p = lm[i];
          points.push(p.x, p.y, p.visibility ?? 0);
        }
      }
      onFrame(points, fps, video.videoWidth, video.videoHeight);
    }
    rafId = requestAnimationFrame(loop);
  };
  rafId = requestAnimationFrame(loop);
}

function stop() {
  running = false;
  if (rafId !== null) {
    cancelAnimationFrame(rafId);
    rafId = null;
  }
  if (stream) {
    for (const track of stream.getTracks()) track.stop();
    stream = null;
  }
  if (video) {
    video.srcObject = null;
    video = null;
  }
  lastVideoTime = -1;
  fps = 0;
}

window.zamanPose = { start, stop };
