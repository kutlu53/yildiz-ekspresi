import 'package:flutter/material.dart';

import '../../core/clock_time.dart';
import '../../shared/widgets/clock_face.dart';
import 'pose_frame.dart';

/// Kamera önizlemesinin üstüne yarı saydam kadran, çocuğun kollarını ve
/// varsa hedef saatin hayalet ellerini çizer. Koordinatlar [PoseFrame]'deki
/// gibi ayna görünümünde ve 0-1 normalize kabul edilir.
class PoseOverlayPainter extends CustomPainter {
  final PoseFrame frame;
  final ClockTime? target;
  final bool matched;

  PoseOverlayPainter({
    required this.frame,
    this.target,
    this.matched = false,
  });

  Offset _toPixels(PosePoint p, Size size) =>
      Offset(p.x * size.width, p.y * size.height);

  @override
  void paint(Canvas canvas, Size size) {
    final centerPoint = frame.shoulderCenter;
    if (centerPoint == null) return;

    final center = _toPixels(centerPoint, size);
    final armPx = frame.armLength * size.height;
    final radius = (armPx * 1.1).clamp(size.height * 0.15, size.height * 0.48);

    ClockFacePainter.paintDial(canvas, center, radius,
        opacity: matched ? 0.55 : 0.35, showNumerals: true);

    if (target != null) {
      ClockFacePainter.paintHand(canvas, center, radius, target!.hourHandAngle,
          isHour: true, opacity: 0.25);
      ClockFacePainter.paintHand(
          canvas, center, radius, target!.minuteHandAngle,
          isHour: false, opacity: 0.25);
    }

    _paintArm(canvas, size, frame.hourArm, ClockStyle.hourHand, radius * 0.07);
    _paintArm(
        canvas, size, frame.minuteArm, ClockStyle.minuteHand, radius * 0.045);

    ClockFacePainter.paintCenterPin(canvas, center, radius, opacity: 0.8);

    if (matched) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0xFF43A047)
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.08,
      );
    }
  }

  void _paintArm(
      Canvas canvas, Size size, ArmReading? arm, Color color, double width) {
    if (arm == null) return;
    final shoulder = _toPixels(arm.shoulder, size);
    final wrist = _toPixels(arm.wrist, size);
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(shoulder, wrist, paint);
    canvas.drawCircle(wrist, width * 0.9, Paint()..color = color);
    canvas.drawCircle(
        shoulder, width * 0.6, Paint()..color = color.withValues(alpha: 0.7));
  }

  @override
  bool shouldRepaint(PoseOverlayPainter old) =>
      old.frame != frame || old.target != target || old.matched != matched;
}
