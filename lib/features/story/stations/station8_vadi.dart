import 'package:flutter/material.dart';

import '../../../core/turkish_time.dart';
import '../../../core/week.dart';
import '../../../core/year.dart';
import '../../../shared/widgets/knuckle_hills.dart';
import '../../../shared/widgets/season_window.dart';
import '../../mechanics/calendar.dart';
import '../../mechanics/choose_option.dart';
import '../../mechanics/mechanic_frame.dart';
import '../../mechanics/place_cards.dart';
import '../../mechanics/stone_path.dart';
import '../lines.dart';
import '../models.dart';

const _dayOptions = [
  ChoiceOption(label: '31', spoken: 'otuz bir gün'),
  ChoiceOption(label: '30', spoken: 'otuz gün'),
  ChoiceOption(label: '28', spoken: 'yirmi sekiz gün'),
];

ChoiceRound _houseRound(int month) {
  final days = Year.daysIn(month);
  final correct = days == 31 ? 0 : (days == 30 ? 1 : 2);
  final where = month == 1
      ? 'en küçük ev'
      : Year.onKnuckle(month)
          ? 'tepede'
          : 'çukurda';
  return ChoiceRound(
    prompt: '${Year.name(month)} kasabası. Tepede mi, çukurda mi? Kaç gün?',
    options: _dayOptions,
    correct: correct,
    successSpoken:
        '${Year.name(month)} $where: ${TurkishTime.number(days)} gün.',
  );
}

IconData _seasonIcon(int season) => switch (season) {
      Year.spring => Icons.local_florist,
      Year.summer => Icons.wb_sunny,
      Year.autumn => Icons.eco,
      _ => Icons.ac_unit,
    };

Widget _wagonSlot(int season, bool filled, bool glow) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: glow
          ? const Color(0xFFFFF59D)
          : filled
              ? const Color(0xFFC8E6C9)
              : const Color(0xFF8D6E63),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: glow ? const Color(0xFFFFD54F) : const Color(0xFF4E342E),
        width: glow ? 5 : 3,
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_seasonIcon(season),
            size: 30,
            color: glow || filled ? const Color(0xFF263238) : Colors.white),
        Text(
          Year.seasons[season],
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: glow || filled ? const Color(0xFF263238) : Colors.white,
          ),
        ),
      ],
    ),
  );
}

/// Durak 8: Mevsim Vadisi. Yıl 12 aydır, ayların adı ve sırası, gün sayıları
/// (31/30/28), mevsimler, takvim okuma. Dört farklı his: kasabaları sırayla
/// geçmek (taş yolu, 12 tabela), yumruk tepelerinde evin gün sayısını seçmek
/// (seçenek), ay kartlarını mevsim vagonlarına yüklemek (kart yerleştir),
/// takvim panosunda tarih bulmak (takvim).
final station8 = Station(
  number: 8,
  title: 'On İki Kasaba',
  place: 'Mevsim Vadisi',
  scenery: Scenery.valley,
  clockFrame: ClockFrameStyle.post,
  travelLine: Lines.s8Travel,
  reward: const VagonItem(
      id: 'leaves', name: 'Dört mevsimden birer yaprak', icon: Icons.eco),
  intro: const [
    CinematicShot(
      line: Lines.s8Intro,
      mood: PamukMood.thinking,
      duration: Duration(seconds: 6),
    ),
  ],
  scenes: [
    Scene(
      id: 'towns',
      build: (context, c) => StonePathMechanic(
        controller: c,
        mode: StoneMode.walk,
        labels: Year.months,
        unit: 'ay',
        intro: Lines.s8TownsIntro,
        hintLine: Lines.s8TownsHint,
        wrongLine: Lines.s8Wrong,
        done: Lines.s8TownsDone,
        prop: (round, done) =>
            WoodenSign(text: '12 ay', highlighted: done),
        rounds: const [
          StoneRound(
            start: 0,
            steps: 12,
            prompt:
                'Ocak kasabasındayız. Sıradaki kasabaya geç, ayları sayalım.',
            successSpoken:
                'On iki kasaba, on iki ay: bir yıl! Aralık\'tan sonra yine Ocak gelir.',
          ),
        ],
      ),
    ),
    Scene(
      id: 'houses',
      build: (context, c) => ChooseOptionMechanic(
        controller: c,
        intro: Lines.s8HousesIntro,
        hintLine: Lines.s8HousesHint,
        wrongLine: Lines.s8Wrong,
        done: Lines.s8HousesDone,
        prop: (round, index, done) => KnuckleHills(
          highlight: const [0, 3, 1, 6, 7, 10][index],
          reveal: done,
        ),
        rounds: [
          for (final m in const [0, 3, 1, 6, 7, 10]) _houseRound(m),
        ],
      ),
    ),
    Scene(
      id: 'wagons',
      build: (context, c) => PlaceCardsMechanic(
        controller: c,
        intro: Lines.s8WagonsIntro,
        wrongLine: Lines.s8WagonsWrong,
        done: Lines.s8WagonsDone,
        shuffleSeed: 8,
        prop: (last) =>
            SeasonWindow(season: last == null ? null : int.parse(last.id)),
        cards: [
          for (var m = 0; m < 12; m++)
            PlaceCard(
              id: 'm$m',
              label: Year.name(m),
              icon: Icons.calendar_month,
              slotId: '${Year.seasonOf(m)}',
            ),
        ],
        slots: [
          for (var s = 0; s < 4; s++)
            PlaceSlot(
              id: '$s',
              spoken: Year.seasons[s].toLowerCase(),
              capacity: 3,
              build: (context, filled, glow) => _wagonSlot(s, filled, glow),
            ),
        ],
      ),
    ),
    Scene(
      id: 'calendar',
      build: (context, c) => CalendarMechanic(
        controller: c,
        intro: Lines.s8CalendarIntro,
        hintLine: Lines.s8CalendarHint,
        wrongLine: Lines.s8Wrong,
        done: Lines.s8CalendarDone,
        rounds: const [
          CalendarRound(
            month: 2,
            firstWeekday: Week.sunday,
            answerDay: 14,
            prompt:
                'Benim doğum günüm on dört Mart. Takvimde on dördü bul, dokun.',
            successSpoken:
                'On dört Mart, Cumartesi! Doğum günüm Cumartesi\'ye geliyor.',
          ),
          CalendarRound(
            month: 10,
            firstWeekday: Week.wednesday,
            answerDay: 6,
            prompt:
                'Kasım\'da pazar ilk Pazartesi kurulur. Kasım\'ın ilk Pazartesi\'si kaçı?',
            successSpoken: 'Altı Kasım, ilk Pazartesi. Pazar o gün!',
          ),
          CalendarRound(
            month: 1,
            firstWeekday: Week.monday,
            answerDay: 28,
            prompt: 'Şubat\'ın son gününe dokun. Şubat kaç gün çeker?',
            successSpoken:
                'Yirmi sekiz Şubat, Pazar. Şubat yirmi sekiz gün, en kısa ay!',
          ),
        ],
      ),
    ),
  ],
  outro: const [
    CinematicShot(
      line: Lines.s8Outro,
      mood: PamukMood.happy,
      duration: Duration(seconds: 4),
      trainMoving: true,
    ),
  ],
);
