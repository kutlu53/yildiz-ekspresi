import 'package:flutter/material.dart';

import '../../../core/clock_time.dart';
import '../../../core/turkish_time.dart';
import '../../../shared/widgets/clock_drag_logic.dart';
import '../../mechanics/mechanic_frame.dart';
import '../../mechanics/pick_clock.dart';
import '../../mechanics/set_clock.dart';
import '../lines.dart';
import '../models.dart';
import '../props.dart';
import 'helpers.dart';

SetClockRound _spokenRound(ClockTime target, {Line? lead}) => SetClockRound(
      target: target,
      start: const ClockTime(12, 0),
      spokenPrompt: TurkishTime.spoken(target),
      lead: lead,
    );

/// Durak 5: Büyük İstasyon. Saat ve dakikayı birlikte okuma ve kurma,
/// sözlü ifadeler, dijital-analog eşleme. Dört farklı his: panodaki dijital
/// saati kadrana kurmak (kur, önce 5'er sonra 1'er), biletle peron saatini
/// eşlemek (eşleştir), kondüktörün sözlü saatini kurmak (kur, iki el),
/// kapı (5'er dakika; kamera eşdeğeri Faz 2'de).
final station5 = Station(
  number: 5,
  title: 'Yedi Kırk Sekiz',
  place: 'Büyük İstasyon',
  scenery: Scenery.hall,
  clockFrame: ClockFrameStyle.gold,
  travelLine: Lines.s5Travel,
  reward: const VagonItem(
      id: 'ticket', name: 'Bilet', icon: Icons.confirmation_number),
  intro: const [
    CinematicShot(
      line: Lines.s5Intro,
      mood: PamukMood.happy,
      duration: Duration(seconds: 6),
    ),
  ],
  scenes: [
    Scene(
      id: 'board',
      build: (context, c) => SetClockMechanic(
        controller: c,
        intro: Lines.s5BoardIntro,
        successLine: Lines.s5BoardDone,
        wrongLine: Lines.s5Wrong,
        numeralsHint: Lines.s5BoardHint,
        draggable: const {ClockHand.hour, ClockHand.minute},
        minuteStep: 5,
        linkHands: true,
        frame: ClockFrameStyle.gold,
        roundProp: (round, done) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DigitalBoard(text: round.target.digital12),
            const SizedBox(width: 16),
            LeverProp(down: done),
          ],
        ),
        rounds: const [
          SetClockRound(
            target: ClockTime(3, 25),
            start: ClockTime(12, 0),
            spokenPrompt: 'Üç, yirmi beş.',
          ),
          SetClockRound(
            target: ClockTime(10, 40),
            start: ClockTime(12, 0),
            spokenPrompt: 'On, kırk.',
          ),
          SetClockRound(
            target: ClockTime(7, 48),
            start: ClockTime(7, 45),
            minuteStep: 1,
            lead: Lines.s5BoardFine,
            spokenPrompt: 'Yedi, kırk sekiz.',
          ),
          SetClockRound(
            target: ClockTime(1, 52),
            start: ClockTime(1, 50),
            minuteStep: 1,
            spokenPrompt: 'Bir, elli iki.',
          ),
        ],
      ),
    ),
    Scene(
      id: 'platform',
      build: (context, c) => PickClockMechanic(
        controller: c,
        intro: Lines.s5PlatformIntro,
        hintLine: Lines.s5PlatformHint,
        successLine: Lines.s5PlatformDone,
        frame: ClockFrameStyle.post,
        prop: (round) => TicketProp(text: round.target.digital12),
        rounds: [
          digitalRound(const ClockTime(3, 25), seed: 11),
          digitalRound(const ClockTime(9, 10), seed: 12),
          digitalRound(const ClockTime(7, 48), seed: 13),
        ],
      ),
    ),
    Scene(
      id: 'spoken',
      build: (context, c) => SetClockMechanic(
        controller: c,
        intro: Lines.s5SpokenIntro,
        successLine: Lines.s5SpokenDone,
        wrongLine: Lines.s5Wrong,
        draggable: const {ClockHand.hour, ClockHand.minute},
        minuteStep: 5,
        linkHands: true,
        frame: ClockFrameStyle.gold,
        prop: (done, _) => DoorProp(open: done),
        rounds: [
          _spokenRound(const ClockTime(8, 45)), // dokuza çeyrek var
          _spokenRound(const ClockTime(2, 20)), // ikiyi yirmi geçiyor
          _spokenRound(const ClockTime(4, 50)), // beşe on var
        ],
      ),
    ),
    Scene(
      id: 'gate',
      build: (context, c) => SetClockMechanic(
        controller: c,
        intro: Lines.s5GateIntro,
        successLine: Lines.s2GateDone,
        draggable: const {ClockHand.hour, ClockHand.minute},
        minuteStep: 5,
        linkHands: true,
        frame: ClockFrameStyle.tower,
        prop: (done, _) => GateProp(open: done),
        rounds: const [
          SetClockRound(
            target: ClockTime(4, 20),
            start: ClockTime(12, 0),
            spokenPrompt: 'Dördü yirmi geçeyi kur.',
          ),
        ],
      ),
    ),
  ],
  outro: const [
    CinematicShot(
      line: Lines.s5Outro,
      mood: PamukMood.happy,
      duration: Duration(seconds: 4),
      trainMoving: true,
    ),
  ],
);
