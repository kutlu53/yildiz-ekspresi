import 'package:flutter/material.dart';

import '../../../core/clock_time.dart';
import '../../../shared/widgets/clock_drag_logic.dart';
import '../../mechanics/attach_hands.dart';
import '../../mechanics/count_minutes.dart';
import '../../mechanics/tap_hand.dart';
import '../lines.dart';
import '../models.dart';

/// Durak 1: Garaj. Akrep kısa ve saati, yelkovan uzun ve dakikayı gösterir.
final station1 = Station(
  number: 1,
  title: 'Elleri Tak',
  place: 'Garaj',
  scenery: Scenery.garage,
  clockFrame: ClockFrameStyle.cab,
  travelLine: Lines.s1Travel,
  reward: const VagonItem(
      id: 'pocket_watch', name: 'Pamuk\'un cep saati', icon: Icons.watch),
  intro: const [
    CinematicShot(
      line: Lines.s1Intro,
      mood: PamukMood.thinking,
      duration: Duration(seconds: 4),
    ),
  ],
  scenes: [
    Scene(
      id: 'attach',
      build: (context, c) => AttachHandsMechanic(controller: c),
    ),
    Scene(
      id: 'tap',
      build: (context, c) => TapHandMechanic(
        controller: c,
        intro: Lines.s1TapIntro,
        time: const ClockTime(3, 0),
        rounds: const [ClockHand.hour, ClockHand.minute, ClockHand.hour],
      ),
    ),
    Scene(
      id: 'turn',
      build: (context, c) => CountMinutesMechanic(
        controller: c,
        start: const ClockTime(3, 0),
        step: 5,
        speakCounts: false,
        linkHands: true,
        intro: Lines.s1Turn,
        done: Lines.s1TurnDone,
      ),
    ),
  ],
  outro: const [
    CinematicShot(
      line: Lines.s1Outro,
      mood: PamukMood.happy,
      duration: Duration(seconds: 4),
      trainMoving: true,
    ),
  ],
);
