import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/angle_mapper.dart';
import '../../core/clock_time.dart';
import '../../shared/widgets/clock_face.dart';
import '../../shared/widgets/clock_drag_logic.dart';
import '../../shared/widgets/scenery_view.dart';
import '../story/lines.dart';
import '../story/models.dart';
import 'hint_ladder.dart';
import 'mechanic_frame.dart';

/// Hangisi?: Pamuk "akrebe dokun" / "yelkovana dokun" der, çocuk ele dokunur.
class TapHandMechanic extends StatefulWidget {
  final SceneController controller;
  final List<ClockHand> rounds;
  final ClockTime time;
  final ClockFrameStyle frame;
  final Line? intro;

  const TapHandMechanic({
    super.key,
    required this.controller,
    required this.rounds,
    this.time = const ClockTime(3, 0),
    this.frame = ClockFrameStyle.cab,
    this.intro,
  });

  @override
  State<TapHandMechanic> createState() => _TapHandMechanicState();
}

class _TapHandMechanicState extends State<TapHandMechanic>
    with SingleTickerProviderStateMixin {
  final _ladder = HintLadder();
  int _round = 0;
  int _celebrate = 0;
  bool _busy = false;
  ClockHand? _flash;
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  ClockHand get _asked => widget.rounds[_round];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.intro != null) await widget.controller.say(widget.intro!);
      if (mounted) await _ask();
    });
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  Future<void> _ask() => widget.controller
      .say(_asked == ClockHand.hour ? Lines.s1TapHour : Lines.s1TapMinute);

  Future<void> _tap(Offset local, Size size) async {
    if (_busy) return;
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;
    final r = (local - center).distance / radius;
    if (r > 1.1) return;
    final angle = AngleMapper.angleFromCenter(
        centerX: center.dx, centerY: center.dy, x: local.dx, y: local.dy);
    final hit = ClockDragLogic.pickHand(
      time: widget.time,
      touchAngle: angle,
      radiusFraction: r,
      draggable: const {ClockHand.hour, ClockHand.minute},
    );
    if (hit == null) return;

    setState(() => _busy = true);
    if (hit == _asked) {
      setState(() {
        _flash = hit;
        _celebrate++;
      });
      await widget.controller.sayText(
          hit == ClockHand.hour ? 'Akrep! Kısa olan.' : 'Yelkovan! Uzun olan.');
      if (!mounted) return;
      if (_round + 1 < widget.rounds.length) {
        setState(() {
          _round++;
          _flash = null;
          _ladder.reset();
          _busy = false;
        });
        await _ask();
      } else {
        widget.controller.complete();
      }
      return;
    }

    widget.controller.mistake();
    setState(() => _ladder.fail());
    await widget.controller.say(
        _asked == ClockHand.hour ? Lines.s1TapWrongHour : Lines.s1TapWrongMinute);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return MechanicFrame(
      celebrate: _celebrate,
      header: Icon(
        Icons.touch_app_rounded,
        size: 44,
        color:
            _asked == ClockHand.hour ? ClockStyle.hourHand : ClockStyle.minuteHand,
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: ClockFrame(
            style: widget.frame,
            child: LayoutBuilder(builder: (context, c) {
              final side = math.min(c.maxWidth, c.maxHeight);
              final size = Size.square(side);
              return Center(
                child: SizedBox.fromSize(
                  size: size,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) => _tap(d.localPosition, size),
                    child: AnimatedBuilder(
                      animation: _glow,
                      builder: (context, _) => CustomPaint(
                        painter: ClockFacePainter(
                          hourAngle: widget.time.hourHandAngle,
                          minuteAngle: widget.time.minuteHandAngle,
                          glowHour: _flash == ClockHand.hour ||
                              (_ladder.glowHand && _asked == ClockHand.hour),
                          glowMinute: _flash == ClockHand.minute ||
                              (_ladder.glowHand &&
                                  _asked == ClockHand.minute),
                          glowPhase: _glow.value,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
