import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/core/clock_time.dart';
import 'package:zaman_bekcisi/features/mechanics/set_clock.dart';
import 'package:zaman_bekcisi/features/story/lines.dart';
import 'package:zaman_bekcisi/features/story/props.dart';
import 'package:zaman_bekcisi/shared/widgets/draggable_clock.dart';

import 'fake_controller.dart';

/// Durak 10 kilit sahnesi: üç saat kurulur ama dişli yalnız sonuncuda döner;
/// ara turlarda kapı kıpırdamaz ve "dişli döndü" denmez.
void main() {
  testWidgets('dişli ve kapı yalnız son turda hareket eder', (tester) async {
    setScreen(tester);
    final c = FakeController();
    await tester.pumpWidget(wrap(SetClockMechanic(
      controller: c,
      successLine: Lines.wellDone,
      draggable: const {ClockHand.hour},
      prop: (done, solved) =>
          LockProp(gears: 0, total: 5, turning: done && solved == 2),
      rounds: const [
        SetClockRound(
          target: ClockTime(5, 0),
          start: ClockTime(12, 0),
          spokenPrompt: 'Saat beş.',
        ),
        SetClockRound(
          target: ClockTime(9, 0),
          start: ClockTime(12, 0),
          spokenPrompt: 'Saat dokuz.',
          successLine: Lines.s10Gear,
        ),
      ],
    )));
    await tester.pump();

    // İlk tur: akrep 5'e. Kapı kapalı kalır, genel kutlama okunur.
    await dragHand(tester, fromAngle: 0, toAngle: 150, frac: 0.4);
    var lock = tester.widget<LockProp>(find.byType(LockProp));
    expect(lock.turning, isFalse);
    expect(c.spoken, contains(Lines.wellDone.text));
    expect(c.spoken, isNot(contains(Lines.s10Gear.text)));
    await tester.pump(const Duration(milliseconds: 700));

    // Son tur: akrep 9'a. Dişli döner, "dişli döndü" okunur.
    await dragHand(tester, fromAngle: 0, toAngle: 270, frac: 0.4);
    lock = tester.widget<LockProp>(find.byType(LockProp));
    expect(lock.turning, isTrue);
    expect(c.spoken.last, Lines.s10Gear.text);
    expect(c.completed, 1);
  });
}
