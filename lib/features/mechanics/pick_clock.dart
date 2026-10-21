import 'package:flutter/material.dart';

import '../../core/clock_time.dart';
import '../../core/turkish_time.dart';
import '../../shared/widgets/draggable_clock.dart';
import '../../shared/widgets/scenery_view.dart';
import '../story/lines.dart';
import '../story/models.dart';
import 'hint_ladder.dart';
import 'mechanic_frame.dart';

class PickClockRound {
  final ClockTime target;
  final List<ClockTime> options;

  /// Tur başında okunan istem (ör. "On beş sıfır sıfır. Hangi kadran?").
  final String? spokenPrompt;

  /// Doğru seçimden sonra okunan açıklama (ör. "On beş, öğleden sonra üç").
  final String? successSpoken;

  const PickClockRound({
    required this.target,
    required this.options,
    this.spokenPrompt,
    this.successSpoken,
  });
}

/// Eşleştir (dijital → analog): hedef dijital/sözlü verilir, dünyadaki
/// birkaç saatten (peron saatleri gibi) doğrusuna dokunulur. Saati Oku'nun
/// tersi: orada kadran verilip tabela seçilir, burada tabela verilip kadran
/// seçilir. Dokunulan saat sesle okunur; yanlışta sallanır, yardım merdiveni
/// önce akrebi, sonra sayıları parlatır, en son doğru saati gösterir.
class PickClockMechanic extends StatefulWidget {
  final SceneController controller;
  final List<PickClockRound> rounds;
  final ClockFrameStyle frame;
  final Line? intro;
  final Line? hintLine;
  final Line? successLine;

  /// Hedefi gösteren nesne (bilet, pano). Verilmezse dijital pano.
  final Widget Function(PickClockRound round)? prop;

  /// Seçeneklerin altındaki etiket (peron numarası gibi). Verilmezse 1, 2, 3.
  final String Function(int index)? optionLabel;

  const PickClockMechanic({
    super.key,
    required this.controller,
    required this.rounds,
    this.frame = ClockFrameStyle.post,
    this.intro,
    this.hintLine,
    this.successLine,
    this.prop,
    this.optionLabel,
  });

  @override
  State<PickClockMechanic> createState() => _PickClockMechanicState();
}

class _PickClockMechanicState extends State<PickClockMechanic>
    with SingleTickerProviderStateMixin {
  final _ladder = HintLadder();
  int _round = 0;
  int _celebrate = 0;
  bool _busy = false;
  int? _shaking;
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  PickClockRound get _current => widget.rounds[_round];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _announce(first: true));
  }

  Future<void> _announce({bool first = false}) async {
    if (first && widget.intro != null) await widget.controller.say(widget.intro!);
    if (!mounted || _current.spokenPrompt == null) return;
    await widget.controller.sayText(_current.spokenPrompt!);
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  Future<void> _pick(int index) async {
    if (_busy) return;
    final option = _current.options[index];
    setState(() => _busy = true);
    await widget.controller.sayText(TurkishTime.spokenDigital(option));
    if (!mounted) return;

    if (option.sameOnDial(_current.target)) {
      setState(() => _celebrate++);
      await widget.controller.say(widget.successLine ?? Lines.great);
      if (!mounted) return;
      if (_current.successSpoken != null) {
        await widget.controller.sayText(_current.successSpoken!);
        if (!mounted) return;
      }
      if (_round + 1 < widget.rounds.length) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        setState(() {
          _round++;
          _ladder.reset();
          _busy = false;
        });
        await _announce();
      } else {
        widget.controller.complete();
      }
      return;
    }

    widget.controller.mistake();
    setState(() {
      _ladder.fail();
      _shaking = index;
    });
    _shake.forward(from: 0);
    switch (_ladder.level) {
      case 1:
        await widget.controller.say(widget.hintLine ?? Lines.hintHour);
      case 2:
        await widget.controller.say(Lines.hintNumerals);
      default:
        await widget.controller.say(Lines.showYou);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final header = widget.prop?.call(_current) ??
        DigitalBoard(text: _current.target.digital12);

    return MechanicFrame(
      celebrate: _celebrate,
      header: header,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < _current.options.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _Option(
                  index: i,
                  time: _current.options[i],
                  label: widget.optionLabel?.call(i) ?? '${i + 1}',
                  frame: widget.frame,
                  shake: _shake,
                  shaking: _shaking == i,
                  glowHour: _ladder.glowHand,
                  glowNumerals: _ladder.glowNumerals,
                  answer: _ladder.showAnswer
                      ? _current.options[i].sameOnDial(_current.target)
                      : null,
                  onTap: _busy ? null : () => _pick(i),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final int index;
  final ClockTime time;
  final String label;
  final ClockFrameStyle frame;
  final AnimationController shake;
  final bool shaking;
  final bool glowHour;
  final bool glowNumerals;

  /// null: cevap gösterilmiyor; true: bu doğru; false: bu yanlış (soluk).
  final bool? answer;
  final VoidCallback? onTap;

  const _Option({
    required this.index,
    required this.time,
    required this.label,
    required this.frame,
    required this.shake,
    required this.shaking,
    required this.glowHour,
    required this.glowNumerals,
    required this.answer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dim = answer == false;
    final highlight = answer == true;
    return AnimatedBuilder(
      animation: shake,
      builder: (context, child) {
        final dx = shaking && shake.isAnimating
            ? (1 - shake.value) *
                10 *
                ((shake.value * 20).floor().isEven ? 1 : -1)
            : 0.0;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: dim ? 0.4 : 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                decoration: BoxDecoration(
                  color: highlight
                      ? const Color(0xFFFFF59D)
                      : const Color(0xFF1E88E5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: highlight ? const Color(0xFF263238) : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: highlight
                          ? const Color(0xFFFFD54F)
                          : Colors.transparent,
                    ),
                    child: ClockFrame(
                      style: frame,
                      child: DraggableClock(
                        time: time,
                        draggable: const {},
                        glowHands:
                            glowHour ? const {ClockHand.hour} : const {},
                        glowNumerals: glowNumerals,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
