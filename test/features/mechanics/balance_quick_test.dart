import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/core/clock_time.dart';
import 'package:zaman_bekcisi/features/mechanics/balance.dart';
import 'package:zaman_bekcisi/features/mechanics/quick_clock.dart';
import 'package:zaman_bekcisi/features/mechanics/read_clock.dart';
import 'package:zaman_bekcisi/features/story/lines.dart';
import 'package:zaman_bekcisi/features/story/stations/helpers.dart';

import 'fake_controller.dart';

void main() {
  group('BalanceMechanic', () {
    testWidgets('toplam söylenir, fazla gelince geri alınır, denk gelince dengelenir',
        (tester) async {
      setScreen(tester);
      final c = FakeController();
      await tester.pumpWidget(wrap(BalanceMechanic(
        controller: c,
        overLine: Lines.s9BalanceOver,
        done: Lines.s9BalanceDone,
        rounds: const [
          BalanceRound(
            leftLabel: '1 saat',
            leftSpoken: 'bir saat',
            target: 60,
            unitSpoken: 'dakika',
            prompt: 'Altmış dakika koy.',
            pool: [
              BalanceWeight(value: 30, label: '30 dk'),
              BalanceWeight(value: 30, label: '30 dk'),
              BalanceWeight(value: 10, label: '10 dk'),
            ],
          ),
        ],
      )));
      await tester.pump();
      expect(c.spoken.last, 'Altmış dakika koy.');

      Future<void> tapWeight(int i) async {
        await tester.tap(find.byKey(ValueKey('weight-$i')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
      }

      await tapWeight(0);
      expect(c.spoken.last, 'otuz dakika');
      await tapWeight(2);
      expect(c.spoken.last, 'kırk dakika');

      // 40 + 30 = 70: fazla, son ağırlık geri alınır.
      await tapWeight(1);
      expect(c.mistakes, 1);
      expect(c.spoken, contains(Lines.s9BalanceOver.text));
      expect(find.byKey(const ValueKey('weight-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('placed-2')), findsOneWidget);

      // 10'u geri al, 30 koy: 60.
      await tester.tap(find.byKey(const ValueKey('placed-2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(c.spoken.last, 'Geri aldım. otuz dakika.');
      await tapWeight(1);
      expect(c.spoken, contains('altmış dakika, bir saat. Dengelendi!'));
      expect(c.spoken.last, Lines.s9BalanceDone.text);
      expect(c.completed, 1);
    });
  });

  group('QuickClockMechanic', () {
    testWidgets('süre bitince doğru gösterilir ve devam edilir; sonunda doğru sayısı',
        (tester) async {
      setScreen(tester);
      final c = FakeController();
      await tester.pumpWidget(wrap(QuickClockMechanic(
        controller: c,
        perRound: const Duration(seconds: 2),
        lateLine: Lines.s9QuickLate,
        done: Lines.s9QuickDone,
        rounds: const [
          ReadClockRound(
            shown: ClockTime(7, 0),
            options: [ClockTime(7, 0), ClockTime(2, 0), ClockTime(9, 0)],
          ),
          ReadClockRound(
            shown: ClockTime(4, 20),
            options: [ClockTime(4, 5), ClockTime(4, 20), ClockTime(4, 40)],
          ),
        ],
      )));
      await tester.pump();

      // İlk tur: yanlış sonra doğru.
      await tester.tap(find.text('2:00'));
      await tester.pump();
      expect(c.mistakes, 1);
      await tester.tap(find.text('7:00'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(c.spoken, contains('saat yedi'));
      expect(find.text('4:20'), findsOneWidget);

      // İkinci tur: süre dolar.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      expect(c.mistakes, 2);
      expect(c.spoken, contains(Lines.s9QuickLate.text));
      expect(c.spoken, contains('dördü yirmi geçiyor'));
      expect(c.spoken, contains('bir doğru, iki saat.'));
      expect(c.completed, 1);
    });

    test('fiveMinuteRound: aynı saat, üç farklı 5\'lik dakika', () {
      final r = fiveMinuteRound(const ClockTime(4, 20), seed: 2);
      expect(r.options.length, 3);
      expect(r.options.map((o) => o.hour).toSet(), {4});
      expect(r.options.map((o) => o.minute).toSet().length, 3);
      expect(r.options.every((o) => o.minute % 5 == 0), isTrue);
      expect(r.options.any((o) => o.minute == 20), isTrue);
    });
  });
}
