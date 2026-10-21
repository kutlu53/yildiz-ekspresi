/// Saat ve dakikayı temsil eden, UI'dan bağımsız saf Dart sınıfı.
///
/// `hour` 0-23 aralığında tutulur (gün seviyesi için gerekli), analog kadran
/// için `hour12` kullanılır. Akrep ve yelkovan açıları derece cinsinden,
/// 12 yönü 0° ve saat yönü pozitif olacak şekilde hesaplanır.
class ClockTime {
  final int hour;
  final int minute;

  const ClockTime(this.hour, this.minute)
      : assert(hour >= 0 && hour < 24, 'hour 0-23 olmalı'),
        assert(minute >= 0 && minute < 60, 'minute 0-59 olmalı');

  factory ClockTime.fromMinutesSinceMidnight(int minutes) {
    final m = ((minutes % 1440) + 1440) % 1440;
    return ClockTime(m ~/ 60, m % 60);
  }

  int get minutesSinceMidnight => hour * 60 + minute;

  /// Kadrandaki saat: 1-12.
  int get hour12 => hour % 12 == 0 ? 12 : hour % 12;

  /// Akrep açısı. 3:30'da akrep 3 ile 4'ün tam ortasındadır (105°).
  double get hourHandAngle => ((hour % 12) * 30 + minute * 0.5) % 360;

  /// Yelkovan açısı. Her dakika 6°.
  double get minuteHandAngle => (minute * 6).toDouble();

  /// "3:05" biçiminde 12 saatlik dijital gösterim.
  String get digital12 => '$hour12:${minute.toString().padLeft(2, '0')}';

  /// "15:05" biçiminde 24 saatlik dijital gösterim.
  String get digital24 =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// Dakikayı verilen adıma (ör. 5) en yakın değere yuvarlar; 60'a taşarsa
  /// saat ilerler.
  ClockTime roundedToMinuteStep(int step) {
    assert(step > 0 && 60 % step == 0, 'step 60 sayısını bölmeli');
    final rounded = ((minute / step).round() * step);
    return ClockTime.fromMinutesSinceMidnight(hour * 60 + rounded);
  }

  ClockTime addMinutes(int delta) =>
      ClockTime.fromMinutesSinceMidnight(minutesSinceMidnight + delta);

  /// Analog kadranda aynı görünüp görünmediği (12 saatlik eşitlik).
  bool sameOnDial(ClockTime other) =>
      hour % 12 == other.hour % 12 && minute == other.minute;

  @override
  bool operator ==(Object other) =>
      other is ClockTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => 'ClockTime($digital24)';
}
