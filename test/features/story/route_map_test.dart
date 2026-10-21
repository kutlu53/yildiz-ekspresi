import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zaman_bekcisi/features/story/models.dart';
import 'package:zaman_bekcisi/features/story/progress_store.dart';
import 'package:zaman_bekcisi/features/story/stations/stations.dart';
import 'package:zaman_bekcisi/features/story/story_flow.dart';
import 'package:zaman_bekcisi/shared/audio/speech.dart';
import 'package:zaman_bekcisi/shared/widgets/route_map.dart';

void main() {
  testWidgets('harita: açık duraklar dokunulur, kilitliler dokunulmaz, ekler bitince',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Station? opened;
    var quick = 0;
    Widget build({required bool finished}) => MaterialApp(
          home: Scaffold(
            body: RouteMap(
              stations: StationRegistry.stations,
              completed: 3,
              next: 4,
              finished: finished,
              onStation: (s) => opened = s,
              onQuickClock: () => quick++,
              onTimeGates: () {},
            ),
          ),
        );

    await tester.pumpWidget(build(finished: false));
    expect(find.byKey(const ValueKey('map-quick')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('map-2')));
    expect(opened?.number, 2);
    await tester.tap(find.byKey(const ValueKey('map-4'))); // sıradaki: açık
    expect(opened?.number, 4);
    opened = null;
    await tester.tap(find.byKey(const ValueKey('map-7')), warnIfMissed: false);
    expect(opened, isNull);

    await tester.pumpWidget(build(finished: true));
    expect(find.byKey(const ValueKey('map-gates')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('map-quick')));
    expect(quick, 1);
  });

  test('Hızlı Saat ve Zaman Kapıları durakları ilerlemeye sayılmaz', () {
    final quick = StationRegistry.quickClock(seed: 42);
    expect(quick.scenes.length, 1);
    expect(StationRegistry.byNumber(quick.number), isNull);
    expect(StationRegistry.quickClock(seed: 42).scenes.first.id, 'quick');
    expect(StationRegistry.timeGates.scenes.map((s) => s.id), ['gates']);
    expect(StationRegistry.byNumber(StationRegistry.timeGates.number), isNull);
  });

  testWidgets('hikâye bitince haritadan Hızlı Saat açılır ve başlığa döner',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    Speech.instance.enabled = false; // test ortamında TTS yok
    final store = ProgressStore.instance;
    await store.load();
    store.progress
      ..completedStation = StationRegistry.stations.length
      ..prologSeen = true;
    await store.save();

    await tester.pumpWidget(const MaterialApp(home: StoryFlow()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('map-quick')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('map-quick')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.textContaining('Kar bulutu geldi'), findsOneWidget);
    expect(store.progress.completedStation, StationRegistry.stations.length);

    // Sinematik süre zamanlayıcıları boşalsın.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 15));
  });
}
