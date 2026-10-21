import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/core/clock_time.dart';
import 'package:zaman_bekcisi/features/mechanics/read_clock.dart';
import 'package:zaman_bekcisi/features/mechanics/set_clock.dart';
import 'package:zaman_bekcisi/features/story/lines.dart';
import 'package:zaman_bekcisi/features/story/stages.dart';
import 'package:zaman_bekcisi/shared/audio/sfx.dart';
import 'package:zaman_bekcisi/shared/widgets/draggable_clock.dart';
import 'package:zaman_bekcisi/shared/widgets/train_run.dart';

import '../mechanics/fake_controller.dart';

void main() {
  setUp(() {
    Sfx.instance.enabled = true;
    Sfx.instance.log.clear();
  });

  testWidgets('kol: saat yanlışken takılı, doğruyken çekilince tren kalkar',
      (tester) async {
    setScreen(tester);
    final c = FakeController();
    var departed = false;
    await tester.pumpWidget(wrap(SetClockMechanic(
      controller: c,
      draggable: const {ClockHand.hour},
      successLine: Lines.s2LeverDone,
      afterSuccess: () async {
        while (!departed) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      },
      stage: (context, clock, view) => CabStage(
        clock: clock,
        boardText: '8',
        armed: view.done,
        onStuck: () => c.say(Lines.s2LeverStuck),
        onPulled: () => c.say(Lines.s2Pulled),
        onDeparted: () => departed = true,
      ),
      rounds: const [
        SetClockRound(
          target: ClockTime(8, 0),
          start: ClockTime(12, 0),
          spokenPrompt: 'Saat sekiz.',
        ),
      ],
    )));
    await tester.pump();

    await tester.drag(find.byKey(const ValueKey('big-lever')), const Offset(0, 160));
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.spoken.last, Lines.s2LeverStuck.text);
    expect(c.completed, 0);

    await dragHand(tester, fromAngle: 0, toAngle: 240, frac: 0.45);
    await tester.pump(const Duration(milliseconds: 100));
    expect(c.spoken.last, Lines.s2LeverDone.text);
    expect(c.completed, 0, reason: 'kol çekilmeden sahne bitmez');

    await tester.drag(find.byKey(const ValueKey('big-lever')), const Offset(0, 160));
    await tester.pump();
    expect(c.spoken.last, Lines.s2Pulled.text);
    expect(Sfx.instance.log, contains(SfxId.whistle));
    expect(find.byType(TrainRun), findsOneWidget);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(departed, isTrue);
    expect(c.completed, 1);
  });

  testWidgets('vagonlar: yanlış vagon ipucu, doğru vagon tamamlar', (tester) async {
    setScreen(tester);
    final c = FakeController();
    await tester.pumpWidget(wrap(ReadClockMechanic(
      controller: c,
      hintLine: Lines.s2ReadHint,
      stage: (context, clock, options, round) =>
          WagonSigns(clock: clock, options: options),
      rounds: const [
        ReadClockRound(
          shown: ClockTime(3, 0),
          options: [ClockTime(6, 0), ClockTime(3, 0), ClockTime(9, 0)],
        ),
      ],
    )));
    await tester.pump();
    expect(find.byKey(const ValueKey('wagon-3:00')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('wagon-6:00')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(c.mistakes, 1);
    expect(c.spoken.last, Lines.s2ReadHint.text);

    await tester.tap(find.byKey(const ValueKey('wagon-3:00')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(c.completed, 1);
  });

  testWidgets('kapı: doğru kurulunca açılır, tren tünele girince biter',
      (tester) async {
    setScreen(tester);
    final c = FakeController();
    var entered = false;
    await tester.pumpWidget(wrap(SetClockMechanic(
      controller: c,
      draggable: const {ClockHand.hour},
      afterSuccess: () async {
        while (!entered) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      },
      stage: (context, clock, view) =>
          GateStage(clock: clock, open: view.done, onEntered: () => entered = true),
      rounds: const [
        SetClockRound(
          target: ClockTime(3, 0),
          start: ClockTime(12, 0),
          spokenPrompt: 'Saat üç.',
        ),
      ],
    )));
    await tester.pump();
    await dragHand(tester, fromAngle: 0, toAngle: 90, frac: 0.45);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(entered, isTrue);
    expect(c.completed, 1);
    expect(tester.takeException(), isNull);
  });
}
