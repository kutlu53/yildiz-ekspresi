import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/core/week.dart';
import 'package:zaman_bekcisi/features/mechanics/calendar.dart';
import 'package:zaman_bekcisi/features/mechanics/choose_option.dart';
import 'package:zaman_bekcisi/features/story/lines.dart';
import 'package:zaman_bekcisi/shared/widgets/knuckle_hills.dart';

import 'fake_controller.dart';

void main() {
  group('ChooseOptionMechanic', () {
    testWidgets('yanlış tabela ipucu, doğru tabela nesneyi açar ve tamamlar',
        (tester) async {
      setScreen(tester);
      final c = FakeController();
      await tester.pumpWidget(wrap(ChooseOptionMechanic(
        controller: c,
        intro: Lines.s8HousesIntro,
        hintLine: Lines.s8HousesHint,
        wrongLine: Lines.s8Wrong,
        done: Lines.s8HousesDone,
        prop: (round, index, done) => KnuckleHills(highlight: 1, reveal: done),
        rounds: const [
          ChoiceRound(
            prompt: 'Şubat kaç gün?',
            options: [
              ChoiceOption(label: '31', spoken: 'otuz bir gün'),
              ChoiceOption(label: '28', spoken: 'yirmi sekiz gün'),
            ],
            correct: 1,
            successSpoken: 'Şubat en küçük ev: yirmi sekiz gün.',
          ),
        ],
      )));
      await tester.pump();
      expect(c.spoken.last, 'Şubat kaç gün?');

      await tester.tap(find.byKey(const ValueKey('choice-0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(c.spoken, contains('otuz bir gün'));
      expect(c.mistakes, 1);
      expect(c.spoken.last, Lines.s8Wrong.text);
      expect(tester.widget<KnuckleHills>(find.byType(KnuckleHills)).reveal, isFalse);

      await tester.tap(find.byKey(const ValueKey('choice-1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(c.spoken, contains('Şubat en küçük ev: yirmi sekiz gün.'));
      expect(c.spoken.last, Lines.s8HousesDone.text);
      expect(c.completed, 1);
      expect(tester.widget<KnuckleHills>(find.byType(KnuckleHills)).reveal, isTrue);
    });
  });

  group('CalendarMechanic', () {
    testWidgets('yanlış güne dokununca ipucu, doğru güne dokununca tarih ve gün söylenir',
        (tester) async {
      setScreen(tester);
      final c = FakeController();
      await tester.pumpWidget(wrap(CalendarMechanic(
        controller: c,
        hintLine: Lines.s8CalendarHint,
        wrongLine: Lines.s8Wrong,
        rounds: const [
          CalendarRound(
            month: 2,
            firstWeekday: Week.sunday,
            answerDay: 14,
            prompt: 'On dört Mart hangi gün?',
          ),
          CalendarRound(
            month: 1,
            firstWeekday: Week.monday,
            answerDay: 28,
            prompt: 'Şubat\'ın son günü?',
          ),
        ],
      )));
      await tester.pump();
      expect(find.text('Mart'), findsOneWidget);
      expect(find.text('31'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('cal-12')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(c.spoken, contains('on iki'));
      expect(c.mistakes, 1);
      await tester.tap(find.byKey(const ValueKey('cal-13')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(c.mistakes, 2);
      expect(c.spoken.last, Lines.s8CalendarHint.text);

      await tester.tap(find.byKey(const ValueKey('cal-14')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();
      expect(c.spoken, contains('on dört Mart, Cumartesi!'));
      expect(c.completed, 0);

      // İkinci tur: Şubat sayfası, 29 yok.
      expect(find.text('Şubat'), findsOneWidget);
      expect(find.byKey(const ValueKey('cal-29')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('cal-28')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(c.spoken, contains('yirmi sekiz Şubat, Pazar!'));
      expect(c.completed, 1);
    });
  });
}
