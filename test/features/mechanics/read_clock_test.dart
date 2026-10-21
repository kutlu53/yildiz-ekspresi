import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/core/clock_time.dart';
import 'package:zaman_bekcisi/features/mechanics/read_clock.dart';
import 'package:zaman_bekcisi/features/story/lines.dart';

import 'fake_controller.dart';

void main() {
  testWidgets('yanlış kart sallanır ve ipucu verir, doğru kart tamamlar',
      (tester) async {
    setScreen(tester);
    final c = FakeController();
    await tester.pumpWidget(wrap(ReadClockMechanic(
      controller: c,
      rounds: const [
        ReadClockRound(
          shown: ClockTime(3, 0),
          options: [ClockTime(3, 0), ClockTime(6, 0), ClockTime(9, 0)],
        ),
      ],
    )));
    await tester.pump();

    await tester.tap(find.text('6:00'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(c.mistakes, 1);
    expect(c.spoken, contains('saat altı'));
    expect(c.spoken.last, Lines.hintHour.text);

    await tester.tap(find.text('3:00'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(c.completed, 1);
    expect(c.spoken, contains('saat üç'));
  });

  testWidgets('aynı saatin buçuk/çeyrek seçenekleri', (tester) async {
    setScreen(tester);
    final c = FakeController();
    await tester.pumpWidget(wrap(ReadClockMechanic(
      controller: c,
      rounds: const [
        ReadClockRound(
          shown: ClockTime(5, 30),
          options: [ClockTime(5, 0), ClockTime(5, 30), ClockTime(5, 15)],
        ),
      ],
    )));
    await tester.pump();
    await tester.tap(find.text('5:30'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(c.completed, 1);
    expect(c.spoken, contains('beş buçuk'));
  });
}
