import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/story/models.dart';

/// Pamuk: kodla çizilen vektör ayı. Rive dosyası geldiğinde bu widget aynı
/// arayüzle (mood) Rive'a bağlanacak.
class Pamuk extends StatefulWidget {
  final PamukMood mood;
  final double size;
  final bool scarf;

  const Pamuk({
    super.key,
    this.mood = PamukMood.idle,
    this.size = 160,
    this.scarf = false,
  });

  @override
  State<Pamuk> createState() => _PamukState();
}

class _PamukState extends State<Pamuk> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        size: Size.square(widget.size),
        painter: PamukPainter(
          mood: widget.mood,
          t: _c.value,
          scarf: widget.scarf,
        ),
      ),
    );
  }
}

class PamukPainter extends CustomPainter {
  final PamukMood mood;
  final double t;
  final bool scarf;

  static const _fur = Color(0xFF8D6E63);
  static const _furLight = Color(0xFFD7CCC8);
  static const _dark = Color(0xFF3E2723);
  static const _scarf = Color(0xFFE53935);

  PamukPainter({required this.mood, required this.t, this.scarf = false});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas.save();
    canvas.scale(s, s);

    final breathe = math.sin(t * 2 * math.pi) * 1.2;
    final bounce = mood == PamukMood.happy
        ? -math.sin(t * 2 * math.pi).abs() * 4
        : 0.0;
    canvas.translate(0, bounce);

    final fur = Paint()..color = _fur;
    final light = Paint()..color = _furLight;
    final dark = Paint()..color = _dark;

    // Kollar
    final armLift = mood == PamukMood.happy ? -14.0 : 0.0;
    _ellipse(canvas, Offset(24, 68 + armLift), 8, 12, fur,
        rotation: mood == PamukMood.happy ? -0.6 : 0.2);
    _ellipse(canvas, Offset(76, 68 + armLift), 8, 12, fur,
        rotation: mood == PamukMood.happy ? 0.6 : -0.2);

    // Gövde ve karın
    _ellipse(canvas, const Offset(50, 72), 28, 24 + breathe, fur);
    _ellipse(canvas, const Offset(50, 76), 16, 14 + breathe * 0.6, light);

    // Kulaklar
    canvas.drawCircle(const Offset(32, 22), 9, fur);
    canvas.drawCircle(const Offset(68, 22), 9, fur);
    canvas.drawCircle(const Offset(32, 22), 5, light);
    canvas.drawCircle(const Offset(68, 22), 5, light);

    // Baş
    canvas.drawCircle(const Offset(50, 40), 24, fur);
    _ellipse(canvas, const Offset(50, 49), 11, 8, light);
    _ellipse(canvas, const Offset(50, 45), 4, 3, dark);

    // Gözler
    final closed = mood == PamukMood.sleepy;
    final blink = !closed && (t % 1.0) > 0.92;
    if (closed || blink) {
      final p = Paint()
        ..color = _dark
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawArc(
          const Rect.fromLTWH(37, 34, 8, 6), 0.2, math.pi - 0.4, false, p);
      canvas.drawArc(
          const Rect.fromLTWH(55, 34, 8, 6), 0.2, math.pi - 0.4, false, p);
    } else {
      canvas.drawCircle(const Offset(41, 37), 3, dark);
      canvas.drawCircle(const Offset(59, 37), 3, dark);
      canvas.drawCircle(const Offset(42, 36), 1, Paint()..color = Colors.white);
      canvas.drawCircle(const Offset(60, 36), 1, Paint()..color = Colors.white);
      if (mood == PamukMood.thinking) {
        // Kaş
        final p = Paint()
          ..color = _dark
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(const Offset(55, 31), const Offset(62, 33), p);
      }
    }

    // Ağız
    final mouth = Paint()
      ..color = _dark
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    switch (mood) {
      case PamukMood.talking:
        final open = 2 + (math.sin(t * 2 * math.pi * 4).abs()) * 4;
        _ellipse(canvas, const Offset(50, 55), 3.5, open, dark);
      case PamukMood.happy:
        canvas.drawArc(const Rect.fromLTWH(43, 50, 14, 9), 0.15,
            math.pi - 0.3, false, mouth);
      case PamukMood.sleepy:
        _ellipse(canvas, const Offset(50, 55), 2.5, 2, dark);
      case PamukMood.thinking:
        canvas.drawLine(const Offset(46, 55), const Offset(53, 54), mouth);
      case PamukMood.idle:
        canvas.drawArc(const Rect.fromLTWH(45, 51, 10, 6), 0.3,
            math.pi - 0.6, false, mouth);
    }

    // Atkı
    if (scarf) {
      final p = Paint()..color = _scarf;
      _ellipse(canvas, const Offset(50, 62), 20, 5, p);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(58, 62, 7, 16), const Radius.circular(3)),
        p,
      );
    }

    // Uyku: z harfleri
    if (mood == PamukMood.sleepy) {
      final style = TextStyle(
        color: _dark.withValues(alpha: 1 - t),
        fontSize: 8 + t * 6,
        fontWeight: FontWeight.w800,
      );
      final tp = TextPainter(
        text: TextSpan(text: 'z', style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(70 + t * 10, 20 - t * 18));
    }

    canvas.restore();
  }

  void _ellipse(Canvas canvas, Offset c, double rx, double ry, Paint p,
      {double rotation = 0}) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rotation);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2), p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(PamukPainter old) =>
      old.t != t || old.mood != mood || old.scarf != scarf;
}
