import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/core/week.dart';
import 'package:zaman_bekcisi/features/mechanics/stone_path.dart';
import 'package:zaman_bekcisi/features/story/lines.dart';
import 'package:zaman_bekcisi/shared/widgets/pamuk.dart';

import 'fake_controller.dart';

void main() {
  Future<void> tapStone(WidgetTester tester, int day) async {
    await tester.tap(find.byKey(ValueKey('stone-$day')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('yürü: yalnız sıradaki taş kabul edilir, günler sayılır',
      (tester) async {
    setScreen(tester);
    final c = FakeController();
    await tester.pumpWidget(wrap(StonePathMechanic(
      controller: c,
      mode: StoneMode.walk,
      intro: Lines.s7StonesIntro,
      wrongLine: Lines.s7Wrong,
      done: Lines.s7StonesDone,
      rounds: const [
        StoneRound(start: Week.tuesday, steps: 4, prompt: 'Salı. Cumartesiye yürü.'),
      ],
    )));
    await tester.pump();
    expect(c.spoken, contains(Lines.s7StonesIntro.text));
    expect(c.spoken.last, 'Salı. Cumartesiye yürü.');
    expect(find.byType(Pamuk), findsOneWidget);

    // Sıçrama: Salı'dan Cuma'ya.
    await tapStone(tester, Week.friday);
    expect(c.mistakes, 1);
    expect(c.spoken.last, Lines.s7Wrong.text);

    // Taş taş: Çarşamba, Perşembe, Cuma, Cumartesi.
    for (final d in [Week.wednesday, Week.thursday, Week.friday]) {
      await tapStone(tester, d);
    }
    expect(c.spoken, contains('bir, Çarşamba.'));
    expect(c.spoken, contains('üç, Cuma.'));
    expect(c.completed, 0);

    await tapStone(tester, Week.saturday);
    await tester.pump(const Duration(milliseconds: 700));
    expect(c.spoken, contains('dört, Cumartesi.'));
    expect(c.spoken, contains('Çarşamba, Perşembe, Cuma, Cumartesi. dört gün sonra Cumartesi!'));
    expect(c.spoken.last, Lines.s7StonesDone.text);
    expect(c.completed, 1);
  });

  testWidgets('seç: yanlış taş ipucu, doğru taşa dokununca Pamuk zıplar; hafta sarar',
      (tester) async {
    setScreen(tester);
    final c = FakeController();
    await tester.pumpWidget(wrap(StonePathMechanic(
      controller: c,
      mode: StoneMode.pick,
      hintLine: Lines.s7HuntHint,
      wrongLine: Lines.s7Wrong,
      rounds: const [
        StoneRound(start: Week.saturday, steps: 2, prompt: 'Cumartesi. İki gün sonra?'),
      ],
    )));
    await tester.pump();

    await tapStone(tester, Week.tuesday);
    expect(c.mistakes, 1);
    expect(c.spoken.last, Lines.s7Wrong.text);
    await tapStone(tester, Week.sunday);
    expect(c.mistakes, 2);
    expect(c.spoken.last, Lines.s7HuntHint.text);

    await tapStone(tester, Week.monday); // Cumartesi + 2 = Pazartesi
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(c.spoken, contains('Pazar, Pazartesi. iki gün sonra Pazartesi!'));
    expect(c.spoken.last, Lines.great.text);
    expect(c.completed, 1);
  });
}
