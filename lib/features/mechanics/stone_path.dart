import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/turkish_time.dart';
import '../../shared/audio/sfx.dart';
import '../../core/week.dart';
import '../../shared/widgets/pamuk.dart';
import '../story/lines.dart';
import '../story/models.dart';
import 'hint_ladder.dart';
import 'mechanic_frame.dart';

/// Taş yolu modu: `walk` sıradaki taşa basarak sayma, `pick` sorunun
/// cevabı olan taşa dokunma (Pamuk kendisi taş taş zıplar).
enum StoneMode { walk, pick }

class StoneRound {
  /// Pamuk'un başladığı taş (0-6).
  final int start;

  /// Kaç taş ileri (döngüsel; 7 tam tur).
  final int steps;

  /// Tur başında okunan istem.
  final String prompt;

  /// Başarıda okunacak açıklama; verilmezse yol sayılarak okunur.
  final String? successSpoken;

  const StoneRound({
    required this.start,
    required this.steps,
    required this.prompt,
    this.successSpoken,
  });
}

/// Taş Yolu: yedi taş halka biçiminde dizilir, böylece Pazar'dan sonra yine
/// Pazartesi'nin geldiği görülür. Her taş dokununca adını söyler. Walk
/// modunda çocuk Pamuk'u taş taş yürütür ve günleri sayar; pick modunda
/// "n gün sonra hangi gün?" sorusunun taşına dokunur. Yanlışta taş sallanır;
/// yardım merdiveni önce sayma ipucu verir, sonra yolu parlatır, en son
/// hedefi gösterir.
class StonePathMechanic extends StatefulWidget {
  final SceneController controller;
  final List<StoneRound> rounds;
  final StoneMode mode;
  final List<String> labels;

  /// Sayım birimi: "gün" (hafta) ya da "ay" (yıl).
  final String unit;
  final Line? intro;
  final Line? hintLine;
  final Line? wrongLine;
  final Line? done;

  /// Dünyadaki nesne (tarife tabelası gibi), tura göre çizilir.
  final Widget Function(StoneRound round, bool done)? prop;

  const StonePathMechanic({
    super.key,
    required this.controller,
    required this.rounds,
    this.mode = StoneMode.walk,
    this.labels = Week.names,
    this.unit = 'gün',
    this.intro,
    this.hintLine,
    this.wrongLine,
    this.done,
    this.prop,
  });

  @override
  State<StonePathMechanic> createState() => _StonePathMechanicState();
}

class _StonePathMechanicState extends State<StonePathMechanic>
    with SingleTickerProviderStateMixin {
  final _ladder = HintLadder();
  int _round = 0;
  late int _pos = widget.rounds.first.start;
  int _walked = 0;
  int _celebrate = 0;
  bool _busy = false;
  bool _done = false;
  int? _shaking;
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  StoneRound get _current => widget.rounds[_round];
  int get _count => widget.labels.length;
  int get _target => (_current.start + _current.steps) % _count;

  /// Yol: başlangıç hariç, hedef dâhil (etiket sayısına göre döngüsel).
  List<int> _path() => [
        for (var k = 1; k <= _current.steps; k++)
          (_current.start + k) % _count,
      ];

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

  String _pathSpoken() {
    final names = _path().map((d) => widget.labels[d]).join(', ');
    final n = _current.steps;
    return '$names. ${TurkishTime.number(n)} ${widget.unit} sonra '
        '${widget.labels[_target]}!';
  }

  Future<void> _succeed() async {
    setState(() {
      _done = true;
      _celebrate++;
    });
    await widget.controller
        .sayText(_current.successSpoken ?? _pathSpoken());
    if (!mounted) return;
    if (_round + 1 < widget.rounds.length) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        _round++;
        _pos = _current.start;
        _walked = 0;
        _ladder.reset();
        _done = false;
        _busy = false;
      });
      await _announce();
    } else {
      await widget.controller.say(widget.done ?? Lines.great);
      if (mounted) widget.controller.complete();
    }
  }

  Future<void> _fail(int index) async {
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

  Future<void> _tap(int index) async {
    if (_busy || _done) return;
    setState(() => _busy = true);
    final label = widget.labels[index];

    if (widget.mode == StoneMode.walk) {
      final next = (_pos + 1) % _count;
      if (index == next) {
        setState(() {
          _pos = index;
          _walked++;
        });
        await widget.controller
            .sayText('${TurkishTime.number(_walked)}, $label.');
        if (!mounted) return;
        if (_walked >= _current.steps) {
          await _succeed();
        } else {
          setState(() => _busy = false);
        }
        return;
      }
      if (index == _pos) {
        await widget.controller.sayText('$label. Pamuk burada.');
        if (mounted) setState(() => _busy = false);
        return;
      }
      await widget.controller.sayText(label);
      if (!mounted) return;
      await _fail(index);
      return;
    }

    // pick
    await widget.controller.sayText(label);
    if (!mounted) return;
    if (index == _target) {
      for (final d in _path()) {
        if (!mounted) return;
        setState(() => _pos = d);
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
      await _succeed();
      return;
    }
    await _fail(index);
  }

  /// Yardım merdiveninde parlayan taşlar.
  Set<int> _glowing() {
    if (_done) return const {};
    if (widget.mode == StoneMode.walk) {
      return _ladder.level >= 2 ? {(_pos + 1) % _count} : const {};
    }
    if (_ladder.level >= 2) return _path().toSet();
    return const {};
  }

  @override
  Widget build(BuildContext context) {
    final glowing = _glowing();
    final answer = _ladder.showAnswer && !_done
        ? (widget.mode == StoneMode.walk ? (_pos + 1) % _count : _target)
        : null;

    return MechanicFrame(
      celebrate: _celebrate,
      header: widget.prop?.call(_current, _done),
      body: LayoutBuilder(builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final stoneW = math.min(140.0, w / (_count / 2 + 1.5));
        final stoneH = stoneW * 0.55;
        final rx = w / 2 - stoneW / 2 - 8;
        final ry = h / 2 - stoneH / 2 - 40;
        Offset centerOf(int i) {
          final a = -math.pi / 2 + 2 * math.pi * i / _count;
          return Offset(w / 2 + rx * math.cos(a), h / 2 + ry * math.sin(a) + 16);
        }

        final pamukSize = math.min(72.0, stoneW * 0.6);
        final pc = centerOf(_pos);
        return Stack(
          children: [
            // Taşlar arası patika
            CustomPaint(
              size: Size(w, h),
              painter: _PathPainter(
                  [for (var i = 0; i < _count; i++) centerOf(i)]),
            ),
            for (var i = 0; i < _count; i++)
              Positioned(
                left: centerOf(i).dx - stoneW / 2,
                top: centerOf(i).dy - stoneH / 2,
                width: stoneW,
                height: stoneH,
                child: AnimatedBuilder(
                  animation: _shake,
                  builder: (context, child) {
                    final dx = _shaking == i && _shake.isAnimating
                        ? (1 - _shake.value) *
                            10 *
                            ((_shake.value * 20).floor().isEven ? 1 : -1)
                        : 0.0;
                    return Transform.translate(
                        offset: Offset(dx, 0), child: child);
                  },
                  child: _Stone(
                    key: ValueKey('stone-$i'),
                    label: widget.labels[i],
                    current: _pos == i,
                    glow: glowing.contains(i),
                    answer: answer == i,
                    onTap: () => _tap(i),
                  ),
                ),
              ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              left: pc.dx - pamukSize / 2,
              top: pc.dy - stoneH / 2 - pamukSize + 10,
              child: IgnorePointer(
                child: Cue(
                  trigger: _pos,
                  id: SfxId.pop,
                  volume: 0.6,
                  child: Pamuk(
                    size: pamukSize,
                    mood: _done ? PamukMood.happy : PamukMood.idle,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _Stone extends StatelessWidget {
  final String label;
  final bool current;
  final bool glow;
  final bool answer;
  final VoidCallback onTap;

  const _Stone({
    super.key,
    required this.label,
    required this.current,
    required this.glow,
    required this.answer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = answer
        ? const Color(0xFFFFB300)
        : glow
            ? const Color(0xFFFFF176)
            : const Color(0xFF546E7A);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: current
              ? const Color(0xFFFFD54F)
              : answer
                  ? const Color(0xFFFFF59D)
                  : const Color(0xFFB0BEC5),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: border, width: glow || answer ? 5 : 3),
          boxShadow: const [
            BoxShadow(blurRadius: 6, color: Colors.black38, offset: Offset(0, 3)),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF263238),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Taşları birbirine bağlayan kesikli patika; halka olduğu için son taş
/// ilkine bağlanır.
class _PathPainter extends CustomPainter {
  final List<Offset> points;

  _PathPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < points.length; i++) {
      final a = points[i];
      final b = points[(i + 1) % points.length];
      for (var f = 0.2; f < 0.85; f += 0.15) {
        final c = Offset.lerp(a, b, f)!;
        canvas.drawCircle(c, 4, p);
      }
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) => old.points != points;
}
