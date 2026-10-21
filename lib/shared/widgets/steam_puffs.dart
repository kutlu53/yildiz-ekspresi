import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Buhar bulutları: `active` açılınca birkaç kabarık puf yükselir, büyür ve
/// solar. Kalkış kolu, lokomotif bacası ve kutlamalar için.
class SteamPuffs extends StatefulWidget {
  final bool active;
  final double size;
  final bool loop;

  const SteamPuffs({
    super.key,
    required this.active,
    this.size = 60,
    this.loop = false,
  });

  @override
  State<SteamPuffs> createState() => _SteamPuffsState();
}

class _SteamPuffsState extends State<SteamPuffs>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(SteamPuffs old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active || old.loop != widget.loop) _sync();
  }

  void _sync() {
    if (!widget.active) {
      _c.stop();
      return;
    }
    if (widget.loop) {
      _c.repeat();
    } else {
      _c.forward(from: 0);
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
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: SteamPainter(t: _c.value, active: _c.isAnimating),
          ),
        ),
      ),
    );
  }
}

class SteamPainter extends CustomPainter {
  final double t;
  final bool active;

  SteamPainter({required this.t, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    if (!active) return;
    paintPuffs(canvas, Offset(size.width / 2, size.height), size.shortestSide,
        t: t);
  }

  /// `origin` noktasından yukarı yükselen kabarık pufları çizer. Lokomotif
  /// bacası da bu yardımcıyı kullanır.
  static void paintPuffs(Canvas canvas, Offset origin, double scale,
      {required double t, int count = 4, double drift = -0.4}) {
    final rnd = math.Random(5);
    for (var i = 0; i < count; i++) {
      final phase = (t + i / count) % 1;
      final jitter = rnd.nextDouble() - 0.5;
      final c = origin +
          Offset((drift * phase + jitter * 0.2) * scale, -phase * scale * 0.9);
      final r = scale * (0.08 + phase * 0.16);
      final alpha = (0.85 * (1 - phase)).clamp(0.0, 1.0);
      final p = Paint()..color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(c, r, p);
      canvas.drawCircle(c + Offset(r * 0.7, r * 0.2), r * 0.8, p);
      canvas.drawCircle(c + Offset(-r * 0.6, r * 0.25), r * 0.7, p);
    }
  }

  @override
  bool shouldRepaint(SteamPainter old) => old.t != t || old.active != active;
}
