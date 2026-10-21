import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Akrep ve yelkovanın her yerde aynı olan renk, boy ve kalınlık kuralları.
class ClockStyle {
  ClockStyle._();

  static const Color hourHand = Color(0xFFE53935); // akrep: kırmızı
  static const Color minuteHand = Color(0xFF1E88E5); // yelkovan: mavi
  static const Color dial = Color(0xFFFFFDF5);
  static const Color dialBorder = Color(0xFF37474F);
  static const Color tick = Color(0xFF546E7A);
  static const Color numeral = Color(0xFF263238);
  static const Color glow = Color(0xFFFFD54F);

  /// Kadran yarıçapına oranla el uzunlukları.
  static const double hourHandLength = 0.55;
  static const double minuteHandLength = 0.82;

  /// Kadran yarıçapına oranla el kalınlıkları.
  static const double hourHandWidth = 0.075;
  static const double minuteHandWidth = 0.045;
}

/// Kadran ve elleri çizen yardımcı. Hem ekrandaki sürüklenebilir saat hem
/// de kamera bindirmesi bu fonksiyonları kullanır.
class ClockFacePainter extends CustomPainter {
  final double? hourAngle;
  final double? minuteAngle;
  final double? ghostHourAngle;
  final double? ghostMinuteAngle;
  final double opacity;
  final bool showNumerals;
  final bool glowHour;
  final bool glowMinute;
  final bool glowNumerals;
  final double glowPhase;

  ClockFacePainter({
    this.hourAngle,
    this.minuteAngle,
    this.ghostHourAngle,
    this.ghostMinuteAngle,
    this.opacity = 1,
    this.showNumerals = true,
    this.glowHour = false,
    this.glowMinute = false,
    this.glowNumerals = false,
    this.glowPhase = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;
    paintDial(canvas, center, radius,
        opacity: opacity,
        showNumerals: showNumerals,
        glowNumerals: glowNumerals,
        glowPhase: glowPhase);

    if (ghostHourAngle != null) {
      paintHand(canvas, center, radius, ghostHourAngle!,
          isHour: true, opacity: 0.25 * opacity);
    }
    if (ghostMinuteAngle != null) {
      paintHand(canvas, center, radius, ghostMinuteAngle!,
          isHour: false, opacity: 0.25 * opacity);
    }
    if (hourAngle != null) {
      if (glowHour) {
        paintGlow(canvas, center, radius, hourAngle!,
            isHour: true, phase: glowPhase);
      }
      paintHand(canvas, center, radius, hourAngle!,
          isHour: true, opacity: opacity);
    }
    if (minuteAngle != null) {
      if (glowMinute) {
        paintGlow(canvas, center, radius, minuteAngle!,
            isHour: false, phase: glowPhase);
      }
      paintHand(canvas, center, radius, minuteAngle!,
          isHour: false, opacity: opacity);
    }
    paintCenterPin(canvas, center, radius, opacity: opacity);
  }

  static Offset pointAt(Offset center, double radius, double angleDeg) {
    final rad = (angleDeg - 90) * math.pi / 180;
    return center + Offset(math.cos(rad), math.sin(rad)) * radius;
  }

  static void paintDial(
    Canvas canvas,
    Offset center,
    double radius, {
    double opacity = 1,
    bool showNumerals = true,
    bool glowNumerals = false,
    double glowPhase = 1,
  }) {
    final fill = Paint()..color = ClockStyle.dial.withValues(alpha: opacity);
    final border = Paint()
      ..color = ClockStyle.dialBorder.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.05;
    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle(center, radius, border);

    final tickPaint = Paint()
      ..color = ClockStyle.tick.withValues(alpha: opacity)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 60; i++) {
      final isHour = i % 5 == 0;
      tickPaint.strokeWidth = radius * (isHour ? 0.035 : 0.015);
      final outer = pointAt(center, radius * 0.93, i * 6.0);
      final inner = pointAt(center, radius * (isHour ? 0.82 : 0.88), i * 6.0);
      canvas.drawLine(inner, outer, tickPaint);
    }

    if (showNumerals) {
      final style = TextStyle(
        color: ClockStyle.numeral.withValues(alpha: opacity),
        fontSize: radius * 0.2,
        fontWeight: FontWeight.w700,
      );
      for (var h = 1; h <= 12; h++) {
        final pos = pointAt(center, radius * 0.68, h * 30.0);
        if (glowNumerals) {
          canvas.drawCircle(
            pos,
            radius * 0.13,
            Paint()
              ..color = ClockStyle.glow.withValues(alpha: 0.35 + 0.4 * glowPhase),
          );
        }
        final tp = TextPainter(
          text: TextSpan(text: '$h', style: style),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
      }
    }
  }

  static void paintHand(
    Canvas canvas,
    Offset center,
    double radius,
    double angleDeg, {
    required bool isHour,
    double opacity = 1,
  }) {
    final paint = Paint()
      ..color = (isHour ? ClockStyle.hourHand : ClockStyle.minuteHand)
          .withValues(alpha: opacity)
      ..strokeWidth = radius *
          (isHour ? ClockStyle.hourHandWidth : ClockStyle.minuteHandWidth)
      ..strokeCap = StrokeCap.round;
    final length =
        isHour ? ClockStyle.hourHandLength : ClockStyle.minuteHandLength;
    final tail = pointAt(center, radius * 0.08, angleDeg + 180);
    canvas.drawLine(tail, pointAt(center, radius * length, angleDeg), paint);
  }

  static void paintGlow(
    Canvas canvas,
    Offset center,
    double radius,
    double angleDeg, {
    required bool isHour,
    double phase = 1,
  }) {
    final paint = Paint()
      ..color = ClockStyle.glow.withValues(alpha: 0.35 + 0.45 * phase)
      ..strokeWidth = radius *
          (isHour ? ClockStyle.hourHandWidth : ClockStyle.minuteHandWidth) *
          3
      ..strokeCap = StrokeCap.round;
    final length =
        isHour ? ClockStyle.hourHandLength : ClockStyle.minuteHandLength;
    final tail = pointAt(center, radius * 0.08, angleDeg + 180);
    canvas.drawLine(tail, pointAt(center, radius * length, angleDeg), paint);
  }

  static void paintCenterPin(Canvas canvas, Offset center, double radius,
      {double opacity = 1}) {
    canvas.drawCircle(
      center,
      radius * 0.05,
      Paint()..color = ClockStyle.dialBorder.withValues(alpha: opacity),
    );
  }

  @override
  bool shouldRepaint(ClockFacePainter old) =>
      old.hourAngle != hourAngle ||
      old.minuteAngle != minuteAngle ||
      old.ghostHourAngle != ghostHourAngle ||
      old.ghostMinuteAngle != ghostMinuteAngle ||
      old.opacity != opacity ||
      old.showNumerals != showNumerals ||
      old.glowHour != glowHour ||
      old.glowMinute != glowMinute ||
      old.glowNumerals != glowNumerals ||
      old.glowPhase != glowPhase;
}
