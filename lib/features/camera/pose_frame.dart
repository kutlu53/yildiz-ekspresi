import 'dart:math' as math;

import '../../core/angle_mapper.dart';

/// Normalize (0-1) ekran koordinatında bir vücut noktası. x sağa, y aşağı.
/// Koordinatlar **ayna görünümüne** göre tutulur: çocuğun sağ kolu ekranın
/// sağında görünür.
class PosePoint {
  final double x;
  final double y;
  final double visibility;

  const PosePoint(this.x, this.y, this.visibility);

  double distanceTo(PosePoint other) =>
      math.sqrt((x - other.x) * (x - other.x) + (y - other.y) * (y - other.y));
}

/// Tek bir kolun omuz → bilek vektörü ve bunun kadran açısı.
class ArmReading {
  final PosePoint shoulder;
  final PosePoint wrist;

  const ArmReading({required this.shoulder, required this.wrist});

  /// 12 yönü 0°, saat yönü pozitif.
  double get angle => AngleMapper.angleFromVertical(
        dx: wrist.x - shoulder.x,
        dy: wrist.y - shoulder.y,
      );

  /// Omuz ve bileğin en düşük görünürlüğü.
  double get confidence => math.min(shoulder.visibility, wrist.visibility);

  /// Normalize uzunluk; kol gövdeye çok yakınsa açı güvenilmez.
  double get length => shoulder.distanceTo(wrist);
}

/// Bir kamera karesinden çıkarılan kol okumaları.
///
/// Sol kol = akrep (kısa, kırmızı), sağ kol = yelkovan (uzun, mavi).
class PoseFrame {
  final ArmReading? hourArm;
  final ArmReading? minuteArm;
  final double fps;
  final double videoWidth;
  final double videoHeight;

  const PoseFrame({
    required this.hourArm,
    required this.minuteArm,
    required this.fps,
    required this.videoWidth,
    required this.videoHeight,
  });

  static const PoseFrame empty = PoseFrame(
    hourArm: null,
    minuteArm: null,
    fps: 0,
    videoWidth: 4,
    videoHeight: 3,
  );

  bool get hasPose => hourArm != null || minuteArm != null;

  double get aspectRatio =>
      videoHeight > 0 ? videoWidth / videoHeight : 4 / 3;

  /// Omuzların orta noktası; kadranın merkezi olarak kullanılır.
  PosePoint? get shoulderCenter {
    final l = hourArm?.shoulder;
    final r = minuteArm?.shoulder;
    if (l != null && r != null) {
      return PosePoint((l.x + r.x) / 2, (l.y + r.y) / 2,
          math.min(l.visibility, r.visibility));
    }
    return l ?? r;
  }

  /// Kadran yarıçapı için kol uzunluğu tahmini (normalize birim).
  double get armLength {
    final a = hourArm?.length ?? 0;
    final b = minuteArm?.length ?? 0;
    return math.max(a, b);
  }

  /// MediaPipe'ın sol omuz, sağ omuz, sol bilek, sağ bilek noktalarından
  /// (her biri x, y, visibility) kare üretir. Noktalar ayna görünümüne çevrilir.
  ///
  /// `minVisibility` altındaki kollar yok sayılır.
  static PoseFrame fromLandmarks(
    List<double> pts, {
    required double fps,
    required double videoWidth,
    required double videoHeight,
    bool mirrored = true,
    double minVisibility = 0.5,
    double minArmLength = 0.08,
  }) {
    if (pts.length < 12) {
      return PoseFrame(
        hourArm: null,
        minuteArm: null,
        fps: fps,
        videoWidth: videoWidth,
        videoHeight: videoHeight,
      );
    }

    PosePoint point(int i) {
      final x = pts[i * 3];
      return PosePoint(mirrored ? 1 - x : x, pts[i * 3 + 1], pts[i * 3 + 2]);
    }

    final leftShoulder = point(0);
    final rightShoulder = point(1);
    final leftWrist = point(2);
    final rightWrist = point(3);

    ArmReading? arm(PosePoint shoulder, PosePoint wrist) {
      final reading = ArmReading(shoulder: shoulder, wrist: wrist);
      if (reading.confidence < minVisibility) return null;
      if (reading.length < minArmLength) return null;
      return reading;
    }

    return PoseFrame(
      hourArm: arm(leftShoulder, leftWrist),
      minuteArm: arm(rightShoulder, rightWrist),
      fps: fps,
      videoWidth: videoWidth,
      videoHeight: videoHeight,
    );
  }
}
