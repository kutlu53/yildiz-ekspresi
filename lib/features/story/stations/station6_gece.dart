import 'package:flutter/material.dart';

import '../../../core/clock_time.dart';
import '../../../core/turkish_time.dart';
import '../../../shared/widgets/day_window.dart';
import '../../../shared/widgets/draggable_clock.dart';
import '../../../shared/widgets/scenery_view.dart';
import '../../mechanics/mechanic_frame.dart';
import '../../mechanics/pick_clock.dart';
import '../../mechanics/place_cards.dart';
import '../../mechanics/turn_day.dart';
import '../lines.dart';
import '../models.dart';

/// Pamuk'un günü: etkinlik ve saati (24 saatlik).
const _dayPlan = <(String id, String label, IconData icon, int hour)>[
  ('wake', 'Uyanma', Icons.alarm, 7),
  ('breakfast', 'Kahvaltı', Icons.bakery_dining, 8),
  ('play', 'Oyun', Icons.sports_soccer, 10),
  ('lunch', 'Öğle yemeği', Icons.restaurant, 12),
  ('dinner', 'Akşam yemeği', Icons.dinner_dining, 18),
  ('sleep', 'Uyku', Icons.bedtime, 21),
];

/// Yuva görünümü: küçük pencere (manzara saati doğrular) ve küçük kadran.
Widget _hourSlot(BuildContext context, int hour, bool filled, bool glow) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      DayWindow(hour: hour.toDouble(), width: 96, height: 64, highlighted: glow),
      const SizedBox(height: 4),
      SizedBox(
        width: 72,
        height: 72,
        child: ClockFrame(
          style: ClockFrameStyle.cab,
          child: DraggableClock(
            time: ClockTime(hour, 0),
            draggable: const {},
            glowHands: glow ? const {ClockHand.hour} : const {},
            showNumerals: false,
          ),
        ),
      ),
    ],
  );
}

/// Durak 6: Gece Hattı. Gün 24 saattir; sabah, öğle, akşam, gece; günün
/// akışı; 24 saatlik dijital gösterim. Üç farklı his: akrebi iki tur
/// döndürüp pencereden günü izlemek (gün turu), etkinlik kartlarını saatlere
/// yerleştirmek (sırala), 15:00 ile kadran 3'ü eşlemek (eşleştir).
final station6 = Station(
  number: 6,
  title: 'Bir Tam Gün',
  place: 'Gece Hattı',
  scenery: Scenery.cabin,
  clockFrame: ClockFrameStyle.cab,
  travelLine: Lines.s6Travel,
  reward: const VagonItem(
      id: 'star_map', name: 'Yıldız haritası', icon: Icons.auto_awesome),
  intro: const [
    CinematicShot(
      line: Lines.s6Intro,
      mood: PamukMood.thinking,
      duration: Duration(seconds: 6),
    ),
  ],
  scenes: [
    Scene(
      id: 'window',
      build: (context, c) => TurnDayMechanic(
        controller: c,
        startHour: 6,
        intro: Lines.s6WindowIntro,
        done: Lines.s6WindowDone,
        milestones: const {12: Lines.s6Noon},
        prop: (hour, elapsed) => DayWindow(hour: hour.toDouble()),
      ),
    ),
    Scene(
      id: 'day',
      build: (context, c) => PlaceCardsMechanic(
        controller: c,
        intro: Lines.s6DayIntro,
        wrongLine: Lines.s6Wrong,
        done: Lines.s6DayDone,
        shuffleSeed: 6,
        prop: (last) => DayWindow(
          hour: last == null ? 6 : double.parse(last.id),
          width: 150,
          height: 90,
        ),
        cards: [
          for (final (id, label, icon, hour) in _dayPlan)
            PlaceCard(id: id, label: label, icon: icon, slotId: '$hour'),
        ],
        slots: [
          for (final (_, _, _, hour) in _dayPlan)
            PlaceSlot(
              id: '$hour',
              spoken: TurkishTime.spoken24(ClockTime(hour, 0)),
              build: (context, filled, glow) =>
                  _hourSlot(context, hour, filled, glow),
            ),
        ],
      ),
    ),
    Scene(
      id: 'fifteen',
      build: (context, c) => PickClockMechanic(
        controller: c,
        intro: Lines.s6FifteenIntro,
        hintLine: Lines.s6FifteenHint,
        frame: ClockFrameStyle.cab,
        prop: (round) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DigitalBoard(text: round.target.digital24),
            const SizedBox(width: 16),
            DayWindow(hour: round.target.hour.toDouble(), width: 130, height: 84),
          ],
        ),
        rounds: const [
          PickClockRound(
            target: ClockTime(15, 0),
            options: [ClockTime(5, 0), ClockTime(3, 0), ClockTime(1, 0)],
            spokenPrompt:
                'On beş sıfır sıfır. Pencereye bak, öğleden sonra. Hangi kadran?',
            successSpoken: 'On beş, öğleden sonra üç demek. On iki, artı üç.',
          ),
          PickClockRound(
            target: ClockTime(20, 0),
            options: [ClockTime(8, 0), ClockTime(2, 0), ClockTime(10, 0)],
            spokenPrompt: 'Yirmi sıfır sıfır. Akşam oldu. Hangi kadran?',
            successSpoken: 'Yirmi, akşam sekiz demek. On iki, artı sekiz.',
          ),
          PickClockRound(
            target: ClockTime(3, 0),
            options: [ClockTime(9, 0), ClockTime(12, 0), ClockTime(3, 0)],
            spokenPrompt:
                'Üç sıfır sıfır. Pencere kapkaranlık, gece üç. Hangi kadran?',
            successSpoken:
                'Gece üç ile öğleden sonra üç kadranda aynı, ama pencere farklı!',
          ),
        ],
      ),
    ),
  ],
  outro: const [
    CinematicShot(
      line: Lines.s6Outro,
      mood: PamukMood.sleepy,
      duration: Duration(seconds: 4),
      trainMoving: true,
    ),
  ],
);
