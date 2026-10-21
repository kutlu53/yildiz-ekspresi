import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'steam_puffs.dart';

/// Yıldız Ekspresi: lokomotif ve vagonlar, yandan görünüş. `t` 0-1 arası
/// animasyon fazı; `moving` açıkken tekerlekler döner, buhar çıkar.
class Train extends StatefulWidget {
  final int wagons;
  final bool moving;
  final double height;

  const Train({
    super.key,
    this.wagons = 1,
    this.moving = false,
    this.height = 80,
  });

  @override
  State<Train> createState() => _TrainState();
}

class _TrainState extends State<Train> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.height * (2.2 + widget.wagons * 1.4);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        size: Size(width, widget.height),
        painter: TrainPainter(
          wagons: widget.wagons,
          t: _c.value,
          moving: widget.moving,
        ),
      ),
    );
  }
}

class TrainPainter extends CustomPainter {
  final int wagons;
  final double t;
  final bool moving;

  static const _body = Color(0xFF5E35B1);
  static const _accent = Color(0xFFFFB300);
  static const _wagon = Color(0xFF43A047);
  static const _dark = Color(0xFF263238);

  TrainPainter({required this.wagons, required this.t, required this.moving});

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final unit = h / 80;
    final wagonW = 110 * unit;
    final locoW = 150 * unit;
    final groundY = h - 8 * unit;

    var x = size.width - locoW;
    _locomotive(canvas, Offset(x, 0), locoW, h, unit, groundY);
    for (var i = 0; i < wagons; i++) {
      x -= wagonW + 6 * unit;
      _wagonAt(canvas, Offset(x, 0), wagonW, h, unit, groundY);
    }
  }

  void _wheel(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c, r, Paint()..color = _dark);
    canvas.drawCircle(c, r * 0.55, Paint()..color = _accent);
    final spoke = Paint()
      ..color = _dark
      ..strokeWidth = r * 0.25;
    final a = moving ? t * 2 * math.pi : 0.0;
    canvas.drawLine(c + Offset(math.cos(a), math.sin(a)) * r * 0.5,
        c - Offset(math.cos(a), math.sin(a)) * r * 0.5, spoke);
  }

  void _locomotive(Canvas canvas, Offset o, double w, double h, double u,
      double groundY) {
    final body = Paint()..color = _body;
    // Kazan
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(o.dx + 40 * u, groundY - 42 * u, w - 50 * u, 30 * u),
          Radius.circular(10 * u)),
      body,
    );
    // Kabin
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(o.dx, groundY - 60 * u, 48 * u, 48 * u),
          Radius.circular(6 * u)),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(o.dx + 8 * u, groundY - 52 * u, 30 * u, 20 * u),
          Radius.circular(4 * u)),
      Paint()..color = const Color(0xFFB3E5FC),
    );
    // Baca
    canvas.drawRect(
        Rect.fromLTWH(o.dx + w - 40 * u, groundY - 62 * u, 14 * u, 22 * u),
        Paint()..color = _dark);
    // Ön
    canvas.drawRect(
        Rect.fromLTWH(o.dx + w - 10 * u, groundY - 30 * u, 10 * u, 18 * u),
        Paint()..color = _accent);
    // Tekerlekler
    _wheel(canvas, Offset(o.dx + 18 * u, groundY), 10 * u);
    _wheel(canvas, Offset(o.dx + 60 * u, groundY), 12 * u);
    _wheel(canvas, Offset(o.dx + 100 * u, groundY), 12 * u);
    // Buhar: yolda kabarık ve çok, dururken tembel ve küçük
    final chimney = Offset(o.dx + w - 33 * u, groundY - 62 * u);
    if (moving) {
      SteamPainter.paintPuffs(canvas, chimney, 70 * u, t: t, count: 5, drift: -0.7);
    } else {
      SteamPainter.paintPuffs(canvas, chimney, 30 * u,
          t: (t * 0.5) % 1, count: 2, drift: -0.2);
    }
  }

  void _wagonAt(Canvas canvas, Offset o, double w, double h, double u,
      double groundY) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(o.dx, groundY - 44 * u, w, 34 * u),
          Radius.circular(6 * u)),
      Paint()..color = _wagon,
    );
    for (var i = 0; i < 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(o.dx + (10 + i * 34) * u, groundY - 38 * u, 22 * u,
                14 * u),
            Radius.circular(3 * u)),
        Paint()..color = const Color(0xFFB3E5FC),
      );
    }
    _wheel(canvas, Offset(o.dx + 20 * u, groundY), 9 * u);
    _wheel(canvas, Offset(o.dx + w - 20 * u, groundY), 9 * u);
  }

  @override
  bool shouldRepaint(TrainPainter old) =>
      old.t != t || old.wagons != wagons || old.moving != moving;
}
