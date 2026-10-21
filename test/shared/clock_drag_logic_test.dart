import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/core/clock_time.dart';
import 'package:zaman_bekcisi/shared/widgets/clock_drag_logic.dart';

void main() {
  const both = {ClockHand.hour, ClockHand.minute};

  group('pickHand', () {
    test('tek sürüklenebilir el varsa o seçilir', () {
      expect(
        ClockDragLogic.pickHand(
          time: const ClockTime(3, 0),
          touchAngle: 200,
          radiusFraction: 0.9,
          draggable: {ClockHand.hour},
        ),
        ClockHand.hour,
      );
    });

    test('yakın olan el seçilir', () {
      const t = ClockTime(3, 0); // akrep 90, yelkovan 0
      expect(
        ClockDragLogic.pickHand(
            time: t, touchAngle: 85, radiusFraction: 0.8, draggable: both),
        ClockHand.hour,
      );
      expect(
        ClockDragLogic.pickHand(
            time: t, touchAngle: 350, radiusFraction: 0.8, draggable: both),
        ClockHand.minute,
      );
    });

    test('eller üst üsteyken merkeze yakın dokunuş akrep, uzak yelkovan', () {
      const t = ClockTime(0, 0);
      expect(
        ClockDragLogic.pickHand(
            time: t, touchAngle: 3, radiusFraction: 0.3, draggable: both),
        ClockHand.hour,
      );
      expect(
        ClockDragLogic.pickHand(
            time: t, touchAngle: 3, radiusFraction: 0.9, draggable: both),
        ClockHand.minute,
      );
    });

    test('ikisi de uzaksa daha yakın olan', () {
      const t = ClockTime(3, 0);
      expect(
        ClockDragLogic.pickHand(
            time: t, touchAngle: 150, radiusFraction: 0.8, draggable: both),
        ClockHand.hour,
      );
    });
  });

  group('dragMinute', () {
    test('adım 1, akrep bağlı', () {
      final t = ClockDragLogic.dragMinute(const ClockTime(3, 0), 93);
      expect(t, const ClockTime(3, 16));
    });

    test('adım 5 oturtma', () {
      final t = ClockDragLogic.dragMinute(const ClockTime(3, 0), 93,
          minuteStep: 5);
      expect(t, const ClockTime(3, 15));
    });

    test('12 geçilince akrep ilerler', () {
      final t = ClockDragLogic.dragMinute(const ClockTime(3, 55), 10);
      expect(t, const ClockTime(4, 2));
    });

    test('12 geriye geçilince akrep geriler', () {
      final t = ClockDragLogic.dragMinute(const ClockTime(4, 3), 350);
      expect(t, const ClockTime(3, 58));
    });

    test('gün sınırı: 23:58 -> 00:02', () {
      final t = ClockDragLogic.dragMinute(const ClockTime(23, 58), 12);
      expect(t, const ClockTime(0, 2));
    });

    test('bağlantı kapalıysa akrep değişmez', () {
      final t = ClockDragLogic.dragMinute(const ClockTime(3, 55), 10,
          linkHours: false);
      expect(t, const ClockTime(3, 2));
    });
  });

  group('dragHour', () {
    test('dakika 0 iken en yakın saate oturur', () {
      expect(ClockDragLogic.dragHour(const ClockTime(3, 0), 236),
          const ClockTime(8, 0));
      expect(ClockDragLogic.dragHour(const ClockTime(3, 0), 5),
          const ClockTime(0, 0));
    });

    test('dakika 30 iken ofset korunur (105° -> 3:30)', () {
      expect(ClockDragLogic.dragHour(const ClockTime(5, 30), 105),
          const ClockTime(3, 30));
      expect(ClockDragLogic.dragHour(const ClockTime(5, 30), 95),
          const ClockTime(3, 30));
    });

    test('öğleden sonra korunur', () {
      expect(ClockDragLogic.dragHour(const ClockTime(15, 0), 180),
          const ClockTime(18, 0));
    });
  });
}
