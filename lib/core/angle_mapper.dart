import 'dart:math' as math;

import 'clock_time.dart';

/// Açı ile kadran konumu arasındaki dönüşümler. Tüm açılar derece cinsinden,
/// 12 yönü 0°, saat yönü pozitif, [0, 360) aralığında normalize edilir.
///
/// Hem ekrandaki sürükleme hem de kamera modu bu sınıfı kullanır; kamera
/// modunda adım genelde 30° (5 dakika) ve tolerans ±12-15° olur.
class AngleMapper {
  AngleMapper._();

  static const double degreesPerMinute = 6;
  static const double degreesPerHour = 30;

  /// Açıyı [0, 360) aralığına getirir.
  static double normalize(double degrees) {
    final n = degrees % 360;
    return n < 0 ? n + 360 : n;
  }

  /// İki açı arasındaki en kısa fark, [0, 180].
  static double angularDistance(double a, double b) {
    final d = (normalize(a) - normalize(b)).abs();
    return d > 180 ? 360 - d : d;
  }

  /// Ekran koordinatlarında (x sağa, y aşağı) bir vektörün 12 yönüne göre
  /// saat yönündeki açısı. Örn. sağa (3 yönü) 90°, aşağı (6 yönü) 180°.
  static double angleFromVertical({required double dx, required double dy}) {
    if (dx == 0 && dy == 0) return 0;
    return normalize(math.atan2(dx, -dy) * 180 / math.pi);
  }

  /// Kadran merkezine göre bir noktanın açısı.
  static double angleFromCenter({
    required double centerX,
    required double centerY,
    required double x,
    required double y,
  }) =>
      angleFromVertical(dx: x - centerX, dy: y - centerY);

  /// Açıyı en yakın dakikaya çevirir (0-59).
  static int angleToMinute(double degrees) =>
      (normalize(degrees) / degreesPerMinute).round() % 60;

  /// Açıyı en yakın saat dilimine çevirir (0-11; 0 = 12 yönü).
  static int angleToHourIndex(double degrees) =>
      (normalize(degrees) / degreesPerHour).round() % 12;

  /// Açıyı `stepDegrees` adımlarına oturtur. Açı en yakın adıma `tolerance`
  /// dereceden uzaksa null döner.
  static double? snapToStep(
    double degrees, {
    required double stepDegrees,
    required double tolerance,
  }) {
    assert(stepDegrees > 0);
    final n = normalize(degrees);
    final snapped = normalize((n / stepDegrees).round() * stepDegrees);
    return angularDistance(n, snapped) <= tolerance ? snapped : null;
  }

  /// Yelkovan açısını `minuteStep` dakikalık adımlara oturtarak dakikaya
  /// çevirir; tolerans dışındaysa null döner.
  static int? angleToSnappedMinute(
    double degrees, {
    int minuteStep = 5,
    double tolerance = 15,
  }) {
    final snapped = snapToStep(
      degrees,
      stepDegrees: minuteStep * degreesPerMinute,
      tolerance: tolerance,
    );
    if (snapped == null) return null;
    return (snapped / degreesPerMinute).round() % 60;
  }

  /// Akrep ve yelkovan açılarından saati okur.
  ///
  /// Önce dakika `minuteStep` adımına oturtulur. Sonra akrep için 12 olası
  /// saat arasından, o dakikada beklenen akrep konumuna en yakın olan seçilir.
  /// `hourTolerance` ile 3:30'da akrebin 3 ile 4 arasında olması kuralı
  /// gevşetilebilir (ilk seviyelerde ~20°, sonra ~12°).
  static ClockTime? readClock({
    required double hourAngle,
    required double minuteAngle,
    int minuteStep = 5,
    double minuteTolerance = 15,
    double hourTolerance = 20,
  }) {
    final minute = angleToSnappedMinute(
      minuteAngle,
      minuteStep: minuteStep,
      tolerance: minuteTolerance,
    );
    if (minute == null) return null;

    // Beraberlikte (ör. 3:30'da akrep tam 3'ün üstünde: 2:30 ile 3:30 eşit
    // uzak) çocuğun "akrep 3'te" okumasına uyan, akrebin geçtiği rakam seçilir.
    final naiveHour = (normalize(hourAngle) / degreesPerHour).floor() % 12;
    const epsilon = 1e-9;

    int? bestHour;
    double bestDistance = double.infinity;
    for (var h = 0; h < 12; h++) {
      final expected = ClockTime(h, minute).hourHandAngle;
      final d = angularDistance(hourAngle, expected);
      final closer = d < bestDistance - epsilon;
      final tieButNaive =
          (d - bestDistance).abs() <= epsilon && h == naiveHour;
      if (closer || tieButNaive) {
        bestDistance = d;
        bestHour = h;
      }
    }
    if (bestHour == null || bestDistance > hourTolerance) return null;
    return ClockTime(bestHour, minute);
  }

  /// Bir açının hedefe yeterince yakın olup olmadığı.
  static bool matches(double angle, double target, {double tolerance = 15}) =>
      angularDistance(angle, target) <= tolerance;
}
