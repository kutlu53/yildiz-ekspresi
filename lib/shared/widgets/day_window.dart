import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Vagon penceresi: `hour` (0-24, kesirli olabilir) ilerledikçe gökyüzü
/// değişir; güneş doğar, tepeye çıkar, batar, ay ve yıldızlar çıkar.
/// Durak 6'da günün akışını somutlaştırır; başka duraklarda küçük boyutta
/// "sabah mı akşam mı" ipucu olarak kullanılabilir.
class DayWindow extends StatelessWidget {
  final double hour;
  final double width;
  final double height;
  final bool highlighted;

  const DayWindow({
    super.key,
    required this.hour,
    this.width = 160,
    this.height = 110,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFFFD54F) : const Color(0xFF5D4037),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(blurRadius: 8, color: Colors.black38, offset: Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: CustomPaint(
          painter: DayWindowPainter(hour: hour),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class DayWindowPainter extends CustomPainter {
  final double hour;

  DayWindowPainter({required this.hour});

  static const _keys = <(double, Color, Color)>[
    (0, Color(0xFF0D1B3E), Color(0xFF1A237E)),
    (5, Color(0xFF283593), Color(0xFF5C6BC0)),
    (7, Color(0xFF64B5F6), Color(0xFFFFB74D)),
    (10, Color(0xFF42A5F5), Color(0xFFBBDEFB)),
    (14, Color(0xFF29B6F6), Color(0xFFE1F5FE)),
    (17, Color(0xFF7986CB), Color(0xFFFF8A65)),
    (19, Color(0xFF283593), Color(0xFF5C6BC0)),
    (21, Color(0xFF0D1B3E), Color(0xFF1A237E)),
    (24, Color(0xFF0D1B3E), Color(0xFF1A237E)),
  ];

  /// Verilen saatteki gökyüzü renkleri (üst, alt).
  static (Color, Color) skyColors(double hour) {
    final h = ((hour % 24) + 24) % 24;
    for (var i = 0; i < _keys.length - 1; i++) {
      final (h0, t0, b0) = _keys[i];
      final (h1, t1, b1) = _keys[i + 1];
      if (h >= h0 && h <= h1) {
        final f = (h - h0) / (h1 - h0);
        return (Color.lerp(t0, t1, f)!, Color.lerp(b0, b1, f)!);
      }
    }
    return (_keys.last.$2, _keys.last.$3);
  }

  /// Karanlık derecesi 0 (gündüz) - 1 (gece); yıldızların görünürlüğü.
  static double darkness(double hour) {
    final h = ((hour % 24) + 24) % 24;
    if (h >= 7 && h <= 17) return 0;
    if (h > 17 && h < 20) return (h - 17) / 3;
    if (h > 4 && h < 7) return (7 - h) / 3;
    return 1;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final (top, bottom) = skyColors(hour);
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(rect),
    );

    // Yıldızlar
    final dark = darkness(hour);
    if (dark > 0) {
      final rnd = math.Random(3);
      final star = Paint()..color = Colors.white.withValues(alpha: 0.9 * dark);
      for (var i = 0; i < 18; i++) {
        canvas.drawCircle(
          Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height * 0.6),
          1 + rnd.nextDouble() * 1.5,
          star,
        );
      }
    }

    // Güneş 6-18 arası yay çizer, ay 18-6 arası.
    final h = ((hour % 24) + 24) % 24;
    void body(double from, double to, Color color, double r, {bool moon = false}) {
      var f = (h - from) / (to - from);
      if (to < from) {
        final span = 24 - from + to;
        f = ((h - from + 24) % 24) / span;
        if (h > to && h < from) f = -1;
      }
      if (f < 0 || f > 1) return;
      final x = size.width * (0.1 + 0.8 * f);
      final y = size.height * (0.72 - 0.55 * math.sin(f * math.pi));
      if (!moon) {
        canvas.drawCircle(Offset(x, y), r * 1.8,
            Paint()..color = color.withValues(alpha: 0.25));
      }
      canvas.drawCircle(Offset(x, y), r, Paint()..color = color);
      if (moon) {
        canvas.drawCircle(Offset(x + r * 0.4, y - r * 0.2), r * 0.8,
            Paint()..color = skyColors(hour).$1);
      }
    }

    body(5.5, 18.5, const Color(0xFFFFEE58), size.shortestSide * 0.13);
    body(18.5, 5.5, const Color(0xFFFFF9C4), size.shortestSide * 0.1, moon: true);

    // Tepeler ve ağaçlar: karanlıkta koyulaşır.
    final hill = Paint()
      ..color = Color.lerp(const Color(0xFF66BB6A), const Color(0xFF1B3A2A), dark)!;
    final path = Path()..moveTo(0, size.height);
    for (var x = 0.0; x <= size.width; x += 4) {
      path.lineTo(x, size.height * (0.78 + 0.08 * math.sin(x / size.width * math.pi * 2.3)));
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, hill);
    final tree = Paint()
      ..color = Color.lerp(const Color(0xFF2E7D32), const Color(0xFF0F2A1C), dark)!;
    for (final fx in [0.2, 0.55, 0.85]) {
      final bx = size.width * fx;
      final by = size.height * 0.8;
      canvas.drawPath(
        Path()
          ..moveTo(bx - 9, by)
          ..lineTo(bx, by - 22)
          ..lineTo(bx + 9, by)
          ..close(),
        tree,
      );
    }
  }

  @override
  bool shouldRepaint(DayWindowPainter old) => old.hour != hour;
}
