import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/core/clock_time.dart';
import 'package:zaman_bekcisi/features/mechanics/pick_clock.dart';
import 'package:zaman_bekcisi/features/story/lines.dart';
import 'package:zaman_bekcisi/features/story/props.dart';
import 'package:zaman_bekcisi/features/story/stations/helpers.dart';
import 'package:zaman_bekcisi/shared/widgets/draggable_clock.dart';

import 'fake_controller.dart';

void main() {
  testWidgets('yanlış saate dokununca ipucu, doğru saate dokununca tamamlanır',
      (tester) async {
    setScreen(tester);
    final c = FakeController();
    await tester.pumpWidget(wrap(PickClockMechanic(
      controller: c,
      intro: Lines.s5PlatformIntro,
      hintLine: Lines.s5PlatformHint,
      successLine: Lines.s5PlatformDone,
      prop: (round) => TicketProp(text: round.target.digital12),
      rounds: const [
        PickClockRound(
          target: ClockTime(3, 25),
          options: [ClockTime(5, 15), ClockTime(3, 25), ClockTime(3, 45)],
        ),
      ],
    )));
    await tester.pump();
    expect(c.spoken.last, Lines.s5PlatformIntro.text);
    expect(find.text('3:25'), findsOneWidget); // bilet
    expect(find.byType(DraggableClock), findsNWidgets(3));

    // Yanlış: 5:15 (akrep-yelkovan yer değiştirmiş).
    await tester.tap(find.byType(DraggableClock).at(0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(c.spoken, contains('beş on beş'));
    expect(c.mistakes, 1);
    expect(c.spoken.last, Lines.s5PlatformHint.text);
    expect(c.completed, 0);
    final glowing = tester
        .widgetList<DraggableClock>(find.byType(DraggableClock))
        .every((w) => w.glowHands.contains(ClockHand.hour));
    expect(glowing, isTrue);

    // Doğru: 3:25.
    await tester.tap(find.byType(DraggableClock).at(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(c.spoken, contains('üç yirmi beş'));
    expect(c.spoken.last, Lines.s5PlatformDone.text);
    expect(c.completed, 1);
  });

  testWidgets('üç yanlıştan sonra doğru saat vurgulanır, diğerleri solar',
      (tester) async {
    setScreen(tester);
    final c = FakeController();
    await tester.pumpWidget(wrap(PickClockMechanic(
      controller: c,
      rounds: const [
        PickClockRound(
          target: ClockTime(9, 10),
          options: [ClockTime(9, 10), ClockTime(2, 45), ClockTime(9, 40)],
        ),
      ],
    )));
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byType(DraggableClock).at(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(c.mistakes, 3);
    expect(c.spoken.last, Lines.showYou.text);
    final opacities = tester
        .widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity))
        .map((w) => w.opacity)
        .toList();
    expect(opacities, [1, 0.4, 0.4]);
  });

  test('digitalRound: hedef dâhil üç farklı seçenek, çeldiriciler karıştırıcı',
      () {
    for (final t in const [ClockTime(3, 25), ClockTime(7, 48), ClockTime(12, 0)]) {
      final r = digitalRound(t, seed: 3);
      expect(r.options.length, 3);
      expect(r.options.where((o) => o.sameOnDial(t)).length, 1);
      for (var i = 0; i < 3; i++) {
        for (var j = i + 1; j < 3; j++) {
          expect(r.options[i].sameOnDial(r.options[j]), isFalse);
        }
      }
    }
    final r = digitalRound(const ClockTime(3, 25), seed: 1);
    expect(r.options.any((o) => o.sameOnDial(const ClockTime(5, 15))), isTrue,
        reason: 'akrep-yelkovan yer değiştirmiş çeldirici');
  });
}
