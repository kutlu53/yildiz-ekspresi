import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/turkish_time.dart';
import '../../shared/audio/sfx.dart';
import '../story/lines.dart';
import '../story/models.dart';
import 'hint_ladder.dart';
import 'mechanic_frame.dart';

/// Kefeye konan ağırlık: "10 dk", "6 saat", "1 gün".
class BalanceWeight {
  final int value;
  final String label;

  const BalanceWeight({required this.value, required this.label});
}

class BalanceRound {
  /// Sol kefedeki sabit ağırlık: "1 saat".
  final String leftLabel;
  final String leftSpoken;

  /// Sağ kefenin dengelemesi gereken toplam (sağ birimde).
  final int target;

  /// Sağ birimin sözlü adı: "dakika", "saat", "gün".
  final String unitSpoken;
  final List<BalanceWeight> pool;
  final String prompt;
  final String? successSpoken;

  const BalanceRound({
    required this.leftLabel,
    required this.leftSpoken,
    required this.target,
    required this.unitSpoken,
    required this.pool,
    required this.prompt,
    this.successSpoken,
  });
}

/// Terazi: sol kefede büyük birim (1 saat), sağ kefeye küçük birimin
/// ağırlıkları konur; toplam tam denk gelince terazi dengelenir. Fazla
/// konursa kefe düşer, son ağırlık geri alınır. Kefedeki ağırlığa dokunmak
/// onu geri koyar. Yardım merdiveni kalan miktarı söyler.
class BalanceMechanic extends StatefulWidget {
  final SceneController controller;
  final List<BalanceRound> rounds;
  final Line? intro;
  final Line? overLine;
  final Line? done;

  /// Dünyadaki nesne (kilit gibi), terazinin üstünde.
  final Widget? prop;

  const BalanceMechanic({
    super.key,
    required this.controller,
    required this.rounds,
    this.intro,
    this.overLine,
    this.done,
    this.prop,
  });

  @override
  State<BalanceMechanic> createState() => _BalanceMechanicState();
}

class _BalanceMechanicState extends State<BalanceMechanic> {
  final _ladder = HintLadder();
  int _round = 0;
  final List<int> _placed = [];
  int _celebrate = 0;
  bool _busy = false;
  bool _done = false;

  BalanceRound get _current => widget.rounds[_round];
  int get _sum => _placed.fold(0, (s, i) => s + _current.pool[i].value);

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

  String _sumSpoken() =>
      '${TurkishTime.number(_sum)} ${_current.unitSpoken}';

  Future<void> _add(int index) async {
    if (_busy || _done || _placed.contains(index)) return;
    setState(() {
      _busy = true;
      _placed.add(index);
    });
    Sfx.instance.play(SfxId.pop, volume: 0.7);
    final target = _current.target;
    if (_sum == target) {
      setState(() {
        _done = true;
        _celebrate++;
      });
      await widget.controller.sayText(_current.successSpoken ??
          '${_sumSpoken()}, ${_current.leftSpoken}. Dengelendi!');
      if (!mounted) return;
      if (_round + 1 < widget.rounds.length) {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        setState(() {
          _round++;
          _placed.clear();
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
    if (_sum > target) {
      widget.controller.mistake();
      setState(() => _ladder.fail());
      await widget.controller.say(widget.overLine ?? Lines.notYet);
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _placed.removeLast());
      if (_ladder.level >= 2) {
        final remain = target - _sum;
        await widget.controller.sayText(
            '${_sumSpoken()} oldu, ${TurkishTime.number(remain)} '
            '${_current.unitSpoken} daha.');
      }
      if (mounted) setState(() => _busy = false);
      return;
    }
    await widget.controller.sayText(_sumSpoken());
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _remove(int index) async {
    if (_busy || _done) return;
    setState(() {
      _busy = true;
      _placed.remove(index);
    });
    await widget.controller.sayText('Geri aldım. ${_sumSpoken()}.');
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final r = _current;
    final tilt = _done
        ? 0.0
        : ((_sum - r.target) / r.target).clamp(-1.0, 1.0) * 10;

    return MechanicFrame(
      celebrate: _celebrate,
      header: widget.prop,
      body: _Scale(
        tilt: tilt,
        balanced: _done,
        left: _Block(
          label: r.leftLabel,
          color: const Color(0xFFE53935),
          large: true,
        ),
        right: Wrap(
          spacing: 4,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            for (final i in _placed)
              GestureDetector(
                key: ValueKey('placed-$i'),
                onTap: () => _remove(i),
                child: _Block(label: r.pool[i].label, color: const Color(0xFF1E88E5)),
              ),
          ],
        ),
      ),
      footer: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          for (var i = 0; i < r.pool.length; i++)
            if (!_placed.contains(i))
              GestureDetector(
                key: ValueKey('weight-$i'),
                onTap: () => _add(i),
                child: _Block(
                  label: r.pool[i].label,
                  color: const Color(0xFF1E88E5),
                  glow: _ladder.showAnswer && !_done,
                ),
              ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final String label;
  final Color color;
  final bool large;
  final bool glow;

  const _Block({
    required this.label,
    required this.color,
    this.large = false,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: large ? 110 : 64),
      padding: EdgeInsets.symmetric(
          horizontal: large ? 16 : 10, vertical: large ? 14 : 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: glow ? const Color(0xFFFFD54F) : Colors.black26,
          width: glow ? 4 : 2,
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: large ? 26 : 20,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// İki kefeli terazi: `tilt` derece (artı: sağ ağır, eksi: sol ağır).
class _Scale extends StatelessWidget {
  final double tilt;
  final bool balanced;
  final Widget left;
  final Widget right;

  const _Scale({
    required this.tilt,
    required this.balanced,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;
      final beamW = math.min(w * 0.8, 560.0);
      final beamY = h * 0.3;
      final rad = tilt * math.pi / 180;
      final dy = math.sin(rad) * beamW / 2;
      final panW = beamW * 0.42;
      return Stack(
        children: [
          // Direk ve taban
          Positioned(
            left: w / 2 - 8,
            top: beamY,
            child: Container(width: 16, height: h * 0.6, color: const Color(0xFF5D4037)),
          ),
          Positioned(
            left: w / 2 - 70,
            top: beamY + h * 0.6 - 10,
            child: Container(
              width: 140,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFF5D4037),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          // Kiriş
          Positioned(
            left: w / 2 - beamW / 2,
            top: beamY - 6,
            child: AnimatedRotation(
              turns: tilt / 360,
              duration: const Duration(milliseconds: 500),
              child: Container(
                width: beamW,
                height: 12,
                decoration: BoxDecoration(
                  color: balanced ? const Color(0xFFFFB300) : const Color(0xFF8D6E63),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          // Sol kefe
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            left: w / 2 - beamW / 2 - panW / 2 + 10,
            top: beamY - dy + 20,
            width: panW,
            child: _Pan(child: left),
          ),
          // Sağ kefe
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            left: w / 2 + beamW / 2 - panW / 2 - 10,
            top: beamY + dy + 20,
            width: panW,
            child: _Pan(child: right),
          ),
        ],
      );
    });
  }
}

class _Pan extends StatelessWidget {
  final Widget child;

  const _Pan({required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(width: 3, height: 40, color: const Color(0xFF37474F)),
        Container(
          constraints: const BoxConstraints(minHeight: 70),
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFB0BEC5),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ],
    );
  }
}
