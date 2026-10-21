import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/angle_mapper.dart';
import '../../core/clock_time.dart';
import '../audio/sfx.dart';
import 'clock_drag_logic.dart';
import 'clock_face.dart';

export 'clock_drag_logic.dart' show ClockHand;

/// Ekrandaki büyük, dokunmatik analog saat. Hangi ellerin sürüklenebildiği,
/// dakika adımı, yardım parıltıları ve hedefin hayalet gösterimi dışarıdan
/// verilir. Saat mantığı [ClockDragLogic] içinde, burada yalnız jest ve çizim.
class DraggableClock extends StatefulWidget {
  final ClockTime time;
  final ValueChanged<ClockTime>? onChanged;
  final VoidCallback? onDragEnd;
  final Set<ClockHand> draggable;
  final Set<ClockHand> visibleHands;
  final int minuteStep;
  final bool linkHands;
  final Set<ClockHand> glowHands;
  final bool glowNumerals;
  final ClockTime? ghostTime;
  final Set<ClockHand> ghostHands;
  final bool showNumerals;

  const DraggableClock({
    super.key,
    required this.time,
    this.onChanged,
    this.onDragEnd,
    this.draggable = const {ClockHand.hour, ClockHand.minute},
    this.visibleHands = const {ClockHand.hour, ClockHand.minute},
    this.minuteStep = 1,
    this.linkHands = true,
    this.glowHands = const {},
    this.glowNumerals = false,
    this.ghostTime,
    this.ghostHands = const {ClockHand.hour, ClockHand.minute},
    this.showNumerals = true,
  });

  @override
  State<DraggableClock> createState() => _DraggableClockState();
}

class _DraggableClockState extends State<DraggableClock>
    with SingleTickerProviderStateMixin {
  ClockHand? _active;
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  bool get _anyGlow => widget.glowHands.isNotEmpty || widget.glowNumerals;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final side = math.min(constraints.maxWidth, constraints.maxHeight);
      final size = Size.square(side);
      final center = size.center(Offset.zero);
      final radius = side / 2;

      double angleOf(Offset p) => AngleMapper.angleFromCenter(
          centerX: center.dx, centerY: center.dy, x: p.dx, y: p.dy);

      void onStart(DragStartDetails d) {
        final p = d.localPosition;
        final r = (p - center).distance / radius;
        if (r > 1.15) return;
        setState(() {
          _active = ClockDragLogic.pickHand(
            time: widget.time,
            touchAngle: angleOf(p),
            radiusFraction: r,
            draggable: widget.draggable,
          );
        });
      }

      void onUpdate(DragUpdateDetails d) {
        final hand = _active;
        if (hand == null) return;
        final angle = angleOf(d.localPosition);
        final next = switch (hand) {
          ClockHand.minute => ClockDragLogic.dragMinute(
              widget.time,
              angle,
              minuteStep: widget.minuteStep,
              linkHours: widget.linkHands,
            ),
          ClockHand.hour => ClockDragLogic.dragHour(widget.time, angle),
        };
        if (next != widget.time) {
          Sfx.instance.tick();
          widget.onChanged?.call(next);
        }
      }

      void onEnd([dynamic _]) {
        if (_active != null) {
          setState(() => _active = null);
          widget.onDragEnd?.call();
        }
      }

      final interactive = widget.draggable.isNotEmpty;

      return Center(
        child: SizedBox.fromSize(
          size: size,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: interactive ? onStart : null,
            onPanUpdate: interactive ? onUpdate : null,
            onPanEnd: interactive ? onEnd : null,
            onPanCancel: interactive ? onEnd : null,
            child: AnimatedBuilder(
              animation: _glow,
              builder: (context, _) => CustomPaint(
                painter: ClockFacePainter(
                  hourAngle: widget.visibleHands.contains(ClockHand.hour)
                      ? widget.time.hourHandAngle
                      : null,
                  minuteAngle: widget.visibleHands.contains(ClockHand.minute)
                      ? widget.time.minuteHandAngle
                      : null,
                  ghostHourAngle: widget.ghostTime != null &&
                          widget.ghostHands.contains(ClockHand.hour)
                      ? widget.ghostTime!.hourHandAngle
                      : null,
                  ghostMinuteAngle: widget.ghostTime != null &&
                          widget.ghostHands.contains(ClockHand.minute)
                      ? widget.ghostTime!.minuteHandAngle
                      : null,
                  glowHour: widget.glowHands.contains(ClockHand.hour) ||
                      _active == ClockHand.hour,
                  glowMinute: widget.glowHands.contains(ClockHand.minute) ||
                      _active == ClockHand.minute,
                  glowNumerals: widget.glowNumerals,
                  glowPhase: _anyGlow ? _glow.value : (_active != null ? 1 : 1),
                  showNumerals: widget.showNumerals,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
