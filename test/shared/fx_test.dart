import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/features/story/props.dart';
import 'package:zaman_bekcisi/shared/audio/sfx.dart';
import 'package:zaman_bekcisi/shared/widgets/star_burst.dart';
import 'package:zaman_bekcisi/shared/widgets/steam_puffs.dart';
import 'package:zaman_bekcisi/shared/widgets/train.dart';

/// Görsel dokunuşlar hatasız çizilir: konfeti, buhar, ışıklı kapı, tren.
void main() {
  setUp(() {
    Sfx.instance.enabled = true;
    Sfx.instance.log.clear();
  });

  testWidgets('konfeti: küçük ve büyük patlama, sessiz seçenek', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Stack(children: [StarBurst(play: 0), StarBurst(play: 0, big: true, silent: true)]),
    ));
    await tester.pumpWidget(const MaterialApp(
      home: Stack(children: [StarBurst(play: 1), StarBurst(play: 1, big: true, silent: true)]),
    ));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(tester.takeException(), isNull);
    expect(Sfx.instance.log, [SfxId.success]); // sessiz olan çalmadı
  });

  testWidgets('buhar: tek seferlik ve döngü; kol inince puf', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Column(children: [
        SteamPuffs(active: false),
        SteamPuffs(active: true, loop: true),
        LeverProp(down: false),
      ]),
    ));
    await tester.pumpWidget(const MaterialApp(
      home: Column(children: [
        SteamPuffs(active: true),
        SteamPuffs(active: true, loop: true),
        LeverProp(down: true),
      ]),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(tester.takeException(), isNull);
    expect(Sfx.instance.log, contains(SfxId.whistle));
  });

  testWidgets('ışıklı kapı, kilit ve tren hatasız çizilir', (tester) async {
    for (final open in [false, true]) {
      await tester.pumpWidget(MaterialApp(
        home: Column(children: [
          GateProp(open: open),
          LockProp(gears: open ? 5 : 0, turning: open),
          Train(wagons: 3, moving: open, height: 90),
        ]),
      ));
      await tester.pump(const Duration(milliseconds: 800));
    }
    expect(tester.takeException(), isNull);
  });
}
