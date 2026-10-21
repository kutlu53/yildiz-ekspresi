import 'package:flutter/material.dart';

import '../../core/clock_time.dart';
import '../../core/turkish_time.dart';
import '../../shared/widgets/draggable_clock.dart';
import '../../shared/widgets/scenery_view.dart';
import '../story/lines.dart';
import '../story/models.dart';
import 'hint_ladder.dart';
import 'mechanic_frame.dart';

class ReadClockRound {
  final ClockTime shown;
  final List<ClockTime> options;

  const ReadClockRound({required this.shown, required this.options});
}

/// Sahne yerleşimine verilen seçenek: etiket, vurgu, sallanma ve dokunuş.
class ReadOption {
  final ClockTime time;
  final String label;
  final bool highlighted;
  final double shakeDx;
  final VoidCallback? onTap;

  const ReadOption({
    required this.time,
    required this.label,
    required this.highlighted,
    required this.shakeDx,
    required this.onTap,
  });
}

/// Saati Oku: dünyadaki saat gösterilir, çocuk doğru tabelaya dokunur.
/// Tabela dokununca sesle okunur; doğruysa kutlama, yanlışsa tabela sallanır
/// ve yardım merdiveni çıkar.
class ReadClockMechanic extends StatefulWidget {
  final SceneController controller;
  final List<ReadClockRound> rounds;
  final ClockFrameStyle frame;
  final Line? intro;
  final Line? hintLine;
  final Widget Function(int roundIndex)? prop;
  final String Function(ClockTime)? cardLabel;
  final String Function(ClockTime)? cardSpoken;

  /// Sahne yerleşimi: saat (yuvasıyla) ve seçenekler verilir, dünyanın
  /// içine yerleştirilir (vagonlar gibi). Verilince tabela sırası çizilmez.
  final Widget Function(BuildContext context, Widget clock,
      List<ReadOption> options, int round)? stage;

  const ReadClockMechanic({
    super.key,
    required this.controller,
    required this.rounds,
    this.frame = ClockFrameStyle.post,
    this.intro,
    this.hintLine,
    this.prop,
    this.cardLabel,
    this.cardSpoken,
    this.stage,
  });

  @override
  State<ReadClockMechanic> createState() => _ReadClockMechanicState();
}

class _ReadClockMechanicState extends State<ReadClockMechanic>
    with SingleTickerProviderStateMixin {
  final _ladder = HintLadder();
  int _round = 0;
  int _celebrate = 0;
  bool _busy = false;
  ClockTime? _shaking;
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  ReadClockRound get _current => widget.rounds[_round];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.intro != null) await widget.controller.say(widget.intro!);
    });
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  bool get _hourMatters =>
      _current.options.map((o) => o.hour % 12).toSet().length > 1;

  Future<void> _pick(ClockTime option) async {
    if (_busy) return;
    setState(() => _busy = true);
    await widget.controller
        .sayText((widget.cardSpoken ?? TurkishTime.spoken)(option));
    if (!mounted) return;

    if (option.sameOnDial(_current.shown)) {
      setState(() => _celebrate++);
      await widget.controller.say(Lines.great);
      if (!mounted) return;
      if (_round + 1 < widget.rounds.length) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        setState(() {
          _round++;
          _ladder.reset();
          _busy = false;
        });
      } else {
        widget.controller.complete();
      }
      return;
    }

    widget.controller.mistake();
    setState(() {
      _ladder.fail();
      _shaking = option;
    });
    _shake.forward(from: 0);
    switch (_ladder.level) {
      case 1:
        await widget.controller.say(widget.hintLine ??
            (_hourMatters ? Lines.hintHour : Lines.hintMinute));
      case 2:
        await widget.controller.say(Lines.hintNumerals);
      default:
        await widget.controller.say(Lines.showYou);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.cardLabel ?? (t) => t.digital12;
    final glowHand = _hourMatters ? ClockHand.hour : ClockHand.minute;

    final clock = ClockFrame(
      style: widget.frame,
      child: DraggableClock(
        time: _current.shown,
        draggable: const {},
        glowHands: _ladder.glowHand ? {glowHand} : const {},
        glowNumerals: _ladder.glowNumerals,
      ),
    );

    if (widget.stage != null) {
      return MechanicFrame(
        celebrate: _celebrate,
        body: AnimatedBuilder(
          animation: _shake,
          builder: (context, _) => widget.stage!(
            context,
            clock,
            [
              for (final o in _current.options)
                ReadOption(
                  time: o,
                  label: label(o),
                  highlighted:
                      _ladder.showAnswer && o.sameOnDial(_current.shown),
                  shakeDx: _shaking == o && _shake.isAnimating
                      ? (1 - _shake.value) *
                          10 *
                          ((_shake.value * 20).floor().isEven ? 1 : -1)
                      : 0.0,
                  onTap: _busy ? null : () => _pick(o),
                ),
            ],
            _round,
          ),
        ),
      );
    }

    return MechanicFrame(
      celebrate: _celebrate,
      header: widget.prop?.call(_round),
      body: Center(child: AspectRatio(aspectRatio: 1, child: clock)),
      footer: Wrap(
        alignment: WrapAlignment.center,
        spacing: 20,
        runSpacing: 12,
        children: [
          for (final o in _current.options)
            AnimatedBuilder(
              animation: _shake,
              builder: (context, child) {
                final dx = _shaking == o && _shake.isAnimating
                    ? (1 - _shake.value) *
                        10 *
                        ((_shake.value * 20).floor().isEven ? 1 : -1)
                    : 0.0;
                return Transform.translate(offset: Offset(dx, 0), child: child);
              },
              child: WoodenSign(
                text: label(o),
                highlighted:
                    _ladder.showAnswer && o.sameOnDial(_current.shown),
                onTap: _busy ? null : () => _pick(o),
              ),
            ),
        ],
      ),
    );
  }
}
