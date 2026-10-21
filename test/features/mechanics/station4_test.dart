import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/core/clock_time.dart';
import 'package:zaman_bekcisi/features/mechanics/count_minutes.dart';
import 'package:zaman_bekcisi/features/mechanics/set_clock.dart';
import 'package:zaman_bekcisi/features/story/lines.dart';
import 'package:zaman_bekcisi/features/story/props.dart';
import 'package:zaman_bekcisi/shared/widgets/draggable_clock.dart';

import 'fake_controller.dart';

/// Durak 4'ün mekanik kullanımları: fener nesnesi sayımla parlar, damla
/// saati sürükleme sırasında canlı sayar, 1'er dakika hassasiyeti çalışır.
void main() {
  testWidgets('Say: fener her adımda parlar, 60\'ta tam parlak', (tester) async {
    setScreen(tester);
    final c = FakeController();
    await tester.pumpWidget(wrap(CountMinutesMechanic(
      controller: c,
      start: const ClockTime(9, 0),
      step: 5,
      speakCounts: true,
      intro: Lines.s4Count,
      done: Lines.s4CountDone,
      prop: (elapsed, finished) =>
          LanternProp(lit: elapsed > 0 || finished, level: elapsed / 60),
    )));
    await tester.pump();

    var lantern = tester.widget<LanternProp>(find.byType(LanternProp));
    expect(lantern.lit, isFalse);

    await dragHand(tester, fromAngle: 0, toAngle: 30, frac: 0.8, steps: 3);
    lantern = tester.widget<LanternProp>(find.byType(LanternProp));
    expect(lantern.lit, isTrue);
    expect(lantern.level, closeTo(5 / 60, 0.001));
    expect(c.spoken.last, 'beş');

    await dragHand(tester, fromAngle: 30, toAngle: 360, frac: 0.8, steps: 33);
    lantern = tester.widget<LanternProp>(find.byType(LanternProp));
    expect(lantern.level, 1);
    expect(c.spoken.last, Lines.s4CountDone.text);
    expect(c.completed, 1);
  });

  testWidgets('Kur 5\'er: yardım merdiveni özel sayma ipucunu okur',
      (tester) async {
    setScreen(tester);
    final c = FakeController();
    await tester.pumpWidget(wrap(SetClockMechanic(
      controller: c,
      draggable: const {ClockHand.minute},
      minuteStep: 5,
      numeralsHint: Lines.s4SetHint,
      prop: (done, solved) => LanternProp(lit: done),
      rounds: const [
        SetClockRound(
          target: ClockTime(2, 20),
          start: ClockTime(2, 0),
          spokenPrompt: 'Yirmi dakika geçiyor.',
        ),
      ],
    )));
    await tester.pump();

    // İki yanlış bırakış: "henüz değil", sonra el ipucu; üçüncüde sayma ipucu.
    var angle = 0.0;
    for (final next in [60.0, 90.0, 60.0]) {
      await dragHand(tester, fromAngle: angle, toAngle: next, frac: 0.8);
      await tester.pump(const Duration(milliseconds: 50));
      angle = next;
    }
    expect(c.spoken.last, Lines.s4SetHint.text);
    expect(tester.widget<LanternProp>(find.byType(LanternProp)).lit, isFalse);

    await dragHand(tester, fromAngle: angle, toAngle: 120, frac: 0.8);
    await tester.pump(const Duration(milliseconds: 50));
    expect(c.completed, 1);
    expect(tester.widget<LanternProp>(find.byType(LanternProp)).lit, isTrue);
  });

  testWidgets('Damla saati: 1\'er dakika, sürüklerken damlalar sayılır',
      (tester) async {
    setScreen(tester);
    final c = FakeController();
    await tester.pumpWidget(wrap(SetClockMechanic(
      controller: c,
      draggable: const {ClockHand.minute},
      minuteStep: 1,
      timeProp: (time, start, done) => DripClockProp(
        drops: (time.minutesSinceMidnight - start.minutesSinceMidnight + 720) %
            720,
        done: done,
      ),
      rounds: const [
        SetClockRound(
          target: ClockTime(4, 3),
          start: ClockTime(4, 0),
          spokenPrompt: 'Üç dakika daha.',
        ),
      ],
    )));
    await tester.pump();
    expect(tester.widget<DripClockProp>(find.byType(DripClockProp)).drops, 0);

    // Yelkovanı 3 dakika (18°) ilerlet ve bırak.
    await dragHand(tester, fromAngle: 0, toAngle: 18, frac: 0.8, steps: 3);
    await tester.pump(const Duration(milliseconds: 50));
    final clock = tester.widget<DraggableClock>(find.byType(DraggableClock));
    expect(clock.time, const ClockTime(4, 3));
    final drip = tester.widget<DripClockProp>(find.byType(DripClockProp));
    expect(drip.drops, 3);
    expect(drip.done, isTrue);
    expect(c.completed, 1);
  });
}
