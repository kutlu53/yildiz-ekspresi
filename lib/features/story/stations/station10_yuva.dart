import 'package:flutter/material.dart';

import '../../../core/clock_time.dart';
import '../../../core/turkish_time.dart';
import '../../../core/week.dart';
import '../../../shared/layout.dart';
import '../../../shared/widgets/day_window.dart';
import '../../../shared/widgets/draggable_clock.dart';
import '../../../shared/widgets/scenery_view.dart';
import '../../mechanics/balance.dart';
import '../../mechanics/calendar.dart';
import '../../mechanics/place_cards.dart';
import '../../mechanics/read_clock.dart';
import '../../mechanics/set_clock.dart';
import '../lines.dart';
import '../models.dart';
import '../props.dart';
import 'helpers.dart';

const _gears = 5;

/// Günün akışı yuvası: küçük pencere ve kadran (Durak 6 ile aynı dil).
Widget _hourSlot(BuildContext context, int hour, bool glow) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      DayWindow(
        hour: hour.toDouble(),
        width: 96 * Layout.scale(context),
        height: 64 * Layout.scale(context),
        highlighted: glow,
      ),
      const SizedBox(height: 4),
      SizedBox(
        width: 72 * Layout.scale(context),
        height: 72 * Layout.scale(context),
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

/// Durak 10: Yuva. Kapıdaki büyük saat kilidinin beş dişlisi, önceki
/// durakların beş görevini karışık ister: kur, oku, gün akışı, takvim,
/// dönüşüm. Her dişli dönünce kapı biraz daha açılır; final sinematiği
/// `finale.dart` içinde.
final station10 = Station(
  number: 10,
  title: 'Büyük Saat Kilidi',
  place: 'Yuva',
  scenery: Scenery.summit,
  clockFrame: ClockFrameStyle.gold,
  travelLine: Lines.s10Travel,
  reward: const VagonItem(
      id: 'snowflake', name: 'İlk kar tanesi', icon: Icons.ac_unit),
  intro: const [
    CinematicShot(
      line: Lines.s10Intro,
      mood: PamukMood.thinking,
      duration: Duration(seconds: 6),
      showTrain: false,
    ),
  ],
  scenes: [
    Scene(
      id: 'set',
      build: (context, c) => SetClockMechanic(
        controller: c,
        intro: Lines.s10Set,
        successLine: Lines.s10Gear,
        wrongLine: Lines.s10Wrong,
        draggable: const {ClockHand.hour, ClockHand.minute},
        minuteStep: 5,
        linkHands: true,
        frame: ClockFrameStyle.gold,
        prop: (done, solved) =>
            LockProp(gears: solved == 3 ? 1 : 0, total: _gears, turning: done),
        rounds: [
          SetClockRound(
            target: const ClockTime(5, 0),
            start: const ClockTime(12, 0),
            spokenPrompt: TurkishTime.spoken(const ClockTime(5, 0)),
          ),
          SetClockRound(
            target: const ClockTime(9, 30),
            start: const ClockTime(12, 0),
            spokenPrompt: TurkishTime.spoken(const ClockTime(9, 30)),
          ),
          SetClockRound(
            target: const ClockTime(2, 45),
            start: const ClockTime(12, 0),
            spokenPrompt: TurkishTime.spoken(const ClockTime(2, 45)),
          ),
        ],
      ),
    ),
    Scene(
      id: 'read',
      build: (context, c) => ReadClockMechanic(
        controller: c,
        intro: Lines.s10Read,
        frame: ClockFrameStyle.gold,
        prop: (index) => const LockProp(gears: 1, total: _gears),
        rounds: [
          fullHourRound(const ClockTime(11, 0), seed: 101),
          quarterRound(const ClockTime(6, 15), seed: 102),
          fiveMinuteRound(const ClockTime(3, 40), seed: 103),
        ],
      ),
    ),
    Scene(
      id: 'day',
      build: (context, c) => PlaceCardsMechanic(
        controller: c,
        intro: Lines.s10Day,
        wrongLine: Lines.s6Wrong,
        done: Lines.s10Gear,
        shuffleSeed: 10,
        prop: (last) => const LockProp(gears: 2, total: _gears),
        cards: const [
          PlaceCard(id: 'wake', label: 'Uyanma', icon: Icons.alarm, slotId: '7'),
          PlaceCard(
              id: 'lunch', label: 'Öğle yemeği', icon: Icons.restaurant, slotId: '12'),
          PlaceCard(
              id: 'dinner', label: 'Akşam yemeği', icon: Icons.dinner_dining, slotId: '18'),
          PlaceCard(id: 'sleep', label: 'Uyku', icon: Icons.bedtime, slotId: '21'),
        ],
        slots: [
          for (final hour in const [7, 12, 18, 21])
            PlaceSlot(
              id: '$hour',
              spoken: TurkishTime.spoken24(ClockTime(hour, 0)),
              build: (context, filled, glow) => _hourSlot(context, hour, glow),
            ),
        ],
      ),
    ),
    Scene(
      id: 'calendar',
      build: (context, c) => CalendarMechanic(
        controller: c,
        intro: Lines.s10Calendar,
        hintLine: Lines.s8CalendarHint,
        wrongLine: Lines.s10Wrong,
        done: Lines.s10Gear,
        prop: const LockProp(gears: 3, total: _gears),
        rounds: const [
          CalendarRound(
            month: 11,
            firstWeekday: Week.friday,
            answerDay: 21,
            prompt:
                'Kış yirmi bir Aralık\'ta başlar. Yirmi biri bul; hangi gün?',
            successSpoken: 'Yirmi bir Aralık, Pazar. Kış başlıyor, tam zamanında geldik!',
          ),
        ],
      ),
    ),
    Scene(
      id: 'balance',
      build: (context, c) => BalanceMechanic(
        controller: c,
        intro: Lines.s10Balance,
        overLine: Lines.s9BalanceOver,
        done: Lines.s10Gear,
        prop: const LockProp(gears: 4, total: _gears),
        rounds: const [
          BalanceRound(
            leftLabel: '1 gün',
            leftSpoken: 'bir gün',
            target: 24,
            unitSpoken: 'saat',
            prompt: 'Son dişli: bir gün kaç saat? Kefeye saat koy.',
            pool: [
              BalanceWeight(value: 12, label: '12 saat'),
              BalanceWeight(value: 12, label: '12 saat'),
              BalanceWeight(value: 6, label: '6 saat'),
              BalanceWeight(value: 6, label: '6 saat'),
              BalanceWeight(value: 1, label: '1 saat'),
            ],
          ),
        ],
      ),
    ),
  ],
  outro: const [
    CinematicShot(
      line: Lines.s10Outro,
      mood: PamukMood.happy,
      duration: Duration(seconds: 5),
      showTrain: false,
    ),
  ],
);
