import '../../core/angle_mapper.dart';
import '../../core/clock_time.dart';

enum ClockHand { hour, minute }

/// Sürüklenebilir saatin UI'dan bağımsız mantığı: dokunulan noktaya göre
/// hangi el seçilir, el sürüklenince saat nasıl değişir.
class ClockDragLogic {
  ClockDragLogic._();

  /// Dokunma açısına ve merkeze uzaklığına göre tutulacak eli seçer.
  /// `radiusFraction` dokunmanın kadran yarıçapına oranı (0 merkez, 1 kenar).
  static ClockHand? pickHand({
    required ClockTime time,
    required double touchAngle,
    required double radiusFraction,
    required Set<ClockHand> draggable,
  }) {
    if (draggable.isEmpty) return null;
    if (draggable.length == 1) return draggable.first;

    final dHour = AngleMapper.angularDistance(touchAngle, time.hourHandAngle);
    final dMinute =
        AngleMapper.angularDistance(touchAngle, time.minuteHandAngle);
    const closeEnough = 25.0;

    final hourNear = dHour <= closeEnough;
    final minuteNear = dMinute <= closeEnough;
    if (hourNear && !minuteNear) return ClockHand.hour;
    if (minuteNear && !hourNear) return ClockHand.minute;
    if (hourNear && minuteNear) {
      // İkisi de yakın: merkeze yakın dokunuş kısa eli, uzak dokunuş uzun eli.
      return radiusFraction < 0.6 ? ClockHand.hour : ClockHand.minute;
    }
    return dHour <= dMinute ? ClockHand.hour : ClockHand.minute;
  }

  /// Yelkovanı `angle` yönüne sürükler. `minuteStep` adımına oturtur.
  /// `linkHours` açıksa 12'yi geçince akrep ilerler ya da geriler.
  static ClockTime dragMinute(
    ClockTime time,
    double angle, {
    int minuteStep = 1,
    bool linkHours = true,
  }) {
    assert(minuteStep > 0 && 60 % minuteStep == 0);
    final raw = AngleMapper.normalize(angle) / AngleMapper.degreesPerMinute;
    final snapped = ((raw / minuteStep).round() * minuteStep) % 60;
    var hour = time.hour;
    if (linkHours) {
      if (time.minute >= 45 && snapped < 15) hour = (hour + 1) % 24;
      if (time.minute < 15 && snapped >= 45) hour = (hour + 23) % 24;
    }
    return ClockTime(hour, snapped);
  }

  /// Akrebi `angle` yönüne sürükler; dakika sabit kalır, akrep o dakikada
  /// beklenen ofsetiyle (dakika × 0,5°) en yakın saate oturur.
  static ClockTime dragHour(ClockTime time, double angle) {
    final offset = time.minute * 0.5;
    final idx = (AngleMapper.normalize(angle - offset) /
                AngleMapper.degreesPerHour)
            .round() %
        12;
    final pm = time.hour >= 12;
    return ClockTime(pm ? idx + 12 : idx, time.minute);
  }
}
