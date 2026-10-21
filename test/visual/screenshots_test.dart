@Tags(['visual'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zaman_bekcisi/features/armclock/arm_clock_screen.dart';
import 'package:zaman_bekcisi/features/story/models.dart';
import 'package:zaman_bekcisi/features/story/progress_store.dart';
import 'package:zaman_bekcisi/features/story/scene_scaffold.dart';
import 'package:zaman_bekcisi/features/story/stations/stations.dart';
import 'package:zaman_bekcisi/features/story/story_flow.dart';
import 'package:zaman_bekcisi/features/teacher/teacher_panel.dart';
import 'package:zaman_bekcisi/shared/audio/speech.dart';

import '../features/mechanics/fake_controller.dart';

/// Ekran görüntüsü üretir (flutter test --update-goldens --tags visual) ve
/// her yerleşimde taşma hatası olup olmadığını raporlar. Telefon ve tablet
/// boyutlarında tasarımı gözle denetlemek için; normal testlerde çalışmaz.
const sizes = <String, Size>{
  'tel-dikey': Size(390, 844),
  'tel-yatay': Size(844, 390),
  'tablet-yatay': Size(1024, 768),
  'tablet-dikey': Size(768, 1024),
};

/// (durak, sahne) çiftleri: farklı yerleşim kalıplarından birer örnek.
const scenes = <String, (int, int)>{
  'garaj-tak': (1, 0),
  'ilkhat-kol': (2, 0),
  'ilkhat-vagon': (2, 1),
  'ilkhat-kapi': (2, 3),
  'kopru-zil': (3, 1),
  'kopru-oku': (3, 2),
  'fener-say': (4, 0),
  'istasyon-peron': (5, 1),
  'gece-gun': (6, 1),
  'pazar-taslar': (7, 0),
  'pazar-pano': (7, 1),
  'vadi-evler': (8, 1),
  'vadi-vagonlar': (8, 2),
  'vadi-takvim': (8, 3),
  'etek-terazi': (9, 0),
  'etek-hizli': (9, 2),
  'yuva-kilit': (10, 0),
};

/// Yalnız VISUAL=1 ile çalışır; CI'de ve normal testlerde atlanır.
final visual = Platform.environment.containsKey('VISUAL');

void main() {
  final overflows = <String>[];

  setUpAll(() async {
    // Gerçek yazı tipi: test ortamının kutu harfleri yerine okunur metin.
    final file = File(r'C:\Windows\Fonts\arial.ttf');
    if (file.existsSync()) {
      final bytes = file.readAsBytesSync();
      final loader = FontLoader('Roboto')
        ..addFont(Future.value(ByteData.view(bytes.buffer)));
      await loader.load();
    }
    Speech.instance.enabled = false;
    SharedPreferences.setMockInitialValues({});
    await ProgressStore.instance.load();
  });

  tearDownAll(() {
    final out = File('test/visual/goldens/overflow_report.txt');
    out.writeAsStringSync(overflows.isEmpty ? 'taşma yok\n' : '${overflows.join('\n')}\n');
  });

  Future<void> snap(WidgetTester tester, String name, Size size, Widget app,
      {int pumps = 6}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app);
    for (var i = 0; i < pumps; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    final e = tester.takeException();
    if (e != null) {
      final msg = e.toString().split('\n').first;
      overflows.add('$name: $msg');
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 20));
  }

  Widget scene(int station, int index) {
    final s = StationRegistry.byNumber(station)!;
    final c = FakeController();
    final caption = ValueNotifier<String?>(
        'Pamuk burada konuşur: kısa bir replik balonu.');
    final mood = ValueNotifier(PamukMood.talking);
    return MaterialApp(
      home: Scaffold(
        body: SceneScaffold(
          scenery: s.scenery,
          season: s.season,
          caption: caption,
          mood: mood,
          onPamukTap: () {},
          child: Builder(builder: (ctx) => s.scenes[index].build(ctx, c)),
        ),
      ),
    );
  }

  for (final size in sizes.entries) {
    group(size.key, () {
      testWidgets('baslik', skip: !visual, (tester) async {
        SharedPreferences.setMockInitialValues({});
        await ProgressStore.instance.reset();
        await snap(tester, 'baslik_${size.key}', size.value,
            const MaterialApp(home: StoryFlow()));
      });

      for (final sc in scenes.entries) {
        testWidgets(sc.key, skip: !visual, (tester) async {
          await snap(tester, '${sc.key}_${size.key}', size.value,
              scene(sc.value.$1, sc.value.$2));
        });
      }

      testWidgets('kolsaati', skip: !visual, (tester) async {
        await snap(tester, 'kolsaati_${size.key}', size.value,
            const MaterialApp(home: ArmClockScreen(forceDrag: true, seed: 1)));
      });

      testWidgets('ogretmen', skip: !visual, (tester) async {
        await snap(tester, 'ogretmen_${size.key}', size.value,
            MaterialApp(home: TeacherPanel(onJump: (_) {})));
      });
    });
  }
}
