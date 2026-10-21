import 'package:flutter/material.dart';

import '../../../core/clock_time.dart';
import '../../../shared/widgets/clock_drag_logic.dart';
import '../../mechanics/read_clock.dart';
import '../../mechanics/set_clock.dart';
import '../../mechanics/stop_hand.dart';
import '../lines.dart';
import '../models.dart';
import '../props.dart';
import 'helpers.dart';

/// Durak 3: Çarklı Köprü. Buçuk ve çeyrek; buçukta akrep iki sayının ortasında.
/// Dört farklı his: köprüyü indirmek (kur), zili zamanında çalmak (izle),
/// bekçi kedinin sorusu (oku), kapı (iki el birden).
final station3 = Station(
  number: 3,
  title: 'Buçuk ve Çeyrek',
  place: 'Çarklı Köprü',
  scenery: Scenery.bridge,
  clockFrame: ClockFrameStyle.tower,
  travelLine: Lines.s3Travel,
  reward: const VagonItem(
      id: 'bell', name: 'Bekçi kedinin zili', icon: Icons.notifications),
  intro: const [
    CinematicShot(
      line: Lines.s3Intro,
      mood: PamukMood.thinking,
      duration: Duration(seconds: 5),
    ),
  ],
  scenes: [
    Scene(
      id: 'half',
      build: (context, c) => SetClockMechanic(
        controller: c,
        intro: Lines.s3Half,
        successLine: Lines.s3HalfDone,
        wrongLine: Lines.s3Wrong,
        draggable: const {ClockHand.minute},
        minuteStep: 15,
        linkHands: true,
        frame: ClockFrameStyle.tower,
        prop: (done, _) => BridgeProp(down: done),
        rounds: const [
          SetClockRound(
            target: ClockTime(3, 30),
            start: ClockTime(3, 0),
            spokenPrompt: 'Üç buçuk.',
          ),
          SetClockRound(
            target: ClockTime(7, 30),
            start: ClockTime(7, 0),
            spokenPrompt: 'Yedi buçuk.',
          ),
        ],
      ),
    ),
    Scene(
      id: 'bell',
      build: (context, c) => StopHandMechanic(
        controller: c,
        intro: Lines.s3BellIntro,
        frame: ClockFrameStyle.tower,
        rounds: const [
          StopHandRound(target: ClockTime(4, 15), prompt: Lines.s3BellIntro),
          StopHandRound(target: ClockTime(8, 45), prompt: Lines.s3BellTo),
        ],
      ),
    ),
    Scene(
      id: 'read',
      build: (context, c) => ReadClockMechanic(
        controller: c,
        intro: Lines.s3ReadIntro,
        frame: ClockFrameStyle.tower,
        rounds: [
          quarterRound(const ClockTime(2, 0), seed: 4),
          quarterRound(const ClockTime(5, 30), seed: 5),
          quarterRound(const ClockTime(9, 15), seed: 6),
          quarterRound(const ClockTime(10, 45), seed: 7),
        ],
      ),
    ),
    Scene(
      id: 'gate',
      build: (context, c) => SetClockMechanic(
        controller: c,
        intro: Lines.s3GateIntro,
        successLine: Lines.s2GateDone,
        draggable: const {ClockHand.hour, ClockHand.minute},
        minuteStep: 15,
        linkHands: true,
        frame: ClockFrameStyle.tower,
        prop: (done, _) => GateProp(open: done),
        rounds: const [
          SetClockRound(
            target: ClockTime(6, 30),
            start: ClockTime(12, 0),
            spokenPrompt: 'Altı buçuğu kur.',
          ),
        ],
      ),
    ),
  ],
  outro: const [
    CinematicShot(
      line: Lines.s3Outro,
      mood: PamukMood.happy,
      duration: Duration(seconds: 4),
      trainMoving: true,
    ),
  ],
);
