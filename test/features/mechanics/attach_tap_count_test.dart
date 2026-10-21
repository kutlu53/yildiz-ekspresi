import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/core/clock_time.dart';
import 'package:zaman_bekcisi/features/mechanics/attach_hands.dart';
import 'package:zaman_bekcisi/features/mechanics/count_minutes.dart';
import 'package:zaman_bekcisi/features/mechanics/tap_hand.dart';
import 'package:zaman_bekcisi/features/story/lines.dart';
import 'package:zaman_bekcisi/shared/widgets/draggable_clock.dart';

import 'fake_controller.dart';

void main() {
  group('AttachHandsMechanic', () {
    testWidgets('önce yelkovan bırakılırsa hata, akrep sonra yelkovan tamamlar',
        (tester) async {
      setScreen(tester);
      final c = FakeController();
      await tester.pumpWidget(wrap(AttachHandsMechanic(controller: c)));
      await tester.pump();

      expect(find.byType(Draggable<ClockHand>), findsNWidgets(2));
      final target = clockGeometry(tester).center;

      Future<void> dropPiece(ClockHand hand) async {
        final piece = find.byWidgetPredicate(
            (w) => w is Draggable<ClockHand> && w.data == hand);
        final from = tester.getCenter(piece);
        final g = await tester.startGesture(from);
        await tester.pump(const Duration(milliseconds: 100));
        await g.moveTo(target);
        await tester.pump(const Duration(milliseconds: 100));
        await g.up();
        await tester.pump(const Duration(milliseconds: 100));
      }

      await dropPiece(ClockHand.minute); // yelkovan önce
      expect(c.mistakes, 1);
      expect(c.spoken.last, Lines.s1WrongFirst.text);

      await dropPiece(ClockHand.hour);
      expect(c.spoken.last, Lines.s1AttachHourDone.text);
      expect(c.completed, 0);

      await dropPiece(ClockHand.minute);
      expect(c.spoken.last, Lines.s1AttachMinuteDone.text);
      expect(c.completed, 1);
    });
  });

  group('TapHandMechanic', () {
    testWidgets('akrebe dokununca doğru, yelkovana dokununca yanlış',
        (tester) async {
      setScreen(tester);
      final c = FakeController();
      await tester.pumpWidget(wrap(TapHandMechanic(
        controller: c,
        time: const ClockTime(3, 0),
        rounds: const [ClockHand.hour],
      )));
      await tester.pump();
      expect(c.spoken.last, Lines.s1TapHour.text);

      final rect = tester.getRect(find.byType(CustomPaint).last);
      final center = rect.center;
      final radius = rect.shortestSide / 2;

      // Yelkovan 12'de: yanlış.
      await tester.tapAt(pointAt(center, radius, 0, 0.75));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(c.mistakes, 1);
      expect(c.spoken.last, Lines.s1TapWrongHour.text);

      // Akrep 3'te: doğru.
      await tester.tapAt(pointAt(center, radius, 90, 0.45));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(c.completed, 1);
    });
  });

  group('CountMinutesMechanic', () {
    testWidgets('yelkovan adım adım bir tur dönünce tamamlanır', (tester) async {
      setScreen(tester);
      final c = FakeController();
      await tester.pumpWidget(wrap(CountMinutesMechanic(
        controller: c,
        start: const ClockTime(3, 0),
        step: 5,
        speakCounts: true,
        intro: Lines.s1Turn,
        done: Lines.s1TurnDone,
      )));
      await tester.pump();

      // Sıçrama kabul edilmez: 0'dan doğrudan 90°'ye.
      await dragHand(tester, fromAngle: 0, toAngle: 90, frac: 0.8, steps: 1);
      var clock = tester.widget<DraggableClock>(find.byType(DraggableClock));
      expect(clock.time, const ClockTime(3, 0));

      // Adım adım tam tur.
      await dragHand(tester, fromAngle: 0, toAngle: 360, frac: 0.8, steps: 36);
      clock = tester.widget<DraggableClock>(find.byType(DraggableClock));
      expect(clock.time, const ClockTime(4, 0));
      expect(c.spoken, contains('beş'));
      expect(c.spoken, contains('otuz'));
      expect(c.spoken.last, Lines.s1TurnDone.text);
      expect(c.completed, 1);
    });
  });
}
