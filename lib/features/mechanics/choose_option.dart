import 'package:flutter/material.dart';

import '../story/lines.dart';
import '../story/models.dart';
import 'hint_ladder.dart';
import 'mechanic_frame.dart';

class ChoiceOption {
  final String label;
  final String spoken;

  const ChoiceOption({required this.label, required this.spoken});
}

class ChoiceRound {
  /// Tur başında okunan istem.
  final String prompt;
  final List<ChoiceOption> options;

  /// Doğru seçeneğin dizini.
  final int correct;

  /// Doğru seçimden sonra okunan açıklama.
  final String? successSpoken;

  const ChoiceRound({
    required this.prompt,
    required this.options,
    required this.correct,
    this.successSpoken,
  });
}

/// Seçenek Seç (Saati Oku'nun genel biçimi): ortada dünyadaki nesne (yumruk
/// tepeleri, ev, pano), altta ahşap tabelalar. Dokunulan tabela sesle
/// okunur; doğruysa kutlama, yanlışsa tabela sallanır ve yardım merdiveni
/// önce ipucu verir, en son doğru tabelayı parlatır.
class ChooseOptionMechanic extends StatefulWidget {
  final SceneController controller;
  final List<ChoiceRound> rounds;
  final Line? intro;
  final Line? hintLine;
  final Line? wrongLine;
  final Line? done;

  /// Dünyadaki nesne: tur ve `done` ile çizilir.
  final Widget Function(ChoiceRound round, int index, bool done) prop;

  const ChooseOptionMechanic({
    super.key,
    required this.controller,
    required this.rounds,
    required this.prop,
    this.intro,
    this.hintLine,
    this.wrongLine,
    this.done,
  });

  @override
  State<ChooseOptionMechanic> createState() => _ChooseOptionMechanicState();
}

class _ChooseOptionMechanicState extends State<ChooseOptionMechanic>
    with SingleTickerProviderStateMixin {
  final _ladder = HintLadder();
  int _round = 0;
  int _celebrate = 0;
  bool _busy = false;
  bool _done = false;
  int? _shaking;
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  ChoiceRound get _current => widget.rounds[_round];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _announce(first: true));
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  Future<void> _announce({bool first = false}) async {
    if (first && widget.intro != null) await widget.controller.say(widget.intro!);
    if (!mounted) return;
    await widget.controller.sayText(_current.prompt);
  }

  Future<void> _pick(int index) async {
    if (_busy || _done) return;
    setState(() => _busy = true);
    await widget.controller.sayText(_current.options[index].spoken);
    if (!mounted) return;

    if (index == _current.correct) {
      setState(() {
        _done = true;
        _celebrate++;
      });
      if (_current.successSpoken != null) {
        await widget.controller.sayText(_current.successSpoken!);
      } else {
        await widget.controller.say(Lines.great);
      }
      if (!mounted) return;
      if (_round + 1 < widget.rounds.length) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        setState(() {
          _round++;
          _ladder.reset();
          _done = false;
          _busy = false;
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
      _shaking = index;
    });
    _shake.forward(from: 0);
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
    return MechanicFrame(
      celebrate: _celebrate,
      body: Center(child: widget.prop(_current, _round, _done)),
      footer: Wrap(
        alignment: WrapAlignment.center,
        spacing: 20,
        runSpacing: 12,
        children: [
          for (var i = 0; i < _current.options.length; i++)
            AnimatedBuilder(
              animation: _shake,
              builder: (context, child) {
                final dx = _shaking == i && _shake.isAnimating
                    ? (1 - _shake.value) *
                        10 *
                        ((_shake.value * 20).floor().isEven ? 1 : -1)
                    : 0.0;
                return Transform.translate(offset: Offset(dx, 0), child: child);
              },
              child: WoodenSign(
                key: ValueKey('choice-$i'),
                text: _current.options[i].label,
                highlighted: (_ladder.showAnswer || _done) && i == _current.correct,
                onTap: _busy || _done ? null : () => _pick(i),
              ),
            ),
        ],
      ),
    );
  }
}
