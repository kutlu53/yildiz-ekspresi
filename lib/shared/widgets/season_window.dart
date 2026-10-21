import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/year.dart';

/// Mevsim penceresi: yüklenen mevsime göre manzara (ilkbahar çiçek, yaz
/// güneş, sonbahar yaprak, kış kar). `season` null ise boş vadi.
class SeasonWindow extends StatelessWidget {
  final int? season;
  final double width;
  final double height;

  const SeasonWindow({
    super.key,
    required this.season,
    this.width = 170,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF5D4037),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(blurRadius: 8, color: Colors.black38, offset: Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: CustomPaint(
          painter: SeasonPainter(season: season),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class SeasonPainter extends CustomPainter {
  final int? season;

  SeasonPainter({required this.season});

  @override
  void paint(Canvas canvas, Size size) {
    final s = season;
    final sky = switch (s) {
      Year.summer => const Color(0xFF29B6F6),
      Year.autumn => const Color(0xFF90A4AE),
      Year.winter => const Color(0xFFCFD8DC),
      Year.spring => const Color(0xFF64B5F6),
      _ => const Color(0xFF90CAF9),
    };
    final ground = switch (s) {
      Year.summer => const Color(0xFFD4E157),
      Year.autumn => const Color(0xFFFF8A65),
      Year.winter => Colors.white,
      Year.spring => const Color(0xFF66BB6A),
      _ => const Color(0xFFA5D6A7),
    };
    canvas.drawRect(Offset.zero & size, Paint()..color = sky);
    final hill = Path()..moveTo(0, size.height);
    for (var x = 0.0; x <= size.width; x += 4) {
      hill.lineTo(x, size.height * (0.6 + 0.1 * math.sin(x / size.width * math.pi * 2)));
    }
    hill
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(hill, Paint()..color = ground);

    final rnd = math.Random(5);
    switch (s) {
      case Year.spring:
        for (var i = 0; i < 8; i++) {
          final p = Offset(rnd.nextDouble() * size.width, size.height * (0.68 + rnd.nextDouble() * 0.25));
          canvas.drawCircle(p, 4, Paint()..color = const Color(0xFFF06292));
          canvas.drawCircle(p, 1.5, Paint()..color = const Color(0xFFFFEB3B));
        }
      case Year.summer:
        canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.25),
            size.shortestSide * 0.16, Paint()..color = const Color(0xFFFFEE58));
      case Year.autumn:
        for (var i = 0; i < 8; i++) {
          final p = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
          canvas.drawOval(
              Rect.fromCenter(center: p, width: 10, height: 6),
              Paint()..color = const Color(0xFFBF360C));
        }
      case Year.winter:
        for (var i = 0; i < 14; i++) {
          canvas.drawCircle(
              Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
              2, Paint()..color = Colors.white);
        }
      default:
        break;
    }
    // Ağaç: mevsime göre taç rengi
    final trunk = Paint()..color = const Color(0xFF5D4037);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.3 - 3, size.height * 0.45, 6, size.height * 0.25), trunk);
    final crown = switch (s) {
      Year.autumn => const Color(0xFFFF7043),
      Year.winter => const Color(0xFFECEFF1),
      Year.summer => const Color(0xFF2E7D32),
      Year.spring => const Color(0xFF81C784),
      _ => const Color(0xFFA5D6A7),
    };
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.4), size.shortestSide * 0.18, Paint()..color = crown);
  }

  @override
  bool shouldRepaint(SeasonPainter old) => old.season != season;
}
