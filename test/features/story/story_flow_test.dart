import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/features/story/lines.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zaman_bekcisi/features/story/progress_store.dart';
import 'package:zaman_bekcisi/features/story/story_flow.dart';
import 'package:zaman_bekcisi/shared/audio/speech.dart';
import 'package:zaman_bekcisi/shared/widgets/pamuk.dart';

void main() {
  testWidgets('başlıkta Pamuk\'a dokununca prolog, sonra yolculuk ve durak 1',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    Speech.instance.enabled = false; // test ortamında TTS yok

    await tester.pumpWidget(const MaterialApp(home: StoryFlow()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Yıldız Ekspresi'), findsOneWidget);
    expect(find.byIcon(Icons.touch_app_rounded), findsOneWidget);

    await tester.tap(find.byType(Pamuk));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text(Lines.prologWake.text), findsOneWidget);

    // Her dokunuş bir çekim ilerletir; 4 çekim.
    for (var i = 0; i < 4; i++) {
      await tester.tapAt(const Offset(200, 200));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
    }
    expect(ProgressStore.instance.progress.prologSeen, isTrue);

    // Yolculuk sinematiği (garaj yolu), dokununca durak 1 girişine geçer.
    expect(find.text('İşte garaj! Yıldız Ekspresi burada.'), findsOneWidget);
    await tester.tapAt(const Offset(200, 200));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.textContaining('Bu bizim trenimiz'), findsOneWidget);

    // Sinematik süre zamanlayıcıları boşalsın.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 15));
  });
}
