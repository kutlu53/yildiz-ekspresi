import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/features/mechanics/place_cards.dart';
import 'package:zaman_bekcisi/features/story/lines.dart';

import 'fake_controller.dart';

void main() {
  const cards = [
    PlaceCard(id: 'wake', label: 'Uyanma', icon: Icons.alarm, slotId: '7'),
    PlaceCard(id: 'sleep', label: 'Uyku', icon: Icons.bedtime, slotId: '21'),
  ];

  List<PlaceSlot> slots() => [
        for (final (id, spoken) in [('7', 'sabah yedi'), ('21', 'akşam dokuz')])
          PlaceSlot(
            id: id,
            spoken: spoken,
            build: (context, filled, glow) => Container(
              key: ValueKey('slot-$id'),
              width: 80,
              height: 40,
              color: glow ? Colors.yellow : Colors.grey,
            ),
          ),
      ];

  Future<void> dragCardTo(WidgetTester tester, String cardId, String slotId) async {
    final card = find.byWidgetPredicate(
        (w) => w is Draggable<PlaceCard> && w.data?.id == cardId);
    final g = await tester.startGesture(tester.getCenter(card));
    await tester.pump(const Duration(milliseconds: 100));
    await g.moveTo(tester.getCenter(find.byKey(ValueKey('slot-$slotId'))));
    await tester.pump(const Duration(milliseconds: 100));
    await g.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('yanlış yuva kartı geri gönderir, doğru yuva kabul eder',
      (tester) async {
    setScreen(tester);
    final c = FakeController();
    PlaceSlot? last;
    await tester.pumpWidget(wrap(PlaceCardsMechanic(
      controller: c,
      intro: Lines.s6DayIntro,
      wrongLine: Lines.s6Wrong,
      done: Lines.s6DayDone,
      cards: cards,
      slots: slots(),
      prop: (l) {
        last = l;
        return const SizedBox(width: 10, height: 10);
      },
    )));
    await tester.pump();
    expect(c.spoken.last, Lines.s6DayIntro.text);
    expect(find.byType(Draggable<PlaceCard>), findsNWidgets(2));

    // Uyku kartını sabah yediye: yanlış.
    await dragCardTo(tester, 'sleep', '7');
    expect(c.mistakes, 1);
    expect(c.spoken, contains('Uyku')); // kaldırınca adı okunur
    expect(c.spoken, contains('sabah yedi, uyku?'));
    expect(c.spoken.last, Lines.s6Wrong.text);
    expect(find.byType(Draggable<PlaceCard>), findsNWidgets(2));
    expect(last, isNull);

    // Uyanma kartını sabah yediye: doğru.
    await dragCardTo(tester, 'wake', '7');
    expect(c.spoken, contains('sabah yedi: Uyanma'));
    expect(find.byType(Draggable<PlaceCard>), findsOneWidget);
    expect(last?.id, '7');
    expect(c.completed, 0);

    // Son kart doğru yere: sahne biter.
    await dragCardTo(tester, 'sleep', '21');
    expect(c.spoken.last, Lines.s6DayDone.text);
    expect(c.completed, 1);
  });

  testWidgets('ikinci yanlışta doğru yuva parlar', (tester) async {
    setScreen(tester);
    final c = FakeController();
    await tester.pumpWidget(wrap(PlaceCardsMechanic(
      controller: c,
      cards: cards,
      slots: slots(),
    )));
    await tester.pump();
    await dragCardTo(tester, 'sleep', '7');
    await dragCardTo(tester, 'sleep', '7');
    expect(c.mistakes, 2);
    final glowing = tester.widget<Container>(find.byKey(const ValueKey('slot-21')));
    expect(glowing.color, Colors.yellow);
  });
}
