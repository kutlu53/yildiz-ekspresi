import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/core/clock_time.dart';

void main() {
  group('ClockTime açıları', () {
    test('12:00 iki el de 0°', () {
      const t = ClockTime(0, 0);
      expect(t.hourHandAngle, 0);
      expect(t.minuteHandAngle, 0);
    });

    test('3:00 akrep 90°, yelkovan 0°', () {
      const t = ClockTime(3, 0);
      expect(t.hourHandAngle, 90);
      expect(t.minuteHandAngle, 0);
    });

    test('3:30 akrep 3 ile 4 ortasında (105°), yelkovan 180°', () {
      const t = ClockTime(3, 30);
      expect(t.hourHandAngle, 105);
      expect(t.minuteHandAngle, 180);
    });

    test('15:45 ve 3:45 kadranda aynı', () {
      expect(
          const ClockTime(15, 45).sameOnDial(const ClockTime(3, 45)), isTrue);
      expect(const ClockTime(15, 45).hourHandAngle,
          const ClockTime(3, 45).hourHandAngle);
    });

    test('9:15 akrep 277.5°', () {
      expect(const ClockTime(9, 15).hourHandAngle, 277.5);
    });
  });

  group('ClockTime gösterim', () {
    test('digital12 ve digital24', () {
      expect(const ClockTime(0, 5).digital12, '12:05');
      expect(const ClockTime(0, 5).digital24, '00:05');
      expect(const ClockTime(13, 7).digital12, '1:07');
      expect(const ClockTime(13, 7).digital24, '13:07');
    });

    test('hour12', () {
      expect(const ClockTime(0, 0).hour12, 12);
      expect(const ClockTime(12, 0).hour12, 12);
      expect(const ClockTime(23, 0).hour12, 11);
    });
  });

  group('ClockTime aritmetik', () {
    test('fromMinutesSinceMidnight gün içinde döner', () {
      expect(ClockTime.fromMinutesSinceMidnight(1440), const ClockTime(0, 0));
      expect(ClockTime.fromMinutesSinceMidnight(-30), const ClockTime(23, 30));
      expect(ClockTime.fromMinutesSinceMidnight(125), const ClockTime(2, 5));
    });

    test('addMinutes', () {
      expect(const ClockTime(23, 50).addMinutes(20), const ClockTime(0, 10));
      expect(const ClockTime(8, 0).addMinutes(-15), const ClockTime(7, 45));
    });

    test('roundedToMinuteStep', () {
      expect(
          const ClockTime(3, 27).roundedToMinuteStep(5), const ClockTime(3, 25));
      expect(
          const ClockTime(3, 28).roundedToMinuteStep(5), const ClockTime(3, 30));
      expect(
          const ClockTime(3, 58).roundedToMinuteStep(5), const ClockTime(4, 0));
      expect(const ClockTime(3, 20).roundedToMinuteStep(15),
          const ClockTime(3, 15));
    });
  });
}
