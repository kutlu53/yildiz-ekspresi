import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/core/clock_time.dart';
import 'package:zaman_bekcisi/features/mechanics/turn_day.dart';
import 'package:zaman_bekcisi/features/story/lines.dart';
import 'package:zaman_bekcisi/shared/widgets/day_window.dart';
import 'package:zaman_bekcisi/shared/widgets/draggable_clock.dart';

import 'fake_controller.dart';

void main() {
  testWidgets('akrep iki tur dönünce 24 saat; 12\'de öğlen repliği, pencere ilerler',
      (tester) async {
    setScreen(tester);
    final c = FakeController();
    await tester.pumpWidget(wrap(TurnDayMechanic(
      controller: c,
      startHour: 6,
      intro: Lines.s6WindowIntro,
      done: Lines.s6WindowDone,
      milestones: const {12: Lines.s6Noon},
      prop: (hour, elapsed) => DayWindow(hour: hour.toDouble()),
    )));
    await tester.pump();
    expect(c.spoken.last, Lines.s6WindowIntro.text);
    expect(tester.widget<DayWindow>(find.byType(DayWindow)).hour, 6);

    // Sıçrama kabul edilmez: 6'dan doğrudan 9'a.
    await dragHand(tester, fromAngle: 180, toAngle: 270, frac: 0.45, steps: 1);
    var clock = tester.widget<DraggableClock>(find.byType(DraggableClock));
    expect(clock.time, const ClockTime(6, 0));

    // İlk tur: 6 → 18.
    await dragHand(tester, fromAngle: 180, toAngle: 540, frac: 0.45, steps: 24);
    clock = tester.widget<DraggableClock>(find.byType(DraggableClock));
    expect(clock.time, const ClockTime(18, 0));
    expect(c.spoken, contains('bir'));
    expect(c.spoken, contains(Lines.s6Noon.text));
    expect(tester.widget<DayWindow>(find.byType(DayWindow)).hour, 18);
    expect(c.completed, 0);

    // İkinci tur: 18 → 6 (ertesi sabah).
    await dragHand(tester, fromAngle: 180, toAngle: 540, frac: 0.45, steps: 24);
    clock = tester.widget<DraggableClock>(find.byType(DraggableClock));
    expect(clock.time, const ClockTime(6, 0));
    expect(c.spoken.last, Lines.s6WindowDone.text);
    expect(c.completed, 1);
  });

  test('DayWindow: gece karanlık, öğlen aydınlık', () {
    expect(DayWindowPainter.darkness(12), 0);
    expect(DayWindowPainter.darkness(0), 1);
    expect(DayWindowPainter.darkness(23), 1);
    expect(DayWindowPainter.darkness(18.5), closeTo(0.5, 0.001));
    final (noonTop, _) = DayWindowPainter.skyColors(12);
    final (nightTop, _) = DayWindowPainter.skyColors(2);
    expect(noonTop.computeLuminance(), greaterThan(nightTop.computeLuminance()));
  });
}
