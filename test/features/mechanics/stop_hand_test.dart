import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/core/clock_time.dart';
import 'package:zaman_bekcisi/features/mechanics/stop_hand.dart';
import 'package:zaman_bekcisi/features/story/lines.dart';
import 'package:zaman_bekcisi/shared/widgets/draggable_clock.dart';

import 'fake_controller.dart';

void main() {
  testWidgets('erken dokunuş uyarır, zamanında dokunuş zili çalar',
      (tester) async {
    setScreen(tester);
    final c = FakeController();
    await tester.pumpWidget(wrap(StopHandMechanic(
      controller: c,
      degreesPerSecond: 60,
      rounds: const [
        StopHandRound(target: ClockTime(4, 15), prompt: Lines.s3BellIntro),
      ],
    )));
    await tester.pump();
    // Yelkovan hedefin 120° gerisinden başlar (90 - 120 = 330°).
    var clock = tester.widget<DraggableClock>(find.byType(DraggableClock));
    expect(clock.time.minuteHandAngle, 330);

    // 0,5 sn sonra 0°: erken.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byType(DraggableClock));
    await tester.pump();
    expect(c.mistakes, 1);
    expect(c.spoken.last, Lines.s3BellEarly.text);

    // Kaçırınca yelkovan hedefin 100° gerisine alınır: 90 - 100 = 350°.
    clock = tester.widget<DraggableClock>(find.byType(DraggableClock));
    expect(clock.time.minuteHandAngle, closeTo(350, 3));

    // 60°/s ile ~1,65 sn sonra 89°: tolerans içinde; bu kez zile dokunulur.
    await tester.pump(const Duration(milliseconds: 1650));
    await tester.tap(find.byKey(const ValueKey('bell')));
    await tester.pump();
    expect(c.completed, 1);
    expect(c.spoken.last, Lines.s3BellDone.text);
    clock = tester.widget<DraggableClock>(find.byType(DraggableClock));
    expect(clock.time, const ClockTime(4, 15));
  });
}
