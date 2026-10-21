import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/features/story/models.dart';
import 'package:zaman_bekcisi/shared/widgets/day_window.dart';
import 'package:zaman_bekcisi/shared/widgets/knuckle_hills.dart';
import 'package:zaman_bekcisi/shared/widgets/season_window.dart';
import 'package:zaman_bekcisi/shared/widgets/scenery_view.dart';

void main() {
  testWidgets('tünel dekoru ve fener yuvası hatasız çizilir', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: SceneryView(
        scenery: Scenery.tunnel,
        season: 0.9,
        moving: true,
        child: Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: ClockFrame(
              style: ClockFrameStyle.lantern,
              child: SizedBox.expand(),
            ),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SceneryView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('kubbeli istasyon dekoru ve altın yuva hatasız çizilir',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: SceneryView(
        scenery: Scenery.hall,
        season: 0.45,
        child: Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: ClockFrame(
              style: ClockFrameStyle.gold,
              child: SizedBox.expand(),
            ),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });

  testWidgets('mevsim vadisi, yumruk tepeleri ve mevsim penceresi hatasız çizilir',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: SceneryView(
        scenery: Scenery.valley,
        season: 0.8,
        moving: true,
        child: Column(
          children: [
            SizedBox(width: 600, child: KnuckleHills(highlight: 1, reveal: true)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SeasonWindow(season: null, width: 120, height: 70),
                SeasonWindow(season: 0, width: 120, height: 70),
                SeasonWindow(season: 1, width: 120, height: 70),
                SeasonWindow(season: 2, width: 120, height: 70),
                SeasonWindow(season: 3, width: 120, height: 70),
              ],
            ),
          ],
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });

  testWidgets('kar dağı eteği dekoru ve buz yuvası hatasız çizilir',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: SceneryView(
        scenery: Scenery.snowfield,
        season: 0.9,
        moving: true,
        child: Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: ClockFrame(style: ClockFrameStyle.ice, child: SizedBox.expand()),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });

  testWidgets('zirve ve yuva dekorları hatasız çizilir', (tester) async {
    for (final s in [Scenery.summit, Scenery.den]) {
      await tester.pumpWidget(MaterialApp(
        home: SceneryView(scenery: s, season: 1, moving: false),
      ));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('pazar kasabası dekoru hatasız çizilir', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: SceneryView(scenery: Scenery.market, season: 0.7, moving: true),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });

  testWidgets('yataklı vagon dekoru ve gün penceresi hatasız çizilir',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: SceneryView(
        scenery: Scenery.cabin,
        season: 0.8,
        moving: true,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DayWindow(hour: 3),
              DayWindow(hour: 7.5),
              DayWindow(hour: 12),
              DayWindow(hour: 18.5),
              DayWindow(hour: 22, highlighted: true),
            ],
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });
}
