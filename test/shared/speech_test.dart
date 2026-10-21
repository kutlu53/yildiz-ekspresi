import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/shared/audio/speech.dart';

/// TTS eklentisi olmayan ortamda (test, motor yok) `say` asla takılmamalı.
void main() {
  testWidgets('kapalıyken hemen döner', (tester) async {
    Speech.instance.enabled = false;
    var done = false;
    Speech.instance.say('deneme').then((_) => done = true);
    await tester.pump();
    expect(done, isTrue);
  });

  testWidgets('eklenti cevap vermezse zaman aşımıyla döner', (tester) async {
    Speech.instance.enabled = true;
    var done = false;
    Speech.instance.say('deneme').then((_) => done = true);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(done, isFalse, reason: 'henüz başlatma zaman aşımında');
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(done, isTrue);
    Speech.instance.enabled = false;
  });
}
