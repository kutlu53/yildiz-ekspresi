import 'package:flutter/material.dart';

import '../../../core/clock_time.dart';
import '../../../shared/widgets/clock_drag_logic.dart';
import '../../mechanics/count_minutes.dart';
import '../../mechanics/set_clock.dart';
import '../lines.dart';
import '../models.dart';
import '../props.dart';

/// Durak 4: Fener Tüneli. Yelkovanı 5'er dakika sayma, sonra 1'er dakika;
/// 60 dakika = 1 saat. Üç farklı his: fener parlasın diye sayarak döndürmek
/// (say), yağ saatini söylenen dakikaya kurmak (kur, 5'er), damla saatinde
/// "üç dakika daha" gibi ince ayar (kur, 1'er).
final station4 = Station(
  number: 4,
  title: 'Beşer Beşer',
  place: 'Fener Tüneli',
  scenery: Scenery.tunnel,
  clockFrame: ClockFrameStyle.lantern,
  travelLine: Lines.s4Travel,
  reward: const VagonItem(id: 'lantern', name: 'Fener', icon: Icons.light),
  intro: const [
    CinematicShot(
      line: Lines.s4Intro,
      mood: PamukMood.thinking,
      duration: Duration(seconds: 6),
    ),
  ],
  scenes: [
    Scene(
      id: 'count',
      build: (context, c) => CountMinutesMechanic(
        controller: c,
        start: const ClockTime(9, 0),
        step: 5,
        speakCounts: true,
        linkHands: true,
        frame: ClockFrameStyle.lantern,
        intro: Lines.s4Count,
        done: Lines.s4CountDone,
        prop: (elapsed, finished) =>
            LanternProp(lit: elapsed > 0 || finished, level: elapsed / 60),
      ),
    ),
    Scene(
      id: 'set',
      build: (context, c) => SetClockMechanic(
        controller: c,
        intro: Lines.s4SetIntro,
        successLine: Lines.s4SetDone,
        wrongLine: Lines.s4Wrong,
        numeralsHint: Lines.s4SetHint,
        draggable: const {ClockHand.minute},
        minuteStep: 5,
        linkHands: true,
        frame: ClockFrameStyle.lantern,
        prop: (done, solved) => LanternProp(lit: done, level: solved / 3),
        rounds: const [
          SetClockRound(
            target: ClockTime(2, 20),
            start: ClockTime(2, 0),
            spokenPrompt: 'Yirmi dakika geçiyor. Yelkovanı yirmiye getir.',
          ),
          SetClockRound(
            target: ClockTime(5, 45),
            start: ClockTime(5, 0),
            spokenPrompt: 'Kırk beş dakika geçiyor. Yelkovanı kırk beşe getir.',
          ),
          SetClockRound(
            target: ClockTime(8, 35),
            start: ClockTime(8, 0),
            spokenPrompt: 'Otuz beş dakika geçiyor.',
          ),
        ],
      ),
    ),
    Scene(
      id: 'drip',
      build: (context, c) => SetClockMechanic(
        controller: c,
        intro: Lines.s4DripIntro,
        successLine: Lines.s4DripDone,
        wrongLine: Lines.s4Wrong,
        draggable: const {ClockHand.minute},
        minuteStep: 1,
        linkHands: true,
        frame: ClockFrameStyle.lantern,
        timeProp: (time, start, done) => DripClockProp(
          drops: (time.minutesSinceMidnight - start.minutesSinceMidnight + 720) %
              720,
          done: done,
        ),
        rounds: const [
          SetClockRound(
            target: ClockTime(4, 3),
            start: ClockTime(4, 0),
            spokenPrompt: 'Üç damla, üç dakika. Yelkovanı üç küçük çizgi ilerlet.',
          ),
          SetClockRound(
            target: ClockTime(6, 17),
            start: ClockTime(6, 15),
            spokenPrompt: 'İki dakika daha. Yelkovanı iki çizgi ilerlet.',
          ),
          SetClockRound(
            target: ClockTime(10, 34),
            start: ClockTime(10, 30),
            spokenPrompt: 'Dört dakika daha.',
          ),
        ],
      ),
    ),
  ],
  outro: const [
    CinematicShot(
      line: Lines.s4Outro,
      mood: PamukMood.happy,
      duration: Duration(seconds: 4),
      trainMoving: true,
    ),
  ],
);
