import 'package:flutter/material.dart';

import '../../../core/week.dart';
import '../../mechanics/mechanic_frame.dart';
import '../../mechanics/place_cards.dart';
import '../../mechanics/stone_path.dart';
import '../lines.dart';
import '../models.dart';

/// Kasaba panosu: her günün olayı.
const _events = <(int day, String event, IconData icon)>[
  (Week.monday, 'Bal', Icons.hive),
  (Week.tuesday, 'Süt', Icons.local_drink),
  (Week.wednesday, 'Çiçek', Icons.local_florist),
  (Week.thursday, 'Ekmek', Icons.bakery_dining),
  (Week.friday, 'Balık', Icons.set_meal),
  (Week.saturday, 'Tren', Icons.train),
  (Week.sunday, 'Dinlenme', Icons.self_improvement),
];

/// Sıra yuvası: panodaki sıra numarası.
Widget _orderSlot(int index, bool filled, bool glow) {
  return Container(
    width: 56,
    height: 56,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: filled
          ? const Color(0xFFC8E6C9)
          : glow
              ? const Color(0xFFFFF59D)
              : const Color(0xFFFFB300),
      shape: BoxShape.circle,
      border: Border.all(
        color: glow ? const Color(0xFFFFD54F) : const Color(0xFF5D4037),
        width: glow ? 5 : 3,
      ),
    ),
    child: Text(
      '${index + 1}',
      style: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: Color(0xFF263238),
      ),
    ),
  );
}

/// Durak 7: Pazar Kasabası. Hafta 7 gündür, günlerin sırası, "n gün sonra",
/// haftalık tekrar eden olaylar. Üç farklı his: Pamuk'u taş taş yürütmek
/// (say), kasaba panosunu sıraya dizmek (sırala), "n gün sonra" sorusunun
/// taşına dokunmak (bul). Bu durakta saat yok; taş halkası haftanın
/// döngüsünü gösterir.
final station7 = Station(
  number: 7,
  title: 'Haftada Bir',
  place: 'Pazar Kasabası',
  scenery: Scenery.market,
  clockFrame: ClockFrameStyle.post,
  travelLine: Lines.s7Travel,
  reward: const VagonItem(id: 'honey', name: 'Bal kavanozu', icon: Icons.hive),
  intro: const [
    CinematicShot(
      line: Lines.s7Intro,
      mood: PamukMood.thinking,
      duration: Duration(seconds: 6),
    ),
  ],
  scenes: [
    Scene(
      id: 'stones',
      build: (context, c) => StonePathMechanic(
        controller: c,
        mode: StoneMode.walk,
        intro: Lines.s7StonesIntro,
        hintLine: Lines.s7StonesHint,
        wrongLine: Lines.s7Wrong,
        done: Lines.s7StonesDone,
        prop: (round, done) => WoodenSign(
          text: Week.name(Week.after(round.start, round.steps)),
          highlighted: done,
        ),
        rounds: const [
          StoneRound(
            start: Week.tuesday,
            steps: 4,
            prompt:
                'Bugün Salı. Cumartesi taşına kadar yürüyelim: sıradaki taşa bas, günleri sayalım.',
          ),
          StoneRound(
            start: Week.saturday,
            steps: 7,
            prompt:
                'Bir sonraki tren gelecek Cumartesi. Yürümeye devam: Pazar\'dan sonra ne gelir?',
            successSpoken:
                'Pazar\'dan sonra yine Pazartesi geldi! Yedi gün sonra yine Cumartesi. Yedi gün, bir hafta!',
          ),
        ],
      ),
    ),
    Scene(
      id: 'board',
      build: (context, c) => PlaceCardsMechanic(
        controller: c,
        intro: Lines.s7BoardIntro,
        wrongLine: Lines.s7BoardWrong,
        done: Lines.s7BoardDone,
        shuffleSeed: 7,
        cards: [
          for (final (day, _, icon) in _events)
            PlaceCard(
              id: 'day$day',
              label: Week.name(day),
              icon: icon,
              slotId: '$day',
            ),
        ],
        slots: [
          for (final (day, event, _) in _events)
            PlaceSlot(
              id: '$day',
              spoken: '${Week.ordinals[day]} gün, ${event.toLowerCase()} günü',
              build: (context, filled, glow) => _orderSlot(day, filled, glow),
            ),
        ],
      ),
    ),
    Scene(
      id: 'hunt',
      build: (context, c) => StonePathMechanic(
        controller: c,
        mode: StoneMode.pick,
        intro: Lines.s7HuntIntro,
        hintLine: Lines.s7HuntHint,
        wrongLine: Lines.s7Wrong,
        done: Lines.s7HuntDone,
        prop: (round, done) => WoodenSign(
          text: '${round.steps} gün sonra',
          highlighted: done,
        ),
        rounds: const [
          StoneRound(
            start: Week.thursday,
            steps: 2,
            prompt: 'Bugün Perşembe. İki gün sonra hangi gün? Taşa dokun.',
          ),
          StoneRound(
            start: Week.saturday,
            steps: 2,
            prompt: 'Bugün Cumartesi. İki gün sonra hangi gün?',
          ),
          StoneRound(
            start: Week.sunday,
            steps: 3,
            prompt: 'Bugün Pazar. Üç gün sonra hangi gün?',
          ),
          StoneRound(
            start: Week.friday,
            steps: 7,
            prompt: 'Bugün Cuma. Yedi gün sonra, yani bir hafta sonra hangi gün?',
            successSpoken:
                'Bir hafta sonra yine Cuma! Hafta döner, günler yeniden gelir.',
          ),
        ],
      ),
    ),
  ],
  outro: const [
    CinematicShot(
      line: Lines.s7Outro,
      mood: PamukMood.happy,
      duration: Duration(seconds: 4),
      trainMoving: true,
    ),
  ],
);
