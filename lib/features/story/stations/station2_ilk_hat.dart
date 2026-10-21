import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/clock_time.dart';
import '../../../shared/widgets/draggable_clock.dart';
import '../../../shared/widgets/scenery_view.dart';
import '../../mechanics/choose_option.dart';
import '../../mechanics/read_clock.dart';
import '../../mechanics/set_clock.dart';
import '../lines.dart';
import '../models.dart';
import '../stages.dart';
import 'helpers.dart';

const _yesNo = [
  ChoiceOption(label: 'Doğru', spoken: 'doğru'),
  ChoiceOption(label: 'Yanlış', spoken: 'yanlış'),
];

Widget _postClock(ClockTime time) => SizedBox(
      width: 240,
      height: 240,
      child: ClockFrame(
        style: ClockFrameStyle.post,
        child: DraggableClock(time: time, draggable: const {}),
      ),
    );

/// Durak 2: İlk Hat. Tam saatler; yelkovan 12'de, akrep sayıyı gösterir.
/// Dört farklı his: saati kurup büyük kolu çekmek (tren kalkar), manevra
/// yapan yük treninin vagonlarından doğrusuna dokunmak (oku), Pamuk'un
/// tahminini doğrulamak ya da düzeltmek (karar), kapıyı açıp tüneli geçmek.
final station2 = Station(
  number: 2,
  title: 'Tren Tam Saatte Kalkar',
  place: 'İlk Hat',
  scenery: Scenery.track,
  clockFrame: ClockFrameStyle.cab,
  travelLine: Lines.s2Travel,
  reward: const VagonItem(
      id: 'scarf', name: 'Pamuk\'un atkısı', icon: Icons.checkroom),
  intro: const [
    CinematicShot(
      line: Lines.s2Intro,
      mood: PamukMood.thinking,
      duration: Duration(seconds: 5),
    ),
  ],
  scenes: [
    Scene(
      id: 'lever',
      build: (context, c) {
        final departed = Completer<void>();
        return SetClockMechanic(
          controller: c,
          intro: Lines.s2Lever,
          successLine: Lines.s2LeverDone,
          wrongLine: Lines.s2Wrong,
          draggable: const {ClockHand.hour},
          frame: ClockFrameStyle.cab,
          afterSuccess: () => departed.future,
          stage: (context, clock, view) => CabStage(
            clock: clock,
            boardText: '8',
            armed: view.done,
            onStuck: () => c.say(Lines.s2LeverStuck),
            onPulled: () => c.say(Lines.s2Pulled),
            onDeparted: () {
              if (!departed.isCompleted) departed.complete();
            },
          ),
          rounds: const [
            SetClockRound(
              target: ClockTime(8, 0),
              start: ClockTime(12, 0),
              spokenPrompt: 'Saat sekiz.',
            ),
          ],
        );
      },
    ),
    Scene(
      id: 'read',
      build: (context, c) => ReadClockMechanic(
        controller: c,
        intro: Lines.s2ReadIntro,
        hintLine: Lines.s2ReadHint,
        frame: ClockFrameStyle.post,
        stage: (context, clock, options, round) =>
            WagonSigns(clock: clock, options: options),
        rounds: [
          fullHourRound(const ClockTime(3, 0), seed: 1),
          fullHourRound(const ClockTime(11, 0), seed: 2),
        ],
      ),
    ),
    Scene(
      id: 'guess',
      build: (context, c) => ChooseOptionMechanic(
        controller: c,
        intro: Lines.s2GuessIntro,
        hintLine: Lines.s2ReadHint,
        wrongLine: Lines.s2Wrong,
        done: Lines.s2GuessDone,
        prop: (round, index, done) =>
            _postClock(const [ClockTime(5, 0), ClockTime(9, 0)][index]),
        rounds: const [
          ChoiceRound(
            prompt: 'Bence saat beş. Doğru mu?',
            options: _yesNo,
            correct: 0,
            successSpoken: 'Evet! Akrep beşte, saat beş. Öğreniyorum!',
          ),
          ChoiceRound(
            prompt: 'Bence saat on. Doğru mu?',
            options: _yesNo,
            correct: 1,
            successSpoken:
                'Haklısın, yanılmışım. Akrep dokuzda: saat dokuz. Sen daha iyi biliyorsun!',
          ),
        ],
      ),
    ),
    Scene(
      id: 'gate',
      build: (context, c) {
        final entered = Completer<void>();
        return SetClockMechanic(
          controller: c,
          intro: Lines.s2GateIntro,
          successLine: Lines.s2GateDone,
          draggable: const {ClockHand.hour},
          frame: ClockFrameStyle.tower,
          afterSuccess: () => entered.future,
          stage: (context, clock, view) => GateStage(
            clock: clock,
            open: view.done,
            onEntered: () {
              if (!entered.isCompleted) entered.complete();
            },
          ),
          rounds: const [
            SetClockRound(
              target: ClockTime(3, 0),
              start: ClockTime(12, 0),
              spokenPrompt: 'Saat üçü göster.',
            ),
          ],
        );
      },
    ),
  ],
  outro: const [
    CinematicShot(
      line: Lines.s2Outro,
      mood: PamukMood.happy,
      duration: Duration(seconds: 4),
      trainMoving: true,
    ),
  ],
);
