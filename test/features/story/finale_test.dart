import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/features/story/finale.dart';
import 'package:zaman_bekcisi/features/story/lines.dart';
import 'package:zaman_bekcisi/features/story/models.dart';
import 'package:zaman_bekcisi/features/story/props.dart';
import 'package:zaman_bekcisi/features/story/stations/stations.dart';

void main() {
  test('final çekimleri: eşyalar rafta, tren Pamuk\'suz döner, jenerik sonda', () {
    final ids = StationRegistry.stations.map((s) => s.reward.id).toList();
    final shots = finalShots([...ids, 'unknown']);
    expect(shots.first.line, Lines.finalDoor);
    expect(shots.first.scenery, Scenery.den);
    final withItems = shots.where((s) => s.items.isNotEmpty).toList();
    expect(withItems, isNotEmpty);
    expect(withItems.first.items.length, ids.length); // bilinmeyen eşya atlanır
    expect(withItems.first.items.map((i) => i.id), contains('scarf'));
    final ride = shots.firstWhere((s) => s.trainMoving);
    expect(ride.showPamuk, isFalse);
    expect(shots.last.credits, isTrue);
    expect(shots.last.line, Lines.finalCredits);
  });

  testWidgets('kilit: dönen dişliler altın, kapı dişli sayısınca aralanır',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: LockProp(gears: 2, total: 5, turning: true))),
    ));
    await tester.pump(const Duration(seconds: 1));
    final icons = tester
        .widgetList<Icon>(find.byIcon(Icons.settings))
        .map((i) => i.color)
        .toList();
    expect(icons.length, 5);
    expect(icons.take(3).every((c) => c == const Color(0xFFFFB300)), isTrue);
    expect(icons.skip(3).every((c) => c == const Color(0xFF78909C)), isTrue);
    expect(tester.takeException(), isNull);
  });
}
