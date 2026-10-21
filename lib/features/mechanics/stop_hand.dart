import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/angle_mapper.dart';
import '../../core/clock_time.dart';
import '../../shared/audio/sfx.dart';
import '../../shared/widgets/draggable_clock.dart';
import '../../shared/widgets/scenery_view.dart';
import '../story/lines.dart';
import '../story/models.dart';
import 'mechanic_frame.dart';

class StopHandRound {
  final ClockTime target;
  final Line prompt;

  const StopHandRound({required this.target, required this.prompt});
}

/// Zili Çal: yelkovan kendi kendine döner, çocuk hedefe gelince saate
/// (ya da zile) dokunur. Gözlem ve zamanlama; sürüklemeden farklı bir his.
class StopHandMechanic extends StatefulWidget {
  final SceneController controller;
  final List<StopHandRound> rounds;
  final ClockFrameStyle frame;
  final Line? intro;
  final Line? successLine;

  /// Saniyede derece. 18°/s: bir tur 20 sn.
  final double degreesPerSecond;

  /// Kabul toleransı (derece). 9° = 1,5 dakika.
  final double tolerance;

  const StopHandMechanic({
    super.key,
    required this.controller,
    required this.rounds,
    this.frame = ClockFrameStyle.tower,
    this.intro,
    this.successLine,
    this.degreesPerSecond = 18,
    this.tolerance = 9,
  });

  @override
  State<StopHandMechanic> createState() => _StopHandMechanicState();
}

class _StopHandMechanicState extends State<StopHandMechanic> {
  static const _tick = Duration(milliseconds: 50);

  int _round = 0;
  double _minuteAngle = 0;
  Timer? _timer;
  bool _running = false;
  bool _busy = false;
  int _celebrate = 0;
  bool _rang = false;

  StopHandRound get _current => widget.rounds[_round];

  ClockTime get _time {
    final minute = AngleMapper.angleToMinute(_minuteAngle);
    return ClockTime(_current.target.hour, minute);
  }

  @override
  void initState() {
    super.initState();
    _minuteAngle = AngleMapper.normalize(_current.target.minuteHandAngle - 120);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.intro != null) await widget.controller.say(widget.intro!);
      if (!mounted) return;
      await widget.controller.say(_current.prompt);
      _startTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _running = true;
    _timer = Timer.periodic(_tick, (_) {
      if (!mounted || !_running) return;
      setState(() {
        _minuteAngle = AngleMapper.normalize(_minuteAngle +
            widget.degreesPerSecond * _tick.inMilliseconds / 1000);
      });
    });
  }

  Future<void> _tap() async {
    if (_busy || !_running) return;
    final target = _current.target.minuteHandAngle;
    final diff = AngleMapper.normalize(_minuteAngle - target);
    final signed = diff > 180 ? diff - 360 : diff;

    if (signed.abs() <= widget.tolerance) {
      _running = false;
      _timer?.cancel();
      setState(() {
        _busy = true;
        _minuteAngle = target;
        _rang = true;
        _celebrate++;
      });
      await widget.controller.say(widget.successLine ?? Lines.s3BellDone);
      if (!mounted) return;
      if (_round + 1 < widget.rounds.length) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        setState(() {
          _round++;
          _rang = false;
          _minuteAngle =
              AngleMapper.normalize(_current.target.minuteHandAngle - 120);
          _busy = false;
        });
        await widget.controller.say(_current.prompt);
        if (mounted) _startTimer();
      } else {
        widget.controller.complete();
      }
      return;
    }

    setState(() => _busy = true);
    widget.controller.mistake();
    await widget.controller
        .say(signed < 0 ? Lines.s3BellEarly : Lines.s3BellLate);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return MechanicFrame(
      celebrate: _celebrate,
      header: _Bell(ringing: _rang),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _tap(),
        child: Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: ClockFrame(
              style: widget.frame,
              child: DraggableClock(
                time: _time,
                draggable: const {},
                ghostTime: _current.target,
                ghostHands: const {ClockHand.minute},
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bell extends StatelessWidget {
  final bool ringing;

  const _Bell({required this.ringing});

  @override
  Widget build(BuildContext context) {
    return Cue(
      trigger: ringing,
      id: SfxId.bell,
      when: ringing,
      child: AnimatedRotation(
        turns: ringing ? 0.06 : 0,
        duration: const Duration(milliseconds: 150),
        child: Icon(
          Icons.notifications_active_rounded,
          size: 64,
          color: ringing ? const Color(0xFFFFB300) : const Color(0xFF8D6E63),
        ),
      ),
    );
  }
}
