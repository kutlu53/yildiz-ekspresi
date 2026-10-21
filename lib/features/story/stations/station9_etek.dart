import 'package:flutter/material.dart';

import '../../../core/clock_time.dart';
import '../../mechanics/balance.dart';
import '../../mechanics/choose_option.dart';
import '../../mechanics/quick_clock.dart';
import '../lines.dart';
import '../models.dart';
import '../props.dart';
import 'helpers.dart';

const _timetableRows = [
  '2 saat sonra',
  'Yarım gün sonra',
  '1 hafta sonra',
  '1 yıl sonra',
];

/// Durak 9: Kar Dağı Eteği. Birimler arası dönüşüm (1 saat = 60 dk,
/// 1 gün = 24 saat, 1 hafta = 7 gün, 1 yıl = 12 ay) ve hızlı okuma. Üç
/// farklı his: teraziyi dengelemek (terazi), tarifeyi çevirip treni seçmek
/// (seçenek), kar eriyene kadar saatleri okumak (hızlı saat).
final station9 = Station(
  number: 9,
  title: 'Son Tren',
  place: 'Kar Dağı Eteği',
  scenery: Scenery.snowfield,
  clockFrame: ClockFrameStyle.ice,
  travelLine: Lines.s9Travel,
  reward: const VagonItem(id: 'key', name: 'Yuvanın anahtarı', icon: Icons.key),
  intro: const [
    CinematicShot(
      line: Lines.s9Intro,
      mood: PamukMood.thinking,
      duration: Duration(seconds: 6),
    ),
  ],
  scenes: [
    Scene(
      id: 'balance',
      build: (context, c) => BalanceMechanic(
        controller: c,
        intro: Lines.s9BalanceIntro,
        overLine: Lines.s9BalanceOver,
        done: Lines.s9BalanceDone,
        rounds: const [
          BalanceRound(
            leftLabel: '1 saat',
            leftSpoken: 'bir saat',
            target: 60,
            unitSpoken: 'dakika',
            prompt:
                'Sol kefede bir saat var. Sağ kefeye dakika koy; altmış olunca dengelenir.',
            pool: [
              BalanceWeight(value: 10, label: '10 dk'),
              BalanceWeight(value: 10, label: '10 dk'),
              BalanceWeight(value: 10, label: '10 dk'),
              BalanceWeight(value: 10, label: '10 dk'),
              BalanceWeight(value: 10, label: '10 dk'),
              BalanceWeight(value: 10, label: '10 dk'),
              BalanceWeight(value: 5, label: '5 dk'),
              BalanceWeight(value: 5, label: '5 dk'),
            ],
          ),
          BalanceRound(
            leftLabel: '1 gün',
            leftSpoken: 'bir gün',
            target: 24,
            unitSpoken: 'saat',
            prompt: 'Şimdi bir gün. Sağ kefeye saat koy; bir gün kaç saat?',
            pool: [
              BalanceWeight(value: 6, label: '6 saat'),
              BalanceWeight(value: 6, label: '6 saat'),
              BalanceWeight(value: 6, label: '6 saat'),
              BalanceWeight(value: 6, label: '6 saat'),
              BalanceWeight(value: 1, label: '1 saat'),
              BalanceWeight(value: 1, label: '1 saat'),
            ],
          ),
          BalanceRound(
            leftLabel: '1 hafta',
            leftSpoken: 'bir hafta',
            target: 7,
            unitSpoken: 'gün',
            prompt: 'Bir hafta kaç gün? Gün ağırlıklarını koy.',
            pool: [
              BalanceWeight(value: 1, label: '1 gün'),
              BalanceWeight(value: 1, label: '1 gün'),
              BalanceWeight(value: 1, label: '1 gün'),
              BalanceWeight(value: 1, label: '1 gün'),
              BalanceWeight(value: 1, label: '1 gün'),
              BalanceWeight(value: 1, label: '1 gün'),
              BalanceWeight(value: 1, label: '1 gün'),
              BalanceWeight(value: 2, label: '2 gün'),
            ],
          ),
        ],
      ),
    ),
    Scene(
      id: 'timetable',
      build: (context, c) => ChooseOptionMechanic(
        controller: c,
        intro: Lines.s9TimetableIntro,
        hintLine: Lines.s9TimetableHint,
        wrongLine: Lines.s9Wrong,
        done: Lines.s9TimetableDone,
        prop: (round, index, done) =>
            TimetableProp(rows: _timetableRows, highlighted: index, done: done),
        rounds: const [
          ChoiceRound(
            prompt: 'İlk tren iki saat sonra. İki saat kaç dakika?',
            options: [
              ChoiceOption(label: '120 dk', spoken: 'yüz yirmi dakika'),
              ChoiceOption(label: '60 dk', spoken: 'altmış dakika'),
              ChoiceOption(label: '20 dk', spoken: 'yirmi dakika'),
            ],
            correct: 0,
            successSpoken: 'Bir saat altmış, iki saat yüz yirmi dakika!',
          ),
          ChoiceRound(
            prompt: 'İkinci tren yarım gün sonra. Yarım gün kaç saat?',
            options: [
              ChoiceOption(label: '6 saat', spoken: 'altı saat'),
              ChoiceOption(label: '12 saat', spoken: 'on iki saat'),
              ChoiceOption(label: '30 saat', spoken: 'otuz saat'),
            ],
            correct: 1,
            successSpoken: 'Bir gün yirmi dört saat, yarısı on iki saat!',
          ),
          ChoiceRound(
            prompt: 'Üçüncü tren bir hafta sonra. Bir hafta kaç gün?',
            options: [
              ChoiceOption(label: '5 gün', spoken: 'beş gün'),
              ChoiceOption(label: '10 gün', spoken: 'on gün'),
              ChoiceOption(label: '7 gün', spoken: 'yedi gün'),
            ],
            correct: 2,
            successSpoken: 'Bir hafta yedi gün. Çok geç, kar yağar!',
          ),
          ChoiceRound(
            prompt: 'Son tren bir yıl sonra! Bir yıl kaç ay?',
            options: [
              ChoiceOption(label: '12 ay', spoken: 'on iki ay'),
              ChoiceOption(label: '10 ay', spoken: 'on ay'),
              ChoiceOption(label: '24 ay', spoken: 'yirmi dört ay'),
            ],
            correct: 0,
            successSpoken:
                'Bir yıl on iki ay. O zamana kadar uyurum! İki saat sonrakine bineriz.',
          ),
        ],
      ),
    ),
    Scene(
      id: 'quick',
      build: (context, c) => QuickClockMechanic(
        controller: c,
        intro: Lines.s9QuickIntro,
        lateLine: Lines.s9QuickLate,
        done: Lines.s9QuickDone,
        frame: ClockFrameStyle.ice,
        rounds: [
          fullHourRound(const ClockTime(7, 0), seed: 91),
          quarterRound(const ClockTime(2, 30), seed: 92),
          fiveMinuteRound(const ClockTime(4, 20), seed: 93),
          quarterRound(const ClockTime(9, 45), seed: 94),
          fullHourRound(const ClockTime(12, 0), seed: 95),
          fiveMinuteRound(const ClockTime(6, 50), seed: 96),
          quarterRound(const ClockTime(11, 15), seed: 97),
          fiveMinuteRound(const ClockTime(8, 35), seed: 98),
        ],
      ),
    ),
  ],
  outro: const [
    CinematicShot(
      line: Lines.s9Outro,
      mood: PamukMood.happy,
      duration: Duration(seconds: 4),
      trainMoving: true,
    ),
  ],
);
