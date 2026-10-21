import 'package:flutter/material.dart';

import '../../core/clock_time.dart';
import '../../core/turkish_time.dart';
import '../../shared/audio/sfx.dart';
import '../../shared/widgets/draggable_clock.dart';
import '../../shared/widgets/scenery_view.dart';
import '../story/lines.dart';
import '../story/models.dart';
import 'mechanic_frame.dart';
import 'read_clock.dart';

/// Hızlı Saat: süreli tekrar. Her turda bir saat ve üç tabela; kar taneleri
/// eriyene kadar doğru tabelaya dokunulur. Süre biterse kar hızlanır, tren
/// bir an durur, doğru tabela gösterilir ve sıradaki saat gelir. Ceza yok;
/// sonunda doğru sayısı söylenir. Oyun sonu modunda da kullanılır.
class QuickClockMechanic extends StatefulWidget {
  final SceneController controller;
  final List<ReadClockRound> rounds;
  final Duration perRound;
  final ClockFrameStyle frame;
  final Line? intro;
  final Line? lateLine;
  final Line? done;

  const QuickClockMechanic({
    super.key,
    required this.controller,
    required this.rounds,
    this.perRound = const Duration(seconds: 10),
    this.frame = ClockFrameStyle.post,
    this.intro,
    this.lateLine,
    this.done,
  });

  @override
  State<QuickClockMechanic> createState() => _QuickClockMechanicState();
}

class _QuickClockMechanicState extends State<QuickClockMechanic>
    with TickerProviderStateMixin {
  int _round = 0;
  int _correct = 0;
  int _celebrate = 0;
  bool _busy = true;
  bool _reveal = false;
  ClockTime? _shaking;
  late final AnimationController _timer = AnimationController(
    vsync: this,
    duration: widget.perRound,
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed) _timeout();
    });
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
      if (!mounted) return;
      _startRound();
    });
  }

  @override
  void dispose() {
    _timer.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _startRound() {
    setState(() {
      _busy = false;
      _reveal = false;
    });
    _timer.forward(from: 0);
  }

  Future<void> _next() async {
    if (_round + 1 < widget.rounds.length) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _round++);
      _startRound();
      return;
    }
    await widget.controller.say(widget.done ?? Lines.great);
    if (!mounted) return;
    await widget.controller.sayText(
        '${TurkishTime.number(_correct)} doğru, '
        '${TurkishTime.number(widget.rounds.length)} saat.');
    if (mounted) widget.controller.complete();
  }

  Future<void> _timeout() async {
    if (_busy) return;
    Sfx.instance.play(SfxId.wind, volume: 0.7);
    setState(() {
      _busy = true;
      _reveal = true;
    });
    widget.controller.mistake();
    await widget.controller.say(widget.lateLine ?? Lines.notYet);
    if (!mounted) return;
    await widget.controller.sayText(TurkishTime.spoken(_current.shown));
    if (!mounted) return;
    await _next();
  }

  Future<void> _pick(ClockTime option) async {
    if (_busy) return;
    if (option.sameOnDial(_current.shown)) {
      _timer.stop();
      setState(() {
        _busy = true;
        _reveal = true;
        _correct++;
        _celebrate++;
      });
      await widget.controller.sayText(TurkishTime.spoken(option));
      if (!mounted) return;
      await _next();
      return;
    }
    widget.controller.mistake();
    setState(() => _shaking = option);
    _shake.forward(from: 0);
    await widget.controller.sayText(TurkishTime.spoken(option));
  }

  @override
  Widget build(BuildContext context) {
    return MechanicFrame(
      celebrate: _celebrate,
      header: AnimatedBuilder(
        animation: _timer,
        builder: (context, _) => _SnowMeter(
          remaining: 1 - _timer.value,
          correct: _correct,
          total: widget.rounds.length,
          round: _round,
        ),
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: ClockFrame(
            style: widget.frame,
            child: DraggableClock(time: _current.shown, draggable: const {}),
          ),
        ),
      ),
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
                text: o.digital12,
                highlighted: _reveal && o.sameOnDial(_current.shown),
                onTap: _busy ? null : () => _pick(o),
              ),
            ),
        ],
      ),
    );
  }
}

/// Kar tanesi sayacı: kalan süre kadar tane görünür; yanında doğru sayısı.
class _SnowMeter extends StatelessWidget {
  final double remaining;
  final int correct;
  final int total;
  final int round;

  const _SnowMeter({
    required this.remaining,
    required this.correct,
    required this.total,
    required this.round,
  });

  @override
  Widget build(BuildContext context) {
    const flakes = 8;
    final lit = (remaining * flakes).ceil();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < flakes; i++)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: i < lit ? 1 : 0.15,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Icon(Icons.ac_unit, color: Color(0xFF81D4FA), size: 28),
            ),
          ),
        const SizedBox(width: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF263238),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Color(0xFFFFD54F), size: 24),
              const SizedBox(width: 6),
              Text(
                '$correct',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${round + 1}/$total',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
