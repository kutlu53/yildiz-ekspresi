import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zaman_bekcisi/core/clock_time.dart';
import 'package:zaman_bekcisi/features/armclock/arm_clock_game.dart';
import 'package:zaman_bekcisi/features/armclock/arm_clock_screen.dart';
import 'package:zaman_bekcisi/features/camera/pose_frame.dart';
import 'package:zaman_bekcisi/features/story/progress_store.dart';
import 'package:zaman_bekcisi/shared/audio/speech.dart';
import 'package:zaman_bekcisi/shared/widgets/draggable_clock.dart';

import '../mechanics/fake_controller.dart';

void main() {
  group('ArmClockGame', () {
    test('standart oyun: 10 tur, kolaydan zora, ardışık hedefler farklı', () {
      final g = ArmClockGame.standard(seed: 7);
      expect(g.rounds.length, 10);
      expect(g.rounds.first.level, ArmClockLevel.full);
      expect(g.rounds.last.level, ArmClockLevel.five);
      for (var i = 1; i < g.rounds.length; i++) {
        expect(g.rounds[i].target.sameOnDial(g.rounds[i - 1].target), isFalse);
      }
      for (final r in g.rounds) {
        expect(r.target.minute % (r.level.minuteStep == 60 ? 60 : r.level.minuteStep), 0);
      }
    });

    test('sabit tutunca puan: taban + süre bonusu + seri; süre dolunca ceza yok', () {
      final g = ArmClockGame(
        rounds: const [
          ArmClockRound(target: ClockTime(3, 0), level: ArmClockLevel.full),
          ArmClockRound(target: ClockTime(6, 0), level: ArmClockLevel.full),
          ArmClockRound(target: ClockTime(9, 0), level: ArmClockLevel.full),
        ],
        hold: const Duration(seconds: 1),
      );
      var now = Duration.zero;
      g.startRound(now);
      // Yanlış poz: ilerleme sıfır.
      var u = g.update(const ClockTime(5, 0), now);
      expect(u.event, ArmClockEvent.none);
      expect(u.holdProgress, 0);
      // Doğru poz 1 sn tutulur.
      u = g.update(const ClockTime(3, 0), now);
      now += const Duration(milliseconds: 500);
      u = g.update(const ClockTime(3, 0), now);
      expect(u.holdProgress, closeTo(0.5, 0.01));
      now += const Duration(milliseconds: 500);
      u = g.update(const ClockTime(3, 0), now);
      expect(u.event, ArmClockEvent.confirmed);
      // 12 sn'nin 1 sn'si geçti: bonus ~92.
      expect(u.points, inInclusiveRange(190, 195));
      expect(g.index, 1);
      expect(g.streak, 1);

      // İkinci tur: süre dolar.
      g.startRound(now);
      now += const Duration(seconds: 13);
      u = g.update(null, now);
      expect(u.event, ArmClockEvent.timeout);
      expect(u.points, 0);
      expect(g.streak, 0);
      expect(g.index, 2);

      // Son tur: sürükleme modu anında onaylar, oyun biter.
      g.startRound(now);
      u = g.update(const ClockTime(9, 0), now, instant: true);
      expect(u.event, ArmClockEvent.confirmed);
      expect(u.points, 200); // tam süre bonusu, seri sıfırdan
      expect(g.finished, isTrue);
      expect(g.confirmed, 2);
      expect(g.stars, inInclusiveRange(1, 3));
    });

    test('seviye okuması: kol açıları toleransa göre saate çevrilir', () {
      PoseFrame frame(double hourAngle, double minuteAngle) {
        PosePoint wrist(double a) {
          final rad = a * 3.141592653589793 / 180;
          // ekran y aşağı: 12 yönü yukarı
          return PosePoint(0.5 + 0.3 * _sin(rad), 0.4 - 0.3 * _cos(rad), 1);
        }

        return PoseFrame(
          hourArm: ArmReading(shoulder: const PosePoint(0.5, 0.4, 1), wrist: wrist(hourAngle)),
          minuteArm: ArmReading(shoulder: const PosePoint(0.5, 0.4, 1), wrist: wrist(minuteAngle)),
          fps: 30,
          videoWidth: 4,
          videoHeight: 3,
        );
      }

      expect(ArmClockLevel.full.read(frame(90, 0)), const ClockTime(3, 0));
      expect(ArmClockLevel.full.read(frame(96, 8)), const ClockTime(3, 0)); // tolerans içi
      expect(ArmClockLevel.half.read(frame(105, 180)), const ClockTime(3, 30));
      expect(ArmClockLevel.quarter.read(frame(97, 90)), const ClockTime(3, 15));
      expect(ArmClockLevel.five.read(frame(130, 120)), const ClockTime(4, 20));
      expect(ArmClockLevel.five.read(frame(130, 150)), isNot(const ClockTime(4, 20)));
    });
  });

  group('ArmClockScreen (sürükleme modu)', () {
    testWidgets('başla, iki tur kur, puan artar', (tester) async {
      setScreen(tester);
      SharedPreferences.setMockInitialValues({});
      Speech.instance.enabled = false;
      await ProgressStore.instance.load();
      await tester.pumpWidget(const MaterialApp(
        home: ArmClockScreen(forceDrag: true, seed: 3),
      ));
      await tester.pump();
      expect(find.byKey(const ValueKey('arm-start')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('arm-start')));
      await tester.pump();
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      // Oyun başladı: istem görünür, kadran sürüklenebilir.
      final clock = tester.widget<DraggableClock>(find.byType(DraggableClock));
      expect(clock.draggable, isNotEmpty);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // İlk hedefe kur (tam saat): akrebi hedefe sürükle.
      final game = ArmClockGame.standard(seed: 3);
      final target = game.rounds.first.target;
      await dragHand(tester,
          fromAngle: 0, toAngle: target.hourHandAngle, frac: 0.45);
      await tester.pump();
      expect(find.textContaining('+'), findsOneWidget); // +puan
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      // İkinci tur başladı.
      expect(find.text('2/10'), findsOneWidget);

      // Süre dolsun: ceza yok, üçüncü tura geçer.
      for (var i = 0; i < 140; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('3/10'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Çıkış: zamanlayıcılar boşalsın.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 20));
    });
  });
}

double _sin(double r) => _taylor(r, true);
double _cos(double r) => _taylor(r, false);

double _taylor(double r, bool sine) {
  // dart:math kullanmadan basit seri (test yardımcısı)
  var x = r % (2 * 3.141592653589793);
  if (x > 3.141592653589793) x -= 2 * 3.141592653589793;
  var term = sine ? x : 1.0;
  var sum = term;
  for (var n = 1; n < 12; n++) {
    final k = sine ? 2 * n : 2 * n - 1;
    term *= -x * x / (k * (k + 1));
    sum += term;
  }
  return sum;
}
