import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/core/angle_mapper.dart';
import 'package:zaman_bekcisi/core/clock_time.dart';

void main() {
  group('normalize / angularDistance', () {
    test('normalize', () {
      expect(AngleMapper.normalize(370), 10);
      expect(AngleMapper.normalize(-10), 350);
      expect(AngleMapper.normalize(360), 0);
    });

    test('angularDistance en kısa yolu alır', () {
      expect(AngleMapper.angularDistance(350, 10), 20);
      expect(AngleMapper.angularDistance(10, 350), 20);
      expect(AngleMapper.angularDistance(0, 180), 180);
    });
  });

  group('angleFromVertical', () {
    test('yukarı 0°, sağ 90°, aşağı 180°, sol 270°', () {
      expect(AngleMapper.angleFromVertical(dx: 0, dy: -1), 0);
      expect(AngleMapper.angleFromVertical(dx: 1, dy: 0), 90);
      expect(AngleMapper.angleFromVertical(dx: 0, dy: 1), 180);
      expect(AngleMapper.angleFromVertical(dx: -1, dy: 0), 270);
    });

    test('çapraz 45°', () {
      expect(AngleMapper.angleFromVertical(dx: 1, dy: -1), closeTo(45, 1e-9));
    });

    test('sıfır vektör 0 döner', () {
      expect(AngleMapper.angleFromVertical(dx: 0, dy: 0), 0);
    });

    test('angleFromCenter', () {
      expect(
          AngleMapper.angleFromCenter(centerX: 50, centerY: 50, x: 50, y: 10),
          0);
      expect(
          AngleMapper.angleFromCenter(centerX: 50, centerY: 50, x: 90, y: 50),
          90);
    });
  });

  group('dakika / saat dönüşümü', () {
    test('angleToMinute', () {
      expect(AngleMapper.angleToMinute(0), 0);
      expect(AngleMapper.angleToMinute(90), 15);
      expect(AngleMapper.angleToMinute(359), 0);
      expect(AngleMapper.angleToMinute(93), 16);
    });

    test('angleToHourIndex', () {
      expect(AngleMapper.angleToHourIndex(0), 0);
      expect(AngleMapper.angleToHourIndex(90), 3);
      expect(AngleMapper.angleToHourIndex(350), 0);
    });
  });

  group('snapToStep', () {
    test('tolerans içinde oturur', () {
      expect(AngleMapper.snapToStep(100, stepDegrees: 30, tolerance: 15), 90);
      expect(AngleMapper.snapToStep(352, stepDegrees: 30, tolerance: 15), 0);
    });

    test('tolerans dışında null', () {
      expect(
          AngleMapper.snapToStep(105, stepDegrees: 30, tolerance: 12), isNull);
    });

    test('angleToSnappedMinute 5 dakikalık adım', () {
      expect(AngleMapper.angleToSnappedMinute(88), 15);
      expect(AngleMapper.angleToSnappedMinute(175), 30);
      expect(AngleMapper.angleToSnappedMinute(195, tolerance: 12), isNull);
    });
  });

  group('readClock', () {
    test('tam saat, kusursuz açılar', () {
      final t = AngleMapper.readClock(hourAngle: 90, minuteAngle: 0);
      expect(t, const ClockTime(3, 0));
    });

    test('12:00 saat indeksi 0', () {
      final t = AngleMapper.readClock(hourAngle: 2, minuteAngle: 358);
      expect(t, const ClockTime(0, 0));
      expect(t!.hour12, 12);
    });

    test('3:30 akrep 3 ile 4 arasında kabul edilir', () {
      final t = AngleMapper.readClock(hourAngle: 105, minuteAngle: 180);
      expect(t, const ClockTime(3, 30));
    });

    test('3:30 akrep tam 3 üstünde, geniş toleransla kabul', () {
      final t = AngleMapper.readClock(
          hourAngle: 90, minuteAngle: 180, hourTolerance: 20);
      expect(t, const ClockTime(3, 30));
    });

    test('12:30 akrep tam 12 üstünde 11:30 değil 12:30 okunur', () {
      final t = AngleMapper.readClock(
          hourAngle: 0, minuteAngle: 180, hourTolerance: 20);
      expect(t, const ClockTime(0, 30));
    });

    test('3:30 akrep 4\'e daha yakınsa yine 3:30', () {
      final t = AngleMapper.readClock(
          hourAngle: 112, minuteAngle: 180, hourTolerance: 20);
      expect(t, const ClockTime(3, 30));
    });

    test('3:30 akrep tam 3 üstünde, dar toleransla ret', () {
      final t = AngleMapper.readClock(
          hourAngle: 90, minuteAngle: 180, hourTolerance: 12);
      expect(t, isNull);
    });

    test('kol titremesi: 6:00 için 10° sapmalar', () {
      final t = AngleMapper.readClock(hourAngle: 170, minuteAngle: 352);
      expect(t, const ClockTime(6, 0));
    });

    test('yelkovan belirsizse null', () {
      final t = AngleMapper.readClock(
          hourAngle: 90, minuteAngle: 15, minuteTolerance: 12);
      expect(t, isNull);
    });

    test('tüm 5 dakikalık değerler kendi açılarından geri okunur', () {
      for (var h = 0; h < 12; h++) {
        for (var m = 0; m < 60; m += 5) {
          final src = ClockTime(h, m);
          final read = AngleMapper.readClock(
            hourAngle: src.hourHandAngle,
            minuteAngle: src.minuteHandAngle,
            hourTolerance: 12,
          );
          expect(read, src, reason: 'kaynak $src');
        }
      }
    });
  });

  group('matches', () {
    test('tolerans içinde ve 0/360 sınırında', () {
      expect(AngleMapper.matches(355, 0, tolerance: 10), isTrue);
      expect(AngleMapper.matches(20, 0, tolerance: 10), isFalse);
    });
  });
}
