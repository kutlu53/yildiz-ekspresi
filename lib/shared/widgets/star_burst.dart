import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../audio/sfx.dart';

/// Başarıda patlayan yıldızlar ve konfeti. `play` değeri her değiştiğinde
/// yeniden oynar. `big` açıkken daha çok parça, daha uzun süre (durak sonu,
/// jenerik); ses `silent` ile kapatılabilir.
class StarBurst extends StatefulWidget {
  final int play;
  final bool big;
  final bool silent;

  const StarBurst({
    super.key,
    required this.play,
    this.big = false,
    this.silent = false,
  });

  @override
  State<StarBurst> createState() => _StarBurstState();
}

class _StarBurstState extends State<StarBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.big ? 2600 : 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.play > 0) _c.forward(from: 0);
  }

  @override
  void didUpdateWidget(StarBurst old) {
    super.didUpdateWidget(old);
    if (old.play != widget.play && widget.play > 0) {
      _c.forward(from: 0);
      if (!widget.silent) Sfx.instance.play(SfxId.success);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _BurstPainter(_c.value, _c.isAnimating, widget.big),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  final double t;
  final bool active;
  final bool big;

  static const _colors = [
    Color(0xFFFFD54F),
    Color(0xFFFF8A65),
    Color(0xFF4FC3F7),
    Color(0xFFAED581),
    Color(0xFFF06292),
    Color(0xFFBA68C8),
  ];

  _BurstPainter(this.t, this.active, this.big);

  @override
  void paint(Canvas canvas, Size size) {
    if (!active) return;
    final center = big
        ? Offset(size.width / 2, size.height * 0.35)
        : size.center(Offset.zero);
    final rnd = math.Random(3);

    // Yıldızlar: merkezden dışa
    final stars = big ? 36 : 24;
    final reach = size.shortestSide * (big ? 0.7 : 0.55);
    final st = (t * (big ? 1.6 : 1.0)).clamp(0.0, 1.0);
    for (var i = 0; i < stars; i++) {
      final angle = i / stars * 2 * math.pi + rnd.nextDouble() * 0.2;
      final dist = reach *
          Curves.easeOut.transform(st) *
          (0.6 + rnd.nextDouble() * 0.4);
      final p = center + Offset(math.cos(angle), math.sin(angle)) * dist;
      final r = (6 + rnd.nextDouble() * 6) * (1 - st * 0.6);
      _star(canvas, p, r,
          _colors[i % _colors.length].withValues(alpha: (1 - st).clamp(0, 1)));
    }

    // Konfeti: yukarı fırlar, yerçekimiyle düşer, döner
    final pieces = big ? 90 : 36;
    final g = size.height * 1.6;
    for (var i = 0; i < pieces; i++) {
      final angle = -math.pi / 2 + (rnd.nextDouble() - 0.5) * (big ? 2.4 : 1.8);
      final speed = size.shortestSide * (0.5 + rnd.nextDouble() * 0.9);
      final spin = rnd.nextDouble() * 10;
      final tt = t * (big ? 2.2 : 1.6);
      final x = center.dx + math.cos(angle) * speed * tt;
      final y = center.dy + math.sin(angle) * speed * tt + 0.5 * g * tt * tt;
      if (y > size.height + 20) continue;
      final alpha = (1 - t * 0.9).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = _colors[(i * 7) % _colors.length].withValues(alpha: alpha);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(spin * tt);
      final w = 6 + rnd.nextDouble() * 6;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: w, height: w * 0.5),
            const Radius.circular(2)),
        paint,
      );
      canvas.restore();
    }
  }

  void _star(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rr = i.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = c + Offset(math.cos(a), math.sin(a)) * rr;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BurstPainter old) =>
      old.t != t || old.active != active || old.big != big;
}
