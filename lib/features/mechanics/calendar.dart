import 'package:flutter/material.dart';

import '../../core/turkish_time.dart';
import '../../core/week.dart';
import '../../core/year.dart';
import '../story/lines.dart';
import '../story/models.dart';
import 'hint_ladder.dart';
import 'mechanic_frame.dart';

class CalendarRound {
  final int month;

  /// Ayın 1'inin haftanın hangi günü olduğu (0 Pazartesi).
  final int firstWeekday;

  /// Dokunulması gereken gün (1'den başlar).
  final int answerDay;
  final String prompt;

  /// Doğru dokunuşta okunacak açıklama; verilmezse "on dört Mart, Cumartesi".
  final String? successSpoken;

  const CalendarRound({
    required this.month,
    required this.firstWeekday,
    required this.answerDay,
    required this.prompt,
    this.successSpoken,
  });

  int get answerWeekday =>
      Year.weekdayOf(firstWeekday: firstWeekday, day: answerDay);
}

/// Takvim: ay sayfası gösterilir, soru sorulur ("14 Mart hangi gün?",
/// "ilk Pazartesi kaçı?"), çocuk doğru güne dokunur. Dokunulan gün sesle
/// okunur; doğruysa hücre ve sütunu parlar, tarih ve günü söylenir.
/// Yardım: önce ipucu, sonra satır ve sütun parlar, en son hücre gösterilir.
class CalendarMechanic extends StatefulWidget {
  final SceneController controller;
  final List<CalendarRound> rounds;
  final Line? intro;
  final Line? hintLine;
  final Line? wrongLine;
  final Line? done;

  /// Dünyadaki nesne (kilit gibi), ay tabelasının yanında.
  final Widget? prop;

  const CalendarMechanic({
    super.key,
    required this.controller,
    required this.rounds,
    this.intro,
    this.hintLine,
    this.wrongLine,
    this.done,
    this.prop,
  });

  @override
  State<CalendarMechanic> createState() => _CalendarMechanicState();
}

class _CalendarMechanicState extends State<CalendarMechanic> {
  final _ladder = HintLadder();
  int _round = 0;
  int _celebrate = 0;
  bool _busy = false;
  bool _done = false;
  int? _lastWrong;

  CalendarRound get _current => widget.rounds[_round];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _announce(first: true));
  }

  Future<void> _announce({bool first = false}) async {
    if (first && widget.intro != null) await widget.controller.say(widget.intro!);
    if (!mounted) return;
    await widget.controller.sayText(_current.prompt);
  }

  Future<void> _tap(int day) async {
    if (_busy || _done) return;
    setState(() => _busy = true);
    await widget.controller.sayText(TurkishTime.number(day));
    if (!mounted) return;

    if (day == _current.answerDay) {
      setState(() {
        _done = true;
        _celebrate++;
      });
      await widget.controller.sayText(_current.successSpoken ??
          '${Year.dateSpoken(day, _current.month)}, '
              '${Week.name(_current.answerWeekday)}!');
      if (!mounted) return;
      if (_round + 1 < widget.rounds.length) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        setState(() {
          _round++;
          _ladder.reset();
          _done = false;
          _busy = false;
          _lastWrong = null;
        });
        await _announce();
      } else {
        await widget.controller.say(widget.done ?? Lines.wellDone);
        if (mounted) widget.controller.complete();
      }
      return;
    }

    widget.controller.mistake();
    setState(() {
      _ladder.fail();
      _lastWrong = day;
    });
    switch (_ladder.level) {
      case 1:
        await widget.controller.say(widget.wrongLine ?? Lines.notYet);
      case 2:
        await widget.controller.say(widget.hintLine ?? Lines.tryAgain);
      default:
        await widget.controller.say(Lines.showYou);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final r = _current;
    final total = Year.daysIn(r.month);
    final leading = r.firstWeekday;
    final rows = ((leading + total) / 7).ceil();
    final answerRow = (leading + r.answerDay - 1) ~/ 7;
    final glowGuides = _ladder.level >= 2 && !_done;
    final showCell = (_ladder.showAnswer || _done);

    return MechanicFrame(
      celebrate: _celebrate,
      header: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.prop != null) ...[widget.prop!, const SizedBox(width: 16)],
          WoodenSign(text: Year.name(r.month), highlighted: _done),
        ],
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 7 / (rows + 1) * 1.1,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF8D6E63), width: 4),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    for (var d = 0; d < 7; d++)
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: (glowGuides || _done) && d == r.answerWeekday
                                ? const Color(0xFFFFD54F)
                                : d >= 5
                                    ? const Color(0xFFFFCCBC)
                                    : const Color(0xFFB3E5FC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            Week.names[d].substring(0, 3),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF263238),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                for (var row = 0; row < rows; row++)
                  Expanded(
                    child: Row(
                      children: [
                        for (var col = 0; col < 7; col++)
                          Expanded(
                            child: _cell(
                              day: row * 7 + col - leading + 1,
                              total: total,
                              rowGlow: glowGuides && row == answerRow,
                              colGlow: glowGuides && col == r.answerWeekday,
                              showCell: showCell,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cell({
    required int day,
    required int total,
    required bool rowGlow,
    required bool colGlow,
    required bool showCell,
  }) {
    if (day < 1 || day > total) return const SizedBox.shrink();
    final isAnswer = day == _current.answerDay;
    final highlight = showCell && isAnswer;
    final wrong = _lastWrong == day && !_done;
    return GestureDetector(
      key: ValueKey('cal-$day'),
      behavior: HitTestBehavior.opaque,
      onTap: () => _tap(day),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: highlight
              ? const Color(0xFFFFB300)
              : (rowGlow || colGlow)
                  ? const Color(0xFFFFF59D)
                  : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: wrong ? const Color(0xFFE53935) : const Color(0xFFBCAAA4),
            width: wrong ? 3 : 1.5,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$day',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF263238),
            ),
          ),
        ),
      ),
    );
  }
}
