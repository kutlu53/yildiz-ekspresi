import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zaman_bekcisi/core/clock_time.dart';
import 'package:zaman_bekcisi/core/week.dart';
import 'package:zaman_bekcisi/core/year.dart';
import 'package:zaman_bekcisi/features/mechanics/attach_hands.dart';
import 'package:zaman_bekcisi/features/mechanics/balance.dart';
import 'package:zaman_bekcisi/features/mechanics/calendar.dart';
import 'package:zaman_bekcisi/features/mechanics/choose_option.dart';
import 'package:zaman_bekcisi/features/mechanics/count_minutes.dart';
import 'package:zaman_bekcisi/features/mechanics/mechanic_frame.dart';
import 'package:zaman_bekcisi/features/mechanics/pick_clock.dart';
import 'package:zaman_bekcisi/features/mechanics/place_cards.dart';
import 'package:zaman_bekcisi/features/mechanics/quick_clock.dart';
import 'package:zaman_bekcisi/features/mechanics/read_clock.dart';
import 'package:zaman_bekcisi/features/mechanics/set_clock.dart';
import 'package:zaman_bekcisi/features/mechanics/stone_path.dart';
import 'package:zaman_bekcisi/features/mechanics/stop_hand.dart';
import 'package:zaman_bekcisi/features/mechanics/tap_hand.dart';
import 'package:zaman_bekcisi/features/mechanics/turn_day.dart';
import 'package:zaman_bekcisi/features/story/cinematic_player.dart';
import 'package:zaman_bekcisi/features/story/lines.dart';
import 'package:zaman_bekcisi/features/story/progress_store.dart';
import 'package:zaman_bekcisi/features/story/stations/stations.dart';
import 'package:zaman_bekcisi/features/story/story_flow.dart';
import 'package:zaman_bekcisi/shared/audio/speech.dart';
import 'package:zaman_bekcisi/shared/widgets/clock_face.dart';
import 'package:zaman_bekcisi/shared/widgets/draggable_clock.dart';
import 'package:zaman_bekcisi/shared/widgets/pamuk.dart';

import '../features/mechanics/fake_controller.dart';

/// Uçtan uca "robot çocuk": başlıktan jeneriğe tüm hikâye, her mekanik,
/// iki bilinçli hata (ısınma yolunu açar) ve sonunda haritadan Hızlı Saat.
/// TTS kapalı (test ortamında eklenti yok); süreler sahte zamanla geçer.
void main() {
  testWidgets('çocuk oyunu baştan sona oynar', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    Speech.instance.enabled = false;
    final store = ProgressStore.instance;
    await store.load();
    await store.reset();
    await store.setGrade(null);

    // ---- yardımcılar ----
    Future<void> wait([int ms = 900]) async {
      for (var t = 0; t < ms; t += 100) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> cinematic() async {
      var guard = 0;
      await wait(300);
      while (find.byType(CinematicPlayer).evaluate().isNotEmpty && guard++ < 12) {
        await tester.tapAt(const Offset(400, 120));
        await tester.pump();
        await wait(900);
      }
      expect(find.byType(CinematicPlayer), findsNothing,
          reason: 'sinematik bitmeli');
    }

    String onScreen() => tester.allWidgets
        .map((w) => w.runtimeType.toString())
        .where((n) => n.endsWith('Mechanic') || n == 'CinematicPlayer' || n == '_TitleScreen')
        .toSet()
        .join(', ');

    void expectScene(Type type) => expect(find.byType(type), findsOneWidget,
        reason: '$type bekleniyor; ekranda: ${onScreen()}');

    /// Pamuk'un balonunda bu metin var mı?
    bool c0Spoken(String text) =>
        find.textContaining(text.substring(0, 12)).evaluate().isNotEmpty;

    Future<void> hour(double from, double to) async {
      await dragHand(tester, fromAngle: from, toAngle: to, frac: 0.45);
      await wait();
    }

    Future<void> minute(double from, double to, {int steps = 6}) async {
      await dragHand(tester, fromAngle: from, toAngle: to, frac: 0.85, steps: steps);
      await wait();
    }

    Future<void> tapSign(String text) async {
      await tester.tap(find.widgetWithText(WoodenSign, text));
      await tester.pump();
      await wait();
    }

    Future<void> tapKey(String key) async {
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pump();
      await wait();
    }

    Future<void> tapClock(ClockTime target) async {
      await tester.tap(find.byWidgetPredicate(
          (w) => w is DraggableClock && w.time.sameOnDial(target)));
      await tester.pump();
      await wait();
    }

    Future<void> dropCard(String cardId, int slotIndex) async {
      final card = find.byWidgetPredicate(
          (w) => w is Draggable<PlaceCard> && w.data?.id == cardId);
      final g = await tester.startGesture(tester.getCenter(card));
      await tester.pump(const Duration(milliseconds: 100));
      await g.moveTo(tester
          .getCenter(find.byType(DragTarget<PlaceCard>).at(slotIndex)));
      await tester.pump(const Duration(milliseconds: 100));
      await g.up();
      await tester.pump();
      await wait();
    }

    Future<void> tapFace(double angle, double frac) async {
      final face = find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is ClockFacePainter);
      final rect = tester.getRect(face);
      await tester.tapAt(pointAt(rect.center, rect.shortestSide / 2, angle, frac));
      await tester.pump();
      await wait();
    }

    /// Hangisi? sahnesi (akrep, yelkovan, akrep) 3:00'te.
    Future<void> playTapHand({bool mistake = false}) async {
      expectScene(TapHandMechanic);
      if (mistake) await tapFace(0, 0.75); // yelkovana dokunur: yanlış
      await tapFace(90, 0.45); // akrep
      await tapFace(0, 0.75); // yelkovan
      await tapFace(90, 0.45); // akrep
    }

    /// Peron sahnesi: biletteki saatin kadranına dokun.
    Future<void> playPlatform({bool mistake = false}) async {
      expectScene(PickClockMechanic);
      for (final t in const [ClockTime(3, 25), ClockTime(9, 10), ClockTime(7, 48)]) {
        if (mistake && t.hour == 3) {
          final wrong = tester
              .widgetList<DraggableClock>(find.byType(DraggableClock))
              .firstWhere((w) => !w.time.sameOnDial(t));
          await tapClock(wrong.time);
        }
        await tapClock(t);
      }
    }

    Future<void> playStopHand(ClockTime target) async {
      for (var i = 0; i < 400; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        final clock = tester.widget<DraggableClock>(find.byType(DraggableClock));
        final diff = (clock.time.minuteHandAngle - target.minuteHandAngle).abs();
        if (diff <= 6 || diff >= 354) break;
      }
      await tester.tap(find.byType(DraggableClock));
      await tester.pump();
      await wait();
    }

    // ---- başlık ve prolog ----
    await tester.pumpWidget(const MaterialApp(home: StoryFlow()));
    await wait(300);
    expect(find.text('Yıldız Ekspresi'), findsOneWidget);
    await tester.tap(find.byType(Pamuk));
    await tester.pump();
    await cinematic(); // prolog
    await cinematic(); // yolculuk → durak 1
    await cinematic(); // durak 1 giriş

    // ---- Durak 1: Garaj ----
    expectScene(AttachHandsMechanic);
    for (final hand in [ClockHand.hour, ClockHand.minute]) {
      final piece = find.byWidgetPredicate(
          (w) => w is Draggable<ClockHand> && w.data == hand);
      final at = tester.getCenter(piece);
      final g = await tester.startGesture(at);
      await tester.pump(const Duration(milliseconds: 100));
      final target = clockGeometry(tester).center;
      for (var k = 1; k <= 5; k++) {
        await g.moveTo(Offset.lerp(at, target, k / 5)!);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await g.up();
      await tester.pump();
      await wait();
    }
    await playTapHand(mistake: true); // bilinçli hata → ısınma
    expectScene(CountMinutesMechanic);
    await minute(0, 360, steps: 36);
    await cinematic(); // durak 1 kapanış
    expect(store.progress.completedStation, 1);
    expect(store.progress.mistakes['1.tap'], 1);

    // ---- Durak 2: İlk Hat (önce ısınma: Hangisi?) ----
    await cinematic(); // yolculuk
    await playTapHand(); // ısınma
    await cinematic(); // giriş
    expectScene(SetClockMechanic);
    // Saat yanlışken kol kıpırdamaz.
    await tester.drag(find.byKey(const ValueKey('big-lever')), const Offset(0, 160));
    await wait();
    expect(c0Spoken(Lines.s2LeverStuck.text), isTrue);
    await hour(0, 240); // saat sekiz
    await tester.drag(find.byKey(const ValueKey('big-lever')), const Offset(0, 160));
    await wait(3600); // düdük, tren kalkar
    expectScene(ReadClockMechanic);
    for (final t in ['3:00', '11:00']) {
      await tester.tap(find.byKey(ValueKey('wagon-$t')));
      await tester.pump();
      await wait();
    }
    expectScene(ChooseOptionMechanic);
    await tapKey('choice-0'); // Pamuk haklı
    await tapKey('choice-1'); // Pamuk yanıldı
    expectScene(SetClockMechanic);
    await hour(0, 90); // kapı: üç
    await wait(3600); // tren tünele girer
    await cinematic();
    expect(store.progress.completedStation, 2);

    // ---- Durak 3: Çarklı Köprü ----
    await cinematic();
    await cinematic();
    expectScene(SetClockMechanic);
    await minute(0, 180); // üç buçuk
    await minute(0, 180); // yedi buçuk
    expectScene(StopHandMechanic);
    await playStopHand(const ClockTime(4, 15));
    await playStopHand(const ClockTime(8, 45));
    expectScene(ReadClockMechanic);
    for (final t in ['2:00', '5:30', '9:15', '10:45']) {
      await tapSign(t);
    }
    expectScene(SetClockMechanic);
    await hour(0, 180); // altı
    await minute(0, 180); // buçuk
    await cinematic();
    expect(store.progress.completedStation, 3);

    // ---- Durak 4: Fener Tüneli ----
    await cinematic();
    await cinematic();
    expectScene(CountMinutesMechanic);
    await minute(0, 360, steps: 36);
    expectScene(SetClockMechanic);
    await minute(0, 120); // 20
    await minute(0, 270); // 45
    await minute(0, 210); // 35
    expectScene(SetClockMechanic);
    await minute(0, 18, steps: 3); // 4:03
    await minute(90, 102, steps: 2); // 6:17
    await minute(180, 204, steps: 4); // 10:34
    await cinematic();
    expect(store.progress.completedStation, 4);

    // ---- Durak 5: Büyük İstasyon ----
    await cinematic();
    await cinematic();
    expectScene(SetClockMechanic);
    await hour(0, 90);
    await minute(0, 150); // 3:25
    await hour(0, 300);
    await minute(0, 240); // 10:40
    await minute(270, 288, steps: 3); // 7:48
    await minute(300, 312, steps: 2); // 1:52
    await playPlatform(mistake: true); // bilinçli hata → ısınma
    expectScene(SetClockMechanic);
    await hour(0, 240);
    await minute(0, 270); // dokuza çeyrek var
    await hour(0, 60);
    await minute(0, 120); // ikiyi yirmi geçiyor
    await hour(0, 120);
    await minute(0, 300); // beşe on var
    expectScene(SetClockMechanic);
    await hour(0, 120);
    await minute(0, 120); // kapı 4:20
    await cinematic();
    expect(store.progress.completedStation, 5);
    expect(store.progress.mistakes['5.platform'], 1);

    // ---- Durak 6: Gece Hattı (önce ısınma: peron) ----
    await cinematic();
    await playPlatform(); // ısınma
    await cinematic();
    expectScene(TurnDayMechanic);
    await dragHand(tester, fromAngle: 180, toAngle: 540, frac: 0.45, steps: 24);
    await dragHand(tester, fromAngle: 180, toAngle: 540, frac: 0.45, steps: 24);
    await wait();
    expectScene(PlaceCardsMechanic);
    const dayCards = {'wake': 0, 'lunch': 1, 'dinner': 2, 'sleep': 3};
    for (final e in dayCards.entries) {
      await dropCard(e.key, e.value);
    }
    expectScene(PickClockMechanic);
    await tapClock(const ClockTime(15, 0));
    await tapClock(const ClockTime(20, 0));
    await tapClock(const ClockTime(3, 0));
    await cinematic();
    expect(store.progress.completedStation, 6);

    // ---- Durak 7: Pazar Kasabası ----
    await cinematic();
    await cinematic();
    expectScene(StonePathMechanic);
    for (final d in [Week.wednesday, Week.thursday, Week.friday, Week.saturday]) {
      await tapKey('stone-$d');
    }
    for (final d in [6, 0, 1, 2, 3, 4, 5]) {
      await tapKey('stone-$d');
    }
    expectScene(PlaceCardsMechanic);
    for (var d = 0; d < 7; d++) {
      await dropCard('day$d', d);
    }
    expectScene(StonePathMechanic);
    for (final d in [Week.saturday, Week.monday, Week.wednesday, Week.friday]) {
      await tapKey('stone-$d');
      await wait(3000); // Pamuk taş taş zıplar
    }
    await cinematic();
    expect(store.progress.completedStation, 7);

    // ---- Durak 8: Mevsim Vadisi ----
    await cinematic();
    await cinematic();
    expectScene(StonePathMechanic);
    for (var m = 1; m <= 12; m++) {
      await tapKey('stone-${m % 12}');
    }
    expectScene(ChooseOptionMechanic);
    for (final idx in [0, 1, 2, 0, 0, 1]) {
      await tapKey('choice-$idx');
    }
    expectScene(PlaceCardsMechanic);
    for (var m = 0; m < 12; m++) {
      await dropCard('m$m', Year.seasonOf(m));
    }
    expectScene(CalendarMechanic);
    await tapKey('cal-14');
    await tapKey('cal-6');
    await tapKey('cal-28');
    await cinematic();
    expect(store.progress.completedStation, 8);

    // ---- Durak 9: Kar Dağı Eteği ----
    await cinematic();
    await cinematic();
    expectScene(BalanceMechanic);
    for (var i = 0; i < 6; i++) {
      await tapKey('weight-$i'); // 6 × 10 dk
    }
    for (var i = 0; i < 4; i++) {
      await tapKey('weight-$i'); // 4 × 6 saat
    }
    for (var i = 0; i < 7; i++) {
      await tapKey('weight-$i'); // 7 × 1 gün
    }
    expectScene(ChooseOptionMechanic);
    for (final idx in [0, 1, 2, 0]) {
      await tapKey('choice-$idx');
    }
    expectScene(QuickClockMechanic);
    for (final t in ['7:00', '2:30', '4:20', '9:45', '12:00', '6:50', '11:15', '8:35']) {
      await tapSign(t);
    }
    await cinematic();
    expect(store.progress.completedStation, 9);

    // ---- Durak 10: Yuva ----
    await cinematic();
    await cinematic();
    expectScene(SetClockMechanic);
    await hour(0, 150); // beş
    await hour(0, 270);
    await minute(0, 180); // dokuz buçuk
    await hour(0, 60);
    await minute(0, 270); // üçe çeyrek var
    expectScene(ReadClockMechanic);
    for (final t in ['11:00', '6:15', '3:40']) {
      await tapSign(t);
    }
    expectScene(PlaceCardsMechanic);
    const lockCards = {'wake': 0, 'lunch': 1, 'dinner': 2, 'sleep': 3};
    for (final e in lockCards.entries) {
      await dropCard(e.key, e.value);
    }
    expectScene(CalendarMechanic);
    await tapKey('cal-21');
    expectScene(BalanceMechanic);
    await tapKey('weight-0');
    await tapKey('weight-1'); // 12 + 12 saat
    await cinematic(); // durak 10 kapanış
    expect(store.progress.completedStation, 10);
    expect(store.progress.items.length, 10);

    // ---- Final ve jenerik (kapanışla birlikte dokunarak geçildi) ----
    await cinematic();
    expect(find.text('Yıldız Ekspresi'), findsOneWidget);
    expect(find.byKey(const ValueKey('map-quick')), findsOneWidget);

    // ---- Oyun sonu: haritadan Hızlı Saat ----
    await tapKey('map-quick');
    await cinematic(); // giriş
    expectScene(QuickClockMechanic);
    for (var i = 0; i < 10; i++) {
      final shown = tester.widget<DraggableClock>(find.byType(DraggableClock)).time;
      await tapSign(shown.digital12);
    }
    await cinematic(); // kapanış
    expect(find.text('Yıldız Ekspresi'), findsOneWidget);
    expect(store.progress.completedStation, 10, reason: 'tekrar oynama ilerlemeyi bozmaz');
    expect(StationRegistry.stations.length, 10);

    // Dokunarak geçilen son sinematiğin süre zamanlayıcısı boşalsın.
    await wait(15000);
  });
}
