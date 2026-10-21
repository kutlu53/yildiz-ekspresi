import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/story/models.dart';

/// Durak dekoru. Gökyüzü mevsime göre değişir, her dekorun kendi ön planı
/// vardır. `moving` açıkken manzara akar (yolculuk).
class SceneryView extends StatefulWidget {
  final Scenery scenery;
  final double season;
  final bool moving;
  final Widget? child;

  const SceneryView({
    super.key,
    required this.scenery,
    required this.season,
    this.moving = false,
    this.child,
  });

  @override
  State<SceneryView> createState() => _SceneryViewState();
}

class _SceneryViewState extends State<SceneryView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
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
      builder: (context, child) => CustomPaint(
        painter: SceneryPainter(
          scenery: widget.scenery,
          season: widget.season.clamp(0, 1),
          t: _c.value,
          moving: widget.moving,
        ),
        child: child,
      ),
      child: widget.child ?? const SizedBox.expand(),
    );
  }
}

class SceneryPainter extends CustomPainter {
  final Scenery scenery;
  final double season;
  final double t;
  final bool moving;

  SceneryPainter({
    required this.scenery,
    required this.season,
    required this.t,
    required this.moving,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (scenery) {
      case Scenery.garage:
        _garage(canvas, size);
      case Scenery.station:
        _sky(canvas, size);
        _hills(canvas, size);
        _station(canvas, size);
      case Scenery.track:
        _sky(canvas, size);
        _hills(canvas, size);
        _track(canvas, size);
      case Scenery.bridge:
        _sky(canvas, size);
        _hills(canvas, size, base: 0.55);
        _bridge(canvas, size);
      case Scenery.tunnel:
        _tunnel(canvas, size);
      case Scenery.hall:
        _hall(canvas, size);
      case Scenery.cabin:
        _cabin(canvas, size);
      case Scenery.market:
        _sky(canvas, size);
        _hills(canvas, size, base: 0.5);
        _market(canvas, size);
      case Scenery.valley:
        _sky(canvas, size);
        _valley(canvas, size);
      case Scenery.snowfield:
        _sky(canvas, size);
        _snowfield(canvas, size);
      case Scenery.summit:
        _sky(canvas, size);
        _summit(canvas, size);
      case Scenery.den:
        _den(canvas, size);
    }
    final indoors = scenery == Scenery.tunnel ||
        scenery == Scenery.cabin ||
        scenery == Scenery.den;
    if (season > 0.7 && !indoors) _snow(canvas, size);
  }

  // ---- ortak parçalar ----

  void _sky(Canvas canvas, Size size) {
    final top = Color.lerp(const Color(0xFF64B5F6), const Color(0xFF90A4AE), season)!;
    final bottom =
        Color.lerp(const Color(0xFFFFE0B2), const Color(0xFFECEFF1), season)!;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(Offset.zero & size),
    );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.16),
      size.shortestSide * 0.07,
      Paint()
        ..color = Color.lerp(const Color(0xFFFFF176), const Color(0xFFFFFDE7), season)!,
    );
    // Bulutlar yavaşça kayar
    final cloud = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (var i = 0; i < 3; i++) {
      final x = ((i * 0.37 + t * 0.05 * (i + 1)) % 1.2 - 0.1) * size.width;
      final y = size.height * (0.1 + i * 0.07);
      final r = size.shortestSide * 0.035;
      canvas.drawCircle(Offset(x, y), r, cloud);
      canvas.drawCircle(Offset(x + r * 1.2, y + r * 0.2), r * 1.3, cloud);
      canvas.drawCircle(Offset(x + r * 2.6, y), r, cloud);
    }
  }

  void _hills(Canvas canvas, Size size, {double base = 0.62}) {
    final shift = moving ? t * size.width : 0.0;
    final far = Color.lerp(const Color(0xFFA5D6A7), const Color(0xFFCFD8DC), season)!;
    final near = Color.lerp(const Color(0xFFFF8A65), const Color(0xFFFFFFFF), season)!;
    _hillLayer(canvas, size, base, 0.08, 1.3, far, shift * 0.3);
    _hillLayer(canvas, size, base + 0.12, 0.07, 2.1, near, shift * 0.6);
  }

  void _hillLayer(Canvas canvas, Size size, double base, double amp,
      double freq, Color color, double shift) {
    final path = Path()..moveTo(0, size.height);
    for (var x = 0.0; x <= size.width; x += 8) {
      final y = size.height *
          (base + amp * math.sin((x + shift) / size.width * math.pi * freq + 0.5));
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _ground(Canvas canvas, Size size, {double from = 0.86}) {
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * from, size.width, size.height * (1 - from)),
      Paint()
        ..color = Color.lerp(const Color(0xFF8D6E63), const Color(0xFFECEFF1), season)!,
    );
  }

  void _rails(Canvas canvas, Size size) {
    final y = size.height * 0.955;
    final rail = Paint()
      ..color = const Color(0xFF546E7A)
      ..strokeWidth = 4;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), rail);
    canvas.drawLine(Offset(0, y + 10), Offset(size.width, y + 10), rail);
    final tie = Paint()..color = const Color(0xFF5D4037);
    final shift = moving ? (t * 400) % 40 : 0.0;
    for (var x = -40.0; x < size.width + 40; x += 40) {
      canvas.drawRect(Rect.fromLTWH(x - shift, y - 4, 16, 18), tie);
    }
  }

  void _snow(Canvas canvas, Size size) {
    final flakes = ((season - 0.7) / 0.3 * 40).round();
    final rnd = math.Random(7);
    final p = Paint()..color = Colors.white.withValues(alpha: 0.9);
    for (var i = 0; i < flakes; i++) {
      final x = rnd.nextDouble();
      final speed = 0.5 + rnd.nextDouble();
      final y = (rnd.nextDouble() + t * speed) % 1;
      canvas.drawCircle(
        Offset(x * size.width + math.sin((y + x) * 6) * 6, y * size.height),
        2 + rnd.nextDouble() * 2,
        p,
      );
    }
  }

  // ---- dekorlar ----

  void _station(Canvas canvas, Size size) {
    _ground(canvas, size);
    // Peron
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.8, size.width, size.height * 0.08),
      Paint()..color = const Color(0xFFB0BEC5),
    );
    _rails(canvas, size);
    // Bank
    final bench = Paint()..color = const Color(0xFF6D4C41);
    final bx = size.width * 0.62;
    final by = size.height * 0.74;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, 150, 14), const Radius.circular(4)),
      bench,
    );
    canvas.drawRect(Rect.fromLTWH(bx + 10, by + 14, 10, 34), bench);
    canvas.drawRect(Rect.fromLTWH(bx + 130, by + 14, 10, 34), bench);
    // Tabela direği ve lamba
    final post = Paint()..color = const Color(0xFF37474F);
    final px = size.width * 0.18;
    canvas.drawRect(Rect.fromLTWH(px, size.height * 0.42, 8, size.height * 0.38), post);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(px - 60, size.height * 0.42, 128, 36),
          const Radius.circular(6)),
      Paint()..color = const Color(0xFF1E88E5),
    );
    canvas.drawCircle(Offset(px + 4, size.height * 0.4),
        12, Paint()..color = const Color(0xFFFFF59D));
  }

  void _garage(Canvas canvas, Size size) {
    // Ahşap duvar
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF6D4C41));
    final plank = Paint()..color = const Color(0xFF5D4037);
    for (var y = 0.0; y < size.height; y += 36) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 3), plank);
    }
    // Yuvarlak pencere, dışarıda gökyüzü
    final wc = Offset(size.width * 0.8, size.height * 0.22);
    final wr = size.shortestSide * 0.12;
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: wc, radius: wr)));
    canvas.drawRect(
      Rect.fromCircle(center: wc, radius: wr),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF64B5F6), Color(0xFFFFE0B2)],
        ).createShader(Rect.fromCircle(center: wc, radius: wr)),
    );
    canvas.restore();
    canvas.drawCircle(
      wc,
      wr,
      Paint()
        ..color = const Color(0xFF3E2723)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );
    canvas.drawLine(Offset(wc.dx - wr, wc.dy), Offset(wc.dx + wr, wc.dy),
        Paint()..color = const Color(0xFF3E2723)..strokeWidth = 5);
    canvas.drawLine(Offset(wc.dx, wc.dy - wr), Offset(wc.dx, wc.dy + wr),
        Paint()..color = const Color(0xFF3E2723)..strokeWidth = 5);
    // Asılı lamba, hafif sallanır
    final sway = math.sin(t * 2 * math.pi) * 6;
    final lx = size.width * 0.3 + sway;
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(lx, size.height * 0.12),
        Paint()..color = const Color(0xFF263238)..strokeWidth = 3);
    canvas.drawCircle(Offset(lx, size.height * 0.14), 60,
        Paint()..color = const Color(0xFFFFF59D).withValues(alpha: 0.18));
    canvas.drawCircle(Offset(lx, size.height * 0.14), 14,
        Paint()..color = const Color(0xFFFFF59D));
    // Raf ve aletler
    final shelfY = size.height * 0.5;
    canvas.drawRect(Rect.fromLTWH(size.width * 0.68, shelfY, size.width * 0.28, 10),
        Paint()..color = const Color(0xFF3E2723));
    final tool = Paint()..color = const Color(0xFF90A4AE);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.72, shelfY - 30, 10, 30), tool);
    canvas.drawCircle(Offset(size.width * 0.8, shelfY - 14), 14, tool);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.86, shelfY - 24, 26, 24),
        Paint()..color = const Color(0xFFE53935));
    // Zemin
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.86, size.width, size.height * 0.14),
      Paint()..color = const Color(0xFF4E342E),
    );
    _rails(canvas, size);
  }

  void _track(Canvas canvas, Size size) {
    _ground(canvas, size);
    // Çit direkleri akar
    final shift = moving ? (t * 600) % 120 : 0.0;
    final post = Paint()..color = const Color(0xFF5D4037);
    for (var x = -120.0; x < size.width + 120; x += 120) {
      canvas.drawRect(Rect.fromLTWH(x - shift, size.height * 0.78, 8, 40), post);
    }
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.8, size.width, 4),
      post,
    );
    _rails(canvas, size);
  }

  void _bridge(Canvas canvas, Size size) {
    // Nehir
    final riverTop = size.height * 0.72;
    canvas.drawRect(
      Rect.fromLTWH(0, riverTop, size.width, size.height - riverTop),
      Paint()..color = const Color(0xFF4FC3F7),
    );
    final wave = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (var row = 0; row < 3; row++) {
      final y = riverTop + 30 + row * 40;
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 10) {
        path.lineTo(x, y + math.sin((x / 40) + t * 2 * math.pi + row) * 4);
      }
      canvas.drawPath(path, wave);
    }
    // Zıplayan balık
    final jump = (t * 2) % 1;
    if (jump < 0.5) {
      final fx = size.width * 0.5 + jump * 80;
      final fy = riverTop + 20 - math.sin(jump * 2 * math.pi) * 50;
      canvas.drawOval(Rect.fromCenter(center: Offset(fx, fy), width: 26, height: 12),
          Paint()..color = const Color(0xFFFF8A65));
    }
    // Köprü tabliyesi ve korkuluk
    final deckY = size.height * 0.84;
    canvas.drawRect(Rect.fromLTWH(0, deckY, size.width, 16),
        Paint()..color = const Color(0xFF6D4C41));
    final rail = Paint()..color = const Color(0xFF8D6E63);
    for (var x = 0.0; x < size.width; x += 50) {
      canvas.drawRect(Rect.fromLTWH(x, deckY - 30, 6, 30), rail);
    }
    canvas.drawRect(Rect.fromLTWH(0, deckY - 32, size.width, 5), rail);
    // Kule ve dişli
    final tx = size.width * 0.15;
    canvas.drawRect(
      Rect.fromLTWH(tx, size.height * 0.3, 90, deckY - size.height * 0.3),
      Paint()..color = const Color(0xFF78909C),
    );
    final gearC = Offset(tx + 45, size.height * 0.4);
    final gear = Paint()..color = const Color(0xFF455A64);
    canvas.save();
    canvas.translate(gearC.dx, gearC.dy);
    canvas.rotate(t * 2 * math.pi);
    for (var i = 0; i < 8; i++) {
      canvas.rotate(math.pi / 4);
      canvas.drawRect(const Rect.fromLTWH(-6, -38, 12, 16), gear);
    }
    canvas.drawCircle(Offset.zero, 28, gear);
    canvas.drawCircle(Offset.zero, 8, Paint()..color = const Color(0xFFFFB300));
    canvas.restore();
    _rails(canvas, size);
  }

  void _tunnel(Canvas canvas, Size size) {
    // Karanlık tünel: taş duvar, kemer, uzakta çıkış ışığı, sallanan fener.
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF1A1A2E));
    final brick = Paint()..color = const Color(0xFF2B2B45);
    final mortar = Paint()
      ..color = const Color(0xFF14142A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final shift = moving ? (t * 300) % 80 : 0.0;
    for (var row = 0; row < 14; row++) {
      final y = row * 44.0;
      final offset = row.isEven ? 0.0 : 40.0;
      for (var x = -80.0 - offset; x < size.width + 80; x += 80) {
        final r = Rect.fromLTWH(x - shift, y, 78, 42);
        canvas.drawRect(r, brick);
        canvas.drawRect(r, mortar);
      }
    }
    // Uzaktaki çıkış: kemer biçimli ışık, yolculukta büyür.
    final exitW = size.width * 0.16;
    final exitH = size.height * 0.26;
    final exitC = Offset(size.width * 0.5, size.height * 0.62);
    final glowRect = Rect.fromCenter(center: exitC, width: exitW * 2.4, height: exitH * 2.2);
    canvas.drawOval(
      glowRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFE082).withValues(alpha: 0.35),
            const Color(0xFFFFE082).withValues(alpha: 0),
          ],
        ).createShader(glowRect),
    );
    final arch = Path()
      ..moveTo(exitC.dx - exitW / 2, exitC.dy + exitH / 2)
      ..lineTo(exitC.dx - exitW / 2, exitC.dy - exitH * 0.1)
      ..arcToPoint(Offset(exitC.dx + exitW / 2, exitC.dy - exitH * 0.1),
          radius: Radius.circular(exitW / 2))
      ..lineTo(exitC.dx + exitW / 2, exitC.dy + exitH / 2)
      ..close();
    canvas.drawPath(
      arch,
      Paint()
        ..color = Color.lerp(const Color(0xFFFFF8E1), const Color(0xFFE3F2FD), season)!,
    );
    // Raylar çıkışa doğru daralır.
    final railPaint = Paint()
      ..color = const Color(0xFF78909C)
      ..strokeWidth = 5;
    final by = size.height * 0.96;
    canvas.drawLine(Offset(size.width * 0.08, by),
        Offset(exitC.dx - exitW * 0.3, exitC.dy + exitH / 2), railPaint);
    canvas.drawLine(Offset(size.width * 0.92, by),
        Offset(exitC.dx + exitW * 0.3, exitC.dy + exitH / 2), railPaint);
    final tie = Paint()..color = const Color(0xFF3E2723);
    final tieShift = moving ? (t * 3) % 1 : 0.0;
    for (var i = 0; i < 8; i++) {
      final f = ((i + tieShift) / 8);
      final y = by - (by - (exitC.dy + exitH / 2)) * f;
      final halfW = (size.width * 0.42) * (1 - f) + exitW * 0.3 * f;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(size.width * 0.5, y), width: halfW * 2, height: 10 * (1 - f) + 2),
        tie,
      );
    }
    // Tavandan sarkan fener: hafif sallanır, alevi titrer.
    final sway = math.sin(t * 2 * math.pi) * 10;
    final lx = size.width * 0.22 + sway;
    final ly = size.height * 0.2;
    canvas.drawLine(Offset(size.width * 0.22, 0), Offset(lx, ly - 24),
        Paint()..color = const Color(0xFF546E7A)..strokeWidth = 3);
    final flicker = 0.85 + 0.15 * math.sin(t * 2 * math.pi * 7);
    canvas.drawCircle(Offset(lx, ly), 90 * flicker,
        Paint()..color = const Color(0xFFFFB300).withValues(alpha: 0.12));
    canvas.drawCircle(Offset(lx, ly), 48 * flicker,
        Paint()..color = const Color(0xFFFFB300).withValues(alpha: 0.18));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(lx, ly), width: 30, height: 44),
          const Radius.circular(6)),
      Paint()..color = const Color(0xFF37474F),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(lx, ly), width: 20, height: 30),
          const Radius.circular(4)),
      Paint()..color = const Color(0xFFFFE082),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(lx, ly + 2), width: 10, height: 18 * flicker),
      Paint()..color = const Color(0xFFFF8F00),
    );
    // Yarasa gözleri: karanlıkta iki çift küçük ışık göz kırpar.
    final blink = (t * 4) % 1 > 0.9 ? 0.0 : 1.0;
    final eye = Paint()..color = const Color(0xFF80DEEA).withValues(alpha: 0.9 * blink);
    canvas.drawCircle(Offset(size.width * 0.86, size.height * 0.3), 4, eye);
    canvas.drawCircle(Offset(size.width * 0.86 + 14, size.height * 0.3), 4, eye);
  }

  void _hall(Canvas canvas, Size size) {
    // Kubbeli büyük istasyon: cam kubbe, kemerli pencereler, dev pano,
    // simit arabası ve peronda bekleyen silüetler.
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFD7CCC8));
    // Kubbe: yarım daire cam, gökyüzü görünür.
    final domeC = Offset(size.width * 0.5, size.height * 0.42);
    final domeR = size.width * 0.5;
    final domeRect = Rect.fromCircle(center: domeC, radius: domeR);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, domeC.dy));
    canvas.drawCircle(
      domeC,
      domeR,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(const Color(0xFF90CAF9), const Color(0xFFB0BEC5), season)!,
            Color.lerp(const Color(0xFFFFF3E0), const Color(0xFFECEFF1), season)!,
          ],
        ).createShader(domeRect),
    );
    final rib = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    for (var i = 0; i <= 8; i++) {
      final a = math.pi + math.pi * i / 8;
      canvas.drawLine(
          domeC, domeC + Offset(math.cos(a), math.sin(a)) * domeR, rib);
    }
    canvas.drawCircle(domeC, domeR * 0.66, rib);
    canvas.drawCircle(domeC, domeR, rib..strokeWidth = 10);
    canvas.restore();
    // Güvercinler kubbede süzülür.
    final bird = Paint()
      ..color = const Color(0xFF455A64)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final bx = ((t * 0.3 + i * 0.33) % 1.2 - 0.1) * size.width;
      final by = size.height * (0.12 + i * 0.06) +
          math.sin(t * 2 * math.pi * 2 + i) * 6;
      final flap = math.sin(t * 2 * math.pi * 6 + i) * 4;
      canvas.drawLine(Offset(bx - 10, by - flap), Offset(bx, by), bird);
      canvas.drawLine(Offset(bx, by), Offset(bx + 10, by - flap), bird);
    }
    // Kemerli pencereler
    final glass = Paint()..color = const Color(0xFFFFF8E1);
    final frame = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    for (final fx in [0.08, 0.86]) {
      final r = Rect.fromLTWH(size.width * fx, size.height * 0.46,
          size.width * 0.07, size.height * 0.26);
      final rr = RRect.fromRectAndCorners(r,
          topLeft: Radius.circular(r.width / 2),
          topRight: Radius.circular(r.width / 2));
      canvas.drawRRect(rr, glass);
      canvas.drawRRect(rr, frame);
    }
    // Dev tarife panosu: sarı klapeler ara sıra döner.
    final board = Rect.fromLTWH(size.width * 0.33, size.height * 0.44,
        size.width * 0.34, size.height * 0.11);
    canvas.drawRRect(RRect.fromRectAndRadius(board, const Radius.circular(8)),
        Paint()..color = const Color(0xFF263238));
    final slot = Paint()..color = const Color(0xFFFFEB3B);
    for (var i = 0; i < 4; i++) {
      final flip = (t * 3 + i * 0.25) % 1 < 0.1 ? 0.5 : 1.0;
      canvas.drawRect(
        Rect.fromLTWH(
            board.left + 16 + i * (board.width - 32) / 4,
            board.top + 14,
            (board.width - 32) / 4 - 10,
            (board.height - 28) * flip),
        slot,
      );
    }
    // Zemin ve peron
    _ground(canvas, size, from: 0.9);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.74, size.width, size.height * 0.16),
      Paint()..color = const Color(0xFFBCAAA4),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.74, size.width, 6),
      Paint()..color = const Color(0xFFFFB300),
    );
    // Bekleyen silüetler hafifçe sallanır.
    final crowd = Paint()..color = const Color(0xFF8D6E63);
    for (var i = 0; i < 5; i++) {
      final cx = size.width * (0.1 + i * 0.19);
      final bob = math.sin(t * 2 * math.pi + i) * 2;
      final top = size.height * 0.6 + bob;
      canvas.drawCircle(Offset(cx, top), 12, crowd);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - 14, top + 12, 28, 60), const Radius.circular(8)),
        crowd,
      );
    }
    // Simit arabası (simitçi konuşmaz, yalnız durur).
    final cartX = size.width * 0.72;
    final cartY = size.height * 0.6;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cartX, cartY, 90, 50), const Radius.circular(6)),
      Paint()..color = const Color(0xFFE53935),
    );
    canvas.drawRect(Rect.fromLTWH(cartX, cartY - 8, 90, 10),
        Paint()..color = const Color(0xFFFFF59D));
    final wheel = Paint()..color = const Color(0xFF263238);
    canvas.drawCircle(Offset(cartX + 20, cartY + 56), 8, wheel);
    canvas.drawCircle(Offset(cartX + 70, cartY + 56), 8, wheel);
    final simit = Paint()
      ..color = const Color(0xFFD2A25D)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(Offset(cartX + 14 + i * 20, cartY - 16), 8, simit);
    }
    _rails(canvas, size);
  }

  void _cabin(Canvas canvas, Size size) {
    // Yataklı vagon içi: ahşap paneller, perdeli pencere (gece), ranza,
    // battaniye, sallanan lamba.
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF5D4037));
    final panel = Paint()..color = const Color(0xFF4E342E);
    for (var x = 0.0; x < size.width; x += 48) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 3, size.height), panel);
    }
    // Pencere: gece gökyüzü ve akan yıldızlar
    final win = Rect.fromLTWH(size.width * 0.58, size.height * 0.14,
        size.width * 0.34, size.height * 0.3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(win.inflate(8), const Radius.circular(12)),
      Paint()..color = const Color(0xFF3E2723),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(win, const Radius.circular(8)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D1B3E), Color(0xFF283593)],
        ).createShader(win),
    );
    final rnd = math.Random(11);
    final star = Paint()..color = Colors.white.withValues(alpha: 0.9);
    final shift = moving ? t * win.width : 0.0;
    for (var i = 0; i < 16; i++) {
      final x = win.left + (rnd.nextDouble() * win.width + shift) % win.width;
      final y = win.top + rnd.nextDouble() * win.height * 0.7;
      canvas.drawCircle(Offset(x, y), 1.5 + rnd.nextDouble() * 1.5, star);
    }
    canvas.drawCircle(Offset(win.right - 36, win.top + 30), 14,
        Paint()..color = const Color(0xFFFFF9C4));
    canvas.drawCircle(Offset(win.right - 30, win.top + 26), 12,
        Paint()..color = const Color(0xFF0D1B3E));
    // Perdeler
    final curtain = Paint()..color = const Color(0xFFC62828);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(win.left - 6, win.top - 4, 22, win.height + 8),
          const Radius.circular(6)),
      curtain,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(win.right - 16, win.top - 4, 22, win.height + 8),
          const Radius.circular(6)),
      curtain,
    );
    // Ranza ve battaniye
    final bedY = size.height * 0.66;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.56, bedY, size.width * 0.4, 20),
          const Radius.circular(6)),
      Paint()..color = const Color(0xFF3E2723),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.58, bedY - 26, size.width * 0.36, 28),
          const Radius.circular(10)),
      Paint()..color = const Color(0xFF5C6BC0),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.6, bedY - 36, 44, 20),
          const Radius.circular(8)),
      Paint()..color = Colors.white,
    );
    // Sallanan lamba
    final sway = math.sin(t * 2 * math.pi) * 5;
    final lx = size.width * 0.3 + sway;
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(lx, size.height * 0.1),
        Paint()..color = const Color(0xFF263238)..strokeWidth = 3);
    canvas.drawCircle(Offset(lx, size.height * 0.12), 56,
        Paint()..color = const Color(0xFFFFE082).withValues(alpha: 0.15));
    canvas.drawCircle(Offset(lx, size.height * 0.12), 12,
        Paint()..color = const Color(0xFFFFE082));
    // Zemin halısı ve raylar
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.86, size.width, size.height * 0.14),
      Paint()..color = const Color(0xFF8D6E63),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.86, size.width, 6),
      Paint()..color = const Color(0xFFC62828),
    );
    _rails(canvas, size);
  }

  void _market(Canvas canvas, Size size) {
    // Arıların pazar kasabası: tezgâhlar, çizgili tenteler, petekli kovan,
    // uçuşan arılar.
    _ground(canvas, size, from: 0.84);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.7, size.width, size.height * 0.14),
      Paint()..color = const Color(0xFFD7CCC8),
    );
    // Tezgâhlar
    for (var i = 0; i < 3; i++) {
      final x = size.width * (0.06 + i * 0.3);
      final y = size.height * 0.52;
      final w = size.width * 0.22;
      final counter = Paint()..color = const Color(0xFF8D6E63);
      canvas.drawRect(Rect.fromLTWH(x, y + 60, w, 50), counter);
      canvas.drawRect(Rect.fromLTWH(x + 6, y, 6, 60), counter);
      canvas.drawRect(Rect.fromLTWH(x + w - 12, y, 6, 60), counter);
      // Tente: kırmızı-beyaz çizgili
      final stripes = [const Color(0xFFE53935), Colors.white];
      final n = 6;
      for (var s = 0; s < n; s++) {
        canvas.drawRect(
          Rect.fromLTWH(x - 6 + s * (w + 12) / n, y - 18, (w + 12) / n + 1, 22),
          Paint()..color = stripes[s % 2],
        );
      }
      // Kavanozlar
      for (var j = 0; j < 3; j++) {
        final jx = x + 14 + j * 30;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(jx, y + 36, 22, 26), const Radius.circular(5)),
          Paint()..color = const Color(0xFFFFB300),
        );
        canvas.drawRect(Rect.fromLTWH(jx + 2, y + 32, 18, 6),
            Paint()..color = const Color(0xFF5D4037));
      }
    }
    // Kovan: petek deseni
    final hiveC = Offset(size.width * 0.88, size.height * 0.5);
    final hive = Paint()..color = const Color(0xFFFFCA28);
    for (var row = 0; row < 4; row++) {
      final rw = 70 - (row - 1.5).abs() * 14;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: hiveC + Offset(0, row * 22 - 30), width: rw, height: 20),
            const Radius.circular(10)),
        hive,
      );
    }
    canvas.drawCircle(hiveC + const Offset(0, 36), 7,
        Paint()..color = const Color(0xFF5D4037));
    // Arılar: sinüs yolunda uçar
    for (var i = 0; i < 5; i++) {
      final f = (t * (0.4 + i * 0.1) + i * 0.2) % 1;
      final bx = size.width * (0.05 + 0.9 * f);
      final by = size.height * (0.2 + i * 0.08) + math.sin(f * 2 * math.pi * 3 + i) * 14;
      canvas.drawOval(
          Rect.fromCenter(center: Offset(bx, by), width: 16, height: 11),
          Paint()..color = const Color(0xFFFFEB3B));
      canvas.drawRect(Rect.fromLTWH(bx - 3, by - 5, 3, 10),
          Paint()..color = const Color(0xFF263238));
      canvas.drawRect(Rect.fromLTWH(bx + 3, by - 5, 3, 10),
          Paint()..color = const Color(0xFF263238));
      final flap = (t * 20).floor().isEven ? 1.0 : 0.6;
      canvas.drawOval(
          Rect.fromCenter(center: Offset(bx, by - 7 * flap), width: 12, height: 6 * flap),
          Paint()..color = Colors.white.withValues(alpha: 0.8));
    }
    _rails(canvas, size);
  }

  void _valley(Canvas canvas, Size size) {
    // Mevsim vadisi: dört tepe şeridi dört mevsim (kış, ilkbahar, yaz,
    // sonbahar), her şeritte küçük kasaba evleri.
    final colors = [
      const Color(0xFFECEFF1), // kış
      const Color(0xFF81C784), // ilkbahar
      const Color(0xFFD4E157), // yaz
      const Color(0xFFFF8A65), // sonbahar
    ];
    final shift = moving ? (t * size.width) % size.width : 0.0;
    final bandW = size.width / 4;
    for (var b = 0; b < 4; b++) {
      final x0 = ((b * bandW - shift) % size.width + size.width) % size.width;
      for (final xs in [x0, x0 - size.width]) {
        final path = Path()..moveTo(xs, size.height);
        for (var x = 0.0; x <= bandW; x += 6) {
          final y = size.height *
              (0.6 + 0.08 * math.sin((x / bandW) * math.pi * 2 + b));
          path.lineTo(xs + x, y);
        }
        path
          ..lineTo(xs + bandW, size.height)
          ..close();
        canvas.drawPath(path, Paint()..color = colors[b]);
        // Evler
        final hx = xs + bandW * 0.5;
        final hy = size.height * 0.64;
        canvas.drawRect(Rect.fromLTWH(hx - 16, hy, 32, 26),
            Paint()..color = const Color(0xFFFFF8E1));
        canvas.drawPath(
          Path()
            ..moveTo(hx - 20, hy)
            ..lineTo(hx, hy - 18)
            ..lineTo(hx + 20, hy)
            ..close(),
          Paint()..color = const Color(0xFFE53935),
        );
        // Mevsim süsü
        switch (b) {
          case 0:
            for (var i = 0; i < 6; i++) {
              canvas.drawCircle(
                  Offset(xs + 20 + i * bandW / 6, size.height * (0.2 + (i % 3) * 0.1) + (t * 40) % 60),
                  3, Paint()..color = Colors.white);
            }
          case 1:
            for (var i = 0; i < 5; i++) {
              canvas.drawCircle(Offset(xs + 30 + i * bandW / 5, size.height * 0.75), 5,
                  Paint()..color = const Color(0xFFF06292));
            }
          case 2:
            canvas.drawCircle(Offset(xs + bandW * 0.5, size.height * 0.2), 22,
                Paint()..color = const Color(0xFFFFEE58));
          default:
            for (var i = 0; i < 5; i++) {
              final ly = size.height * (0.3 + (i * 0.1 + t * 0.3) % 0.4);
              canvas.drawOval(
                  Rect.fromCenter(center: Offset(xs + 30 + i * bandW / 5, ly), width: 12, height: 7),
                  Paint()..color = const Color(0xFFBF360C));
            }
        }
      }
    }
    _ground(canvas, size, from: 0.88);
    _rails(canvas, size);
  }

  void _snowfield(Canvas canvas, Size size) {
    // Kar Dağı eteği: beyaz tepeler, çam ağaçları, arkada dağ, yoğun kar.
    final mountain = Path()
      ..moveTo(size.width * 0.2, size.height * 0.6)
      ..lineTo(size.width * 0.5, size.height * 0.12)
      ..lineTo(size.width * 0.8, size.height * 0.6)
      ..close();
    canvas.drawPath(mountain, Paint()..color = const Color(0xFF90A4AE));
    final cap = Path()
      ..moveTo(size.width * 0.42, size.height * 0.25)
      ..lineTo(size.width * 0.5, size.height * 0.12)
      ..lineTo(size.width * 0.58, size.height * 0.25)
      ..lineTo(size.width * 0.54, size.height * 0.28)
      ..lineTo(size.width * 0.5, size.height * 0.24)
      ..lineTo(size.width * 0.46, size.height * 0.28)
      ..close();
    canvas.drawPath(cap, Paint()..color = Colors.white);
    final shift = moving ? t * size.width : 0.0;
    _hillLayer(canvas, size, 0.62, 0.06, 1.6, const Color(0xFFECEFF1), shift * 0.3);
    _hillLayer(canvas, size, 0.74, 0.05, 2.4, Colors.white, shift * 0.6);
    // Çamlar
    final pine = Paint()..color = const Color(0xFF2E5D3A);
    final snowCap = Paint()..color = Colors.white;
    for (var i = 0; i < 6; i++) {
      final x = ((i * 0.17 + 0.05) * size.width - shift * 0.6) % size.width;
      final y = size.height * (0.66 + (i % 2) * 0.08);
      for (var tier = 0; tier < 3; tier++) {
        final tw = 40.0 - tier * 10;
        final ty = y - tier * 18;
        canvas.drawPath(
          Path()
            ..moveTo(x - tw / 2, ty)
            ..lineTo(x, ty - 26)
            ..lineTo(x + tw / 2, ty)
            ..close(),
          pine,
        );
        canvas.drawPath(
          Path()
            ..moveTo(x - tw / 4, ty - 13)
            ..lineTo(x, ty - 26)
            ..lineTo(x + tw / 4, ty - 13)
            ..close(),
          snowCap,
        );
      }
      canvas.drawRect(Rect.fromLTWH(x - 4, y, 8, 14),
          Paint()..color = const Color(0xFF5D4037));
    }
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.88, size.width, size.height * 0.12),
      Paint()..color = const Color(0xFFCFD8DC),
    );
    _rails(canvas, size);
  }

  void _summit(Canvas canvas, Size size) {
    // Kar Dağı'nın tepesi: beyaz zirve, yuvanın kapısı (büyük yuvarlak
    // kapı, üstünde saat kilidi), kar.
    _hillLayer(canvas, size, 0.55, 0.05, 1.2, Colors.white, 0);
    final doorC = Offset(size.width * 0.5, size.height * 0.62);
    final r = size.shortestSide * 0.22;
    canvas.drawCircle(doorC, r + 14, Paint()..color = const Color(0xFF8D6E63));
    canvas.drawCircle(doorC, r, Paint()..color = const Color(0xFF5D4037));
    final plank = Paint()
      ..color = const Color(0xFF4E342E)
      ..strokeWidth = 4;
    for (var i = -2; i <= 2; i++) {
      final x = doorC.dx + i * r * 0.4;
      canvas.drawLine(Offset(x, doorC.dy - r * 0.9), Offset(x, doorC.dy + r * 0.9), plank);
    }
    // Kilit: altın çember ve dişliler
    final lockC = Offset(doorC.dx, doorC.dy - r * 0.15);
    canvas.drawCircle(lockC, r * 0.42, Paint()..color = const Color(0xFFB8860B));
    canvas.drawCircle(lockC, r * 0.34, Paint()..color = const Color(0xFFFFD54F));
    final gear = Paint()..color = const Color(0xFF78909C);
    for (var g = 0; g < 5; g++) {
      final a = -math.pi / 2 + g * 2 * math.pi / 5;
      final gc = lockC + Offset(math.cos(a), math.sin(a)) * r * 0.22;
      canvas.save();
      canvas.translate(gc.dx, gc.dy);
      canvas.rotate(t * 2 * math.pi * (g.isEven ? 1 : -1));
      for (var k = 0; k < 6; k++) {
        canvas.rotate(math.pi / 3);
        canvas.drawRect(Rect.fromLTWH(-2, -r * 0.1, 4, r * 0.05), gear);
      }
      canvas.drawCircle(Offset.zero, r * 0.06, gear);
      canvas.restore();
    }
    // Kapının iki yanında çamlar
    for (final fx in [0.18, 0.82]) {
      final x = size.width * fx;
      final y = size.height * 0.8;
      for (var tier = 0; tier < 3; tier++) {
        final tw = 60.0 - tier * 14;
        final ty = y - tier * 24;
        canvas.drawPath(
          Path()
            ..moveTo(x - tw / 2, ty)
            ..lineTo(x, ty - 36)
            ..lineTo(x + tw / 2, ty)
            ..close(),
          Paint()..color = const Color(0xFF2E5D3A),
        );
      }
    }
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.86, size.width, size.height * 0.14),
      Paint()..color = Colors.white,
    );
    _rails(canvas, size);
  }

  void _den(Canvas canvas, Size size) {
    // Yuvanın içi: sıcak mağara-ev, raf, ocak, yuvarlak pencerede kar.
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF6D4C41));
    final arch = Paint()..color = const Color(0xFF8D6E63);
    canvas.drawOval(
      Rect.fromLTWH(-size.width * 0.1, -size.height * 0.2, size.width * 1.2, size.height * 1.2),
      arch,
    );
    // Pencere: dışarıda kar yağar
    final wc = Offset(size.width * 0.78, size.height * 0.28);
    final wr = size.shortestSide * 0.13;
    canvas.drawCircle(wc, wr + 8, Paint()..color = const Color(0xFF3E2723));
    canvas.drawCircle(wc, wr, Paint()..color = const Color(0xFF283593));
    final rnd = math.Random(21);
    for (var i = 0; i < 14; i++) {
      final a = rnd.nextDouble() * 2 * math.pi;
      final d = rnd.nextDouble() * wr * 0.9;
      final fall = ((rnd.nextDouble() + t) % 1) * wr * 2 - wr;
      final p = Offset(wc.dx + math.cos(a) * d, wc.dy + fall);
      if ((p - wc).distance < wr) {
        canvas.drawCircle(p, 2.5, Paint()..color = Colors.white);
      }
    }
    // Raf
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.08, size.height * 0.4, size.width * 0.4, 10),
      Paint()..color = const Color(0xFF3E2723),
    );
    // Ocak: titreyen alev
    final fx = size.width * 0.22;
    final fy = size.height * 0.78;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(fx, fy), width: 120, height: 70),
          const Radius.circular(10)),
      Paint()..color = const Color(0xFF4E342E),
    );
    final flick = 0.8 + 0.2 * math.sin(t * 2 * math.pi * 9);
    canvas.drawCircle(Offset(fx, fy), 70 * flick,
        Paint()..color = const Color(0xFFFFB300).withValues(alpha: 0.12));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(fx, fy - 4), width: 36, height: 44 * flick),
      Paint()..color = const Color(0xFFFF8F00),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(fx, fy + 2), width: 18, height: 24 * flick),
      Paint()..color = const Color(0xFFFFEB3B),
    );
    // Yatak
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.55, size.height * 0.74, size.width * 0.4, 36),
          const Radius.circular(12)),
      Paint()..color = const Color(0xFF5C6BC0),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.58, size.height * 0.7, 50, 22),
          const Radius.circular(8)),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.88, size.width, size.height * 0.12),
      Paint()..color = const Color(0xFF4E342E),
    );
  }

  @override
  bool shouldRepaint(SceneryPainter old) =>
      old.t != t ||
      old.scenery != scenery ||
      old.season != season ||
      old.moving != moving;
}

/// Saatin dünyadaki yuvası.
class ClockFrame extends StatelessWidget {
  final ClockFrameStyle style;
  final Widget child;

  const ClockFrame({super.key, required this.style, required this.child});

  @override
  Widget build(BuildContext context) {
    final (Color outer, Color inner, double radius) = switch (style) {
      ClockFrameStyle.cab => (const Color(0xFF4E342E), const Color(0xFFFFB300), 28.0),
      ClockFrameStyle.post => (const Color(0xFF1E88E5), const Color(0xFF0D47A1), 200.0),
      ClockFrameStyle.tower => (const Color(0xFF78909C), const Color(0xFF455A64), 200.0),
      ClockFrameStyle.lantern => (const Color(0xFF37474F), const Color(0xFFFFB300), 36.0),
      ClockFrameStyle.gold => (const Color(0xFFB8860B), const Color(0xFFFFD54F), 200.0),
      ClockFrameStyle.ice => (const Color(0xFF81D4FA), const Color(0xFFE1F5FE), 200.0),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: outer,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [BoxShadow(blurRadius: 16, color: Colors.black38, offset: Offset(0, 6))],
      ),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: inner,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: child,
      ),
    );
  }
}
