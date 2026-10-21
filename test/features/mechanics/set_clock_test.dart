import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/core/clock_time.dart';
import 'package:zaman_bekcisi/features/mechanics/set_clock.dart';
import 'package:zaman_bekcisi/features/story/lines.dart';
import 'package:zaman_bekcisi/shared/widgets/draggable_clock.dart';

import 'fake_controller.dart';

void main() {
  testWidgets('yanlış bırakışta önce "henüz değil", sonra yardım; doğru bırakış tamamlar',
      (tester) async {
    setScreen(tester);
    final c = FakeController();
    await tester.pumpWidget(wrap(SetClockMechanic(
      controller: c,
      intro: Lines.s2Lever,
      draggable: const {ClockHand.hour},
      rounds: const [
        SetClockRound(
          target: ClockTime(8, 0),
          start: ClockTime(12, 0),
          spokenPrompt: 'Saat sekiz.',
        ),
      ],
    )));
    await tester.pump();
    expect(c.spoken, contains(Lines.s2Lever.text));
    expect(c.spoken, contains('Saat sekiz.'));

    // Akrebi 5'e bırak: ilk yanlış bırakış yumuşak, hata sayılmaz.
    await dragHand(tester, fromAngle: 0, toAngle: 150, frac: 0.45);
    await tester.pump(const Duration(milliseconds: 50));
    expect(c.mistakes, 0);
    expect(c.spoken.last, Lines.notYet.text);

    // Yine yanlış: artık yardım merdiveni.
    await dragHand(tester, fromAngle: 150, toAngle: 180, frac: 0.45);
    await tester.pump(const Duration(milliseconds: 50));
    expect(c.mistakes, 1);
    expect(c.spoken.last, Lines.hintHour.text);
    expect(c.completed, 0);

    // Akrebi 8'e bırak (240°).
    await dragHand(tester, fromAngle: 180, toAngle: 240, frac: 0.45);
    await tester.pump(const Duration(milliseconds: 50));
    expect(c.completed, 1);
    expect(c.spoken.last, Lines.wellDone.text);
  });

  testWidgets('üç hatadan sonra hayalet hedef gösterilir', (tester) async {
    setScreen(tester);
    final c = FakeController();
    await tester.pumpWidget(wrap(SetClockMechanic(
      controller: c,
      draggable: const {ClockHand.minute},
      minuteStep: 15,
      rounds: const [
        SetClockRound(
          target: ClockTime(3, 30),
          start: ClockTime(3, 0),
          spokenPrompt: 'Üç buçuk.',
        ),
      ],
    )));
    await tester.pump();
    var angle = 0.0;
    for (final next in [90.0, 270.0, 90.0, 270.0]) {
      await dragHand(tester, fromAngle: angle, toAngle: next, frac: 0.8);
      await tester.pump(const Duration(milliseconds: 50));
      angle = next;
    }
    expect(c.mistakes, 3);
    expect(c.spoken.last, Lines.showYou.text);
    final clock = tester.widget<DraggableClock>(find.byType(DraggableClock));
    expect(clock.ghostTime, const ClockTime(3, 30));
    expect(clock.glowNumerals, isTrue);
  });

  testWidgets('yelkovan sürüklenince akrep iki sayı arasına kayar',
      (tester) async {
    setScreen(tester);
    final c = FakeController();
    await tester.pumpWidget(wrap(SetClockMechanic(
      controller: c,
      draggable: const {ClockHand.minute},
      minuteStep: 15,
      rounds: const [
        SetClockRound(
          target: ClockTime(3, 30),
          start: ClockTime(3, 0),
          spokenPrompt: 'Üç buçuk.',
        ),
      ],
    )));
    await tester.pump();
    await dragHand(tester, fromAngle: 0, toAngle: 180, frac: 0.8);
    await tester.pump(const Duration(milliseconds: 50));
    final clock = tester.widget<DraggableClock>(find.byType(DraggableClock));
    expect(clock.time, const ClockTime(3, 30));
    expect(clock.time.hourHandAngle, 105);
    expect(c.completed, 1);
  });
}
