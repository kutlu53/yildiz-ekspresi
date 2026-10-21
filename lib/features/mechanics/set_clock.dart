import 'package:flutter/material.dart';

import '../../core/clock_time.dart';
import '../../shared/widgets/draggable_clock.dart';
import '../../shared/widgets/scenery_view.dart';
import '../story/lines.dart';
import '../story/models.dart';
import 'hint_ladder.dart';
import 'mechanic_frame.dart';

/// Bir "Saati Kur" turu: hedef, başlangıç ve sesli istem.
class SetClockRound {
  final ClockTime target;
  final ClockTime start;
  final String spokenPrompt;

  /// Bu tura özel dakika adımı; verilmezse mekaniğin adımı kullanılır
  /// (önce 5'er, sonra 1'er dakika gibi geçişler için).
  final int? minuteStep;

  /// Tur başında okunan ek replik (ör. "şimdi tek tek dakikalar").
  final Line? lead;

  const SetClockRound({
    required this.target,
    required this.start,
    required this.spokenPrompt,
    this.minuteStep,
    this.lead,
  });
}

/// Sahne yerleşimine verilen durum: tur bitti mi, kaçıncı tur, hedef.
class SetClockView {
  final bool done;
  final int round;
  final SetClockRound current;

  const SetClockView({
    required this.done,
    required this.round,
    required this.current,
  });
}

/// Saati Kur: hedef verilir, çocuk eli sürükleyip bırakır. Onay düğmesi yok:
/// bırakıldığında doğruysa dünya tepki verir (`prop` açılır/iner) ve sahne
/// ilerler. İlk yanlış bırakış yalnız "henüz değil" alır; sonrakiler yardım
/// merdivenini çıkarır: el parlar, sayılar parlar, hayalet hedef.
class SetClockMechanic extends StatefulWidget {
  final SceneController controller;
  final List<SetClockRound> rounds;
  final Set<ClockHand> draggable;
  final int minuteStep;
  final bool linkHands;
  final ClockFrameStyle frame;
  final Line? intro;
  final Line? successLine;
  final Line? wrongLine;

  /// Dünyadaki nesne: `done` doğru kurulumdan sonra true olur.
  final Widget Function(bool done, int solved)? prop;

  /// Sürükleme sırasında canlı tepki veren nesne (damla saati gibi):
  /// o anki saat, turun başlangıcı ve `done` ile çizilir.
  final Widget Function(ClockTime time, ClockTime start, bool done)? timeProp;

  /// Turun hedefiyle çizilen nesne (dijital pano gibi).
  final Widget Function(SetClockRound round, bool done)? roundProp;

  /// Yardım merdiveninin 2. basamağında sayılar yerine okunacak replik
  /// (ör. "beşer beşer say").
  final Line? numeralsHint;

  /// Sahne yerleşimi: saat (yuvasıyla) ve durum verilir, dünyanın içine
  /// yerleştirilir (kabin paneli + büyük kol gibi). Verilince `prop`
  /// kullanılmaz.
  final Widget Function(BuildContext context, Widget clock, SetClockView view)?
      stage;

  /// Son turun başarısından sonra, sahne bitmeden önce beklenir (çocuk kolu
  /// çeker, tren kalkar).
  final Future<void> Function()? afterSuccess;

  const SetClockMechanic({
    super.key,
    required this.controller,
    required this.rounds,
    this.draggable = const {ClockHand.hour, ClockHand.minute},
    this.minuteStep = 1,
    this.linkHands = true,
    this.frame = ClockFrameStyle.cab,
    this.intro,
    this.successLine,
    this.wrongLine,
    this.prop,
    this.timeProp,
    this.roundProp,
    this.numeralsHint,
    this.stage,
    this.afterSuccess,
  });

  @override
  State<SetClockMechanic> createState() => _SetClockMechanicState();
}

class _SetClockMechanicState extends State<SetClockMechanic> {
  final _ladder = HintLadder();
  int _round = 0;
  late ClockTime _time = widget.rounds.first.start;
  int _celebrate = 0;
  int _wrongReleases = 0;
  bool _busy = false;
  bool _done = false;

  SetClockRound get _current => widget.rounds[_round];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _announce(first: true));
  }

  Future<void> _announce({bool first = false}) async {
    if (first && widget.intro != null) await widget.controller.say(widget.intro!);
    if (!mounted) return;
    if (_current.lead != null) await widget.controller.say(_current.lead!);
    if (!mounted) return;
    await widget.controller.sayText(_current.spokenPrompt);
  }

  ClockHand _wrongHand() {
    final t = _current.target;
    if (_time.minute != t.minute) return ClockHand.minute;
    return ClockHand.hour;
  }

  Future<void> _onRelease() async {
    if (_busy || _done) return;
    if (_time.sameOnDial(_current.target)) {
      setState(() {
        _busy = true;
        _done = true;
        _celebrate++;
      });
      await widget.controller.say(widget.successLine ?? Lines.wellDone);
      if (!mounted) return;
      if (_round + 1 < widget.rounds.length) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        setState(() {
          _round++;
          _time = _current.start;
          _ladder.reset();
          _wrongReleases = 0;
          _busy = false;
          _done = false;
        });
        await _announce();
      } else {
        if (widget.afterSuccess != null) await widget.afterSuccess!();
        if (!mounted) return;
        widget.controller.complete();
      }
      return;
    }

    setState(() {
      _busy = true;
      _wrongReleases++;
    });
    if (_wrongReleases == 1) {
      await widget.controller.say(Lines.notYet);
    } else {
      widget.controller.mistake();
      setState(() => _ladder.fail());
      if (_ladder.mistakes == 1 && widget.wrongLine != null) {
        await widget.controller.say(widget.wrongLine!);
      }
      if (!mounted) return;
      final hand = _wrongHand();
      switch (_ladder.level) {
        case 1:
          await widget.controller.say(
              hand == ClockHand.minute ? Lines.hintMinute : Lines.hintHour);
        case 2:
          await widget.controller
              .say(widget.numeralsHint ?? Lines.hintNumerals);
        default:
          await widget.controller.say(Lines.showYou);
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final wrong = _wrongHand();
    final prop = widget.prop?.call(_done, _round + (_done ? 1 : 0)) ??
        widget.timeProp?.call(_time, _current.start, _done) ??
        widget.roundProp?.call(_current, _done);

    final clock = ClockFrame(
      style: widget.frame,
      child: DraggableClock(
        time: _time,
        draggable: _done ? const {} : widget.draggable,
        minuteStep: _current.minuteStep ?? widget.minuteStep,
        linkHands: widget.linkHands,
        glowHands: _ladder.glowHand && !_done ? {wrong} : const {},
        glowNumerals: _ladder.glowNumerals && !_done,
        ghostTime: _ladder.showAnswer && !_done ? _current.target : null,
        onChanged: (t) => setState(() => _time = t),
        onDragEnd: _onRelease,
      ),
    );

    if (widget.stage != null) {
      return MechanicFrame(
        celebrate: _celebrate,
        body: widget.stage!(
          context,
          clock,
          SetClockView(done: _done, round: _round, current: _current),
        ),
      );
    }

    return MechanicFrame(
      celebrate: _celebrate,
      header: prop,
      body: Center(child: AspectRatio(aspectRatio: 1, child: clock)),
    );
  }
}
