import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/features/story/props.dart';
import 'package:zaman_bekcisi/shared/audio/sfx.dart';

void main() {
  setUp(() {
    Sfx.instance.enabled = true;
    Sfx.instance.log.clear();
  });

  test('test ortamında eklenti çağrılmaz, günlük tutulur', () {
    expect(Sfx.inTest, isTrue);
    Sfx.instance.play(SfxId.whistle);
    Sfx.instance.tick();
    expect(Sfx.instance.log, [SfxId.whistle, SfxId.tick]);
    Sfx.instance.enabled = false;
    Sfx.instance.play(SfxId.bell);
    expect(Sfx.instance.log.length, 2);
  });

  test('müzik teması durağa göre', () {
    expect(Sfx.themeFor(1), MusicTheme.autumn);
    expect(Sfx.themeFor(5), MusicTheme.autumn);
    expect(Sfx.themeFor(6), MusicTheme.night);
    expect(Sfx.themeFor(8), MusicTheme.winter);
    expect(Sfx.themeFor(11), MusicTheme.winter);
  });

  testWidgets('Cue: değer değişince çalar, koşul sağlanmazsa çalmaz',
      (tester) async {
    Widget build(bool open) => MaterialApp(home: GateProp(open: open));
    await tester.pumpWidget(build(false));
    expect(Sfx.instance.log, isEmpty);
    await tester.pumpWidget(build(true));
    expect(Sfx.instance.log, [SfxId.gear]);
    await tester.pumpWidget(build(false)); // kapanırken ses yok
    expect(Sfx.instance.log, [SfxId.gear]);
    await tester.pumpWidget(build(true));
    expect(Sfx.instance.log, [SfxId.gear, SfxId.gear]);
  });

  testWidgets('damla saati her damlada çalar, sıfırda çalmaz', (tester) async {
    Widget build(int drops) => MaterialApp(home: DripClockProp(drops: drops));
    await tester.pumpWidget(build(0));
    await tester.pumpWidget(build(1));
    await tester.pumpWidget(build(2));
    await tester.pumpWidget(build(0));
    expect(Sfx.instance.log, [SfxId.drop, SfxId.drop]);
  });
}
