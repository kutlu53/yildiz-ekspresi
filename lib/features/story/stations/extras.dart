import 'package:flutter/material.dart';

import '../../../core/clock_time.dart';
import '../../../shared/widgets/clock_drag_logic.dart';
import '../../mechanics/quick_clock.dart';
import '../../mechanics/read_clock.dart';
import '../../mechanics/set_clock.dart';
import '../lines.dart';
import '../models.dart';
import '../props.dart';
import 'helpers.dart';

/// Oyun sonu modu: haritadan bağımsız açılan iki kısa "durak". Hikâye
/// ilerlemesine sayılmaz, ödül vermez; sınıf modunda tekrar için kullanılır.

/// Hızlı Saat: her açılışta farklı on saat (tam, çeyrek, 5'er karışık).
Station quickClockStation({int? seed}) {
  final s = seed ?? DateTime.now().millisecondsSinceEpoch;
  final rounds = <ReadClockRound>[];
  for (var i = 0; i < 10; i++) {
    final h = (s ~/ (i + 1) + i * 5) % 12;
    final t = (s + i * 7) % 3;
    rounds.add(switch (t) {
      0 => fullHourRound(ClockTime(h, 0), seed: s + i),
      1 => quarterRound(ClockTime(h, [0, 15, 30, 45][(s + i) % 4]), seed: s + i),
      _ => fiveMinuteRound(ClockTime(h, ((s + i * 3) % 12) * 5), seed: s + i),
    });
  }
  return Station(
    number: 11,
    title: 'Hızlı Saat',
    place: 'Kar Bulutu',
    scenery: Scenery.snowfield,
    clockFrame: ClockFrameStyle.ice,
    travelLine: Lines.extraQuickIntro,
    reward: const VagonItem(
        id: 'extra_quick', name: 'Kar tanesi', icon: Icons.ac_unit),
    intro: const [
      CinematicShot(
        line: Lines.extraQuickIntro,
        mood: PamukMood.happy,
        duration: Duration(seconds: 4),
      ),
    ],
    scenes: [
      Scene(
        id: 'quick',
        build: (context, c) => QuickClockMechanic(
          controller: c,
          lateLine: Lines.s9QuickLate,
          done: Lines.extraQuickDone,
          frame: ClockFrameStyle.ice,
          rounds: rounds,
        ),
      ),
    ],
    outro: const [
      CinematicShot(
        line: Lines.extraBye,
        mood: PamukMood.happy,
        duration: Duration(seconds: 3),
      ),
    ],
  );
}

/// Zaman Kapıları: üç kapı art arda (tam saat, buçuk, 5'er dakika).
/// Bu sürükleme eşdeğeridir; kamera modu Faz 2'de aynı kapıları açacak.
final timeGatesStation = Station(
  number: 12,
  title: 'Zaman Kapıları',
  place: 'Kapılar',
  scenery: Scenery.tunnel,
  clockFrame: ClockFrameStyle.tower,
  travelLine: Lines.extraGatesIntro,
  reward: const VagonItem(
      id: 'extra_gates', name: 'Kapı anahtarı', icon: Icons.door_sliding),
  intro: const [
    CinematicShot(
      line: Lines.extraGatesIntro,
      mood: PamukMood.thinking,
      duration: Duration(seconds: 4),
    ),
  ],
  scenes: [
    Scene(
      id: 'gates',
      build: (context, c) => SetClockMechanic(
        controller: c,
        successLine: Lines.s2GateDone,
        draggable: const {ClockHand.hour, ClockHand.minute},
        minuteStep: 5,
        linkHands: true,
        frame: ClockFrameStyle.tower,
        prop: (done, _) => GateProp(open: done),
        rounds: const [
          SetClockRound(
            target: ClockTime(3, 0),
            start: ClockTime(12, 0),
            spokenPrompt: 'Birinci kapı: saat üçü göster.',
          ),
          SetClockRound(
            target: ClockTime(6, 30),
            start: ClockTime(12, 0),
            spokenPrompt: 'İkinci kapı: altı buçuğu göster.',
          ),
          SetClockRound(
            target: ClockTime(4, 20),
            start: ClockTime(12, 0),
            spokenPrompt: 'Üçüncü kapı: dördü yirmi geçeyi göster.',
          ),
        ],
      ),
    ),
  ],
  outro: const [
    CinematicShot(
      line: Lines.extraBye,
      mood: PamukMood.happy,
      duration: Duration(seconds: 3),
    ),
  ],
);
