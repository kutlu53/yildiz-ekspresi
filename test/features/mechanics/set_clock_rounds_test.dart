import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/core/clock_time.dart';
import 'package:zaman_bekcisi/features/mechanics/mechanic_frame.dart';
import 'package:zaman_bekcisi/features/mechanics/set_clock.dart';
import 'package:zaman_bekcisi/features/story/lines.dart';
import 'package:zaman_bekcisi/shared/widgets/draggable_clock.dart';

import 'fake_controller.dart';

/// Durak 5 pano sahnesi: tur bazlı dakika adımı (5'er → 1'er), tur başı
/// ek replik ve hedefe göre çizilen pano.
void main() {
  testWidgets('tur adımı mekaniği geçersiz kılar, pano hedefi gösterir',
      (tester) async {
    setScreen(tester);
    final c = FakeController();
    await tester.pumpWidget(wrap(SetClockMechanic(
      controller: c,
      draggable: const {ClockHand.hour, ClockHand.minute},
      minuteStep: 5,
      roundProp: (round, done) => DigitalBoard(text: round.target.digital12),
      rounds: const [
        SetClockRound(
          target: ClockTime(3, 25),
          start: ClockTime(3, 0),
          spokenPrompt: 'Üç, yirmi beş.',
        ),
        SetClockRound(
          target: ClockTime(7, 48),
          start: ClockTime(7, 45),
          minuteStep: 1,
          lead: Lines.s5BoardFine,
          spokenPrompt: 'Yedi, kırk sekiz.',
        ),
      ],
    )));
    await tester.pump();
    expect(find.text('3:25'), findsOneWidget);
    var clock = tester.widget<DraggableClock>(find.byType(DraggableClock));
    expect(clock.minuteStep, 5);

    // Yelkovanı 25'e (150°) bırak: ilk tur biter.
    await dragHand(tester, fromAngle: 0, toAngle: 150, frac: 0.8);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    expect(find.text('7:48'), findsOneWidget);
    expect(c.spoken, contains(Lines.s5BoardFine.text));
    expect(c.spoken.last, 'Yedi, kırk sekiz.');
    clock = tester.widget<DraggableClock>(find.byType(DraggableClock));
    expect(clock.minuteStep, 1);
    expect(clock.time, const ClockTime(7, 45));

    // Yelkovanı 45'ten 48'e (270° → 288°) ilerlet.
    await dragHand(tester, fromAngle: 270, toAngle: 288, frac: 0.8, steps: 3);
    await tester.pump(const Duration(milliseconds: 50));
    expect(c.completed, 1);
  });
}
