import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/features/camera/pose_frame.dart';

/// [ls, rs, lw, rw] her biri (x, y, visibility), ham MediaPipe koordinatı
/// (ayna uygulanmamış).
List<double> landmarks({
  required List<double> leftShoulder,
  required List<double> rightShoulder,
  required List<double> leftWrist,
  required List<double> rightWrist,
}) =>
    [...leftShoulder, ...rightShoulder, ...leftWrist, ...rightWrist];

void main() {
  group('PoseFrame.fromLandmarks', () {
    test('boş liste kol içermez', () {
      final f = PoseFrame.fromLandmarks(const [],
          fps: 30, videoWidth: 640, videoHeight: 480);
      expect(f.hasPose, isFalse);
      expect(f.aspectRatio, closeTo(4 / 3, 1e-9));
    });

    test('ham görüntüde sol omuz sağda görünür; ayna düzeltir', () {
      // Kamera karşıdan bakıyor: kişinin sol omzu ham görüntüde x=0.6,
      // sağ omzu x=0.4. Aynada sol omuz ekranın solunda (x=0.4) olmalı.
      final f = PoseFrame.fromLandmarks(
        landmarks(
          leftShoulder: [0.6, 0.5, 1],
          rightShoulder: [0.4, 0.5, 1],
          leftWrist: [0.6, 0.2, 1],
          rightWrist: [0.4, 0.2, 1],
        ),
        fps: 30,
        videoWidth: 640,
        videoHeight: 480,
      );
      expect(f.hourArm!.shoulder.x, closeTo(0.4, 1e-9));
      expect(f.minuteArm!.shoulder.x, closeTo(0.6, 1e-9));
    });

    test('sağ kol yana açık (kişinin sağı) aynada 3 yönü = 90°', () {
      // Kişinin sağ kolu ham görüntüde sola uzanır (x küçülür).
      final f = PoseFrame.fromLandmarks(
        landmarks(
          leftShoulder: [0.6, 0.5, 1],
          rightShoulder: [0.4, 0.5, 1],
          leftWrist: [0.6, 0.8, 1],
          rightWrist: [0.1, 0.5, 1],
        ),
        fps: 30,
        videoWidth: 640,
        videoHeight: 480,
      );
      expect(f.minuteArm!.angle, closeTo(90, 1e-9));
      expect(f.hourArm!.angle, closeTo(180, 1e-9));
    });

    test('sol kol yukarı 0°, sağ kol aşağı 180°', () {
      final f = PoseFrame.fromLandmarks(
        landmarks(
          leftShoulder: [0.6, 0.5, 1],
          rightShoulder: [0.4, 0.5, 1],
          leftWrist: [0.6, 0.1, 1],
          rightWrist: [0.4, 0.9, 1],
        ),
        fps: 30,
        videoWidth: 640,
        videoHeight: 480,
      );
      expect(f.hourArm!.angle, closeTo(0, 1e-9));
      expect(f.minuteArm!.angle, closeTo(180, 1e-9));
    });

    test('düşük görünürlük kol düşürülür', () {
      final f = PoseFrame.fromLandmarks(
        landmarks(
          leftShoulder: [0.6, 0.5, 1],
          rightShoulder: [0.4, 0.5, 1],
          leftWrist: [0.6, 0.1, 0.2],
          rightWrist: [0.4, 0.9, 1],
        ),
        fps: 30,
        videoWidth: 640,
        videoHeight: 480,
      );
      expect(f.hourArm, isNull);
      expect(f.minuteArm, isNotNull);
      expect(f.hasPose, isTrue);
    });

    test('kol gövdeye çok yakınsa düşürülür', () {
      final f = PoseFrame.fromLandmarks(
        landmarks(
          leftShoulder: [0.6, 0.5, 1],
          rightShoulder: [0.4, 0.5, 1],
          leftWrist: [0.61, 0.52, 1],
          rightWrist: [0.4, 0.9, 1],
        ),
        fps: 30,
        videoWidth: 640,
        videoHeight: 480,
      );
      expect(f.hourArm, isNull);
    });

    test('shoulderCenter omuzların ortası', () {
      final f = PoseFrame.fromLandmarks(
        landmarks(
          leftShoulder: [0.6, 0.5, 1],
          rightShoulder: [0.4, 0.5, 1],
          leftWrist: [0.6, 0.1, 1],
          rightWrist: [0.4, 0.9, 1],
        ),
        fps: 30,
        videoWidth: 640,
        videoHeight: 480,
      );
      expect(f.shoulderCenter!.x, closeTo(0.5, 1e-9));
      expect(f.shoulderCenter!.y, closeTo(0.5, 1e-9));
      expect(f.armLength, closeTo(0.4, 1e-9));
    });
  });
}
