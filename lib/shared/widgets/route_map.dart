import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/story/models.dart';

/// Yol haritası: kıvrımlı ray üstünde duraklar; tren tamamlanan durakta
/// durur. Dokunulabilir nesneler (menü değil): açık bir durağa dokunmak onu
/// oynatır, hikâye bitince kar tanesi Hızlı Saat'i, kapı Zaman Kapıları'nı
/// açar. Kilitli duraklar soluk ve dokunulmaz.
class RouteMap extends StatelessWidget {
  final List<Station> stations;

  /// Tamamlanan en yüksek durak (0: hiçbiri).
  final int completed;

  /// Sıradaki durağın numarası (sınıf ön ayarı durak atlayabilir).
  final int? next;

  /// Sınıf ön ayarındaki duraklar; verilmezse tümü.
  final Set<int>? available;
  final bool allUnlocked;
  final bool finished;
  final ValueChanged<Station>? onStation;
  final VoidCallback? onQuickClock;
  final VoidCallback? onTimeGates;

  /// Kol Saati mini oyunu: haritada hep görünür (hikâyeden bağımsız).
  final VoidCallback? onArmClock;

  const RouteMap({
    super.key,
    required this.stations,
    required this.completed,
    this.next,
    this.available,
    this.allUnlocked = false,
    this.finished = false,
    this.onStation,
    this.onQuickClock,
    this.onTimeGates,
    this.onArmClock,
  });

  /// Durak konumu (0-1 oranı): soldan sağa kıvrımlı yol.
  static Offset positionOf(int index, int count) {
    final f = count <= 1 ? 0.0 : index / (count - 1);
    final x = 0.06 + 0.78 * f;
    final y = 0.5 + 0.3 * math.sin(f * math.pi * 2.5 + 0.4);
    return Offset(x, y);
  }

  bool isUnlocked(Station s) {
    if (available != null && !available!.contains(s.number)) return false;
    return allUnlocked || s.number <= (next ?? completed + 1);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;
      // Yol dikeyde sınırlı kalsın: dar/uzun ekranda zikzak abartılmaz.
      final amp = math.min(h * 0.3, w * 0.16);
      final points = [
        for (var i = 0; i < stations.length; i++)
          () {
            final p = RouteMap.positionOf(i, stations.length);
            return Offset(p.dx * w, h / 2 + (p.dy - 0.5) / 0.3 * amp);
          }(),
      ];
      final trainIndex = completed.clamp(0, stations.length - 1);
      final trainPos = completed == 0
          ? Offset(points.first.dx - 36, points.first.dy)
          : points[trainIndex];
      final markerR = (w / 30).clamp(14.0, 26.0);
      return Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(size: Size(w, h), painter: _RailPainter(points)),
          for (var i = 0; i < stations.length; i++)
            Positioned(
              left: points[i].dx - markerR,
              top: points[i].dy - markerR,
              child: _Marker(
                key: ValueKey('map-${stations[i].number}'),
                icon: stations[i].reward.icon,
                number: stations[i].number,
                unlocked: isUnlocked(stations[i]),
                done: stations[i].number <= completed,
                radius: markerR,
                onTap: isUnlocked(stations[i]) && onStation != null
                    ? () => onStation!(stations[i])
                    : null,
              ),
            ),
          Positioned(
            left: trainPos.dx - 18,
            top: trainPos.dy - markerR - 30,
            child: const IgnorePointer(
              child: Icon(Icons.train, size: 36, color: Color(0xFF311B92)),
            ),
          ),
          if (onArmClock != null)
            Positioned(
              left: 8,
              top: 4,
              child: _Marker(
                key: const ValueKey('map-arm'),
                icon: Icons.accessibility_new,
                unlocked: true,
                done: false,
                radius: markerR,
                color: const Color(0xFFCE93D8),
                onTap: onArmClock,
              ),
            ),
          if (finished) ...[
            Positioned(
              right: 8,
              top: 4,
              child: _Marker(
                key: const ValueKey('map-quick'),
                icon: Icons.ac_unit,
                unlocked: true,
                done: false,
                radius: markerR,
                color: const Color(0xFF81D4FA),
                onTap: onQuickClock,
              ),
            ),
            Positioned(
              right: 8,
              bottom: 4,
              child: _Marker(
                key: const ValueKey('map-gates'),
                icon: Icons.door_sliding,
                unlocked: true,
                done: false,
                radius: markerR,
                color: const Color(0xFFFFB300),
                onTap: onTimeGates,
              ),
            ),
          ],
        ],
      );
    });
  }
}

class _Marker extends StatelessWidget {
  final IconData icon;
  final int? number;
  final bool unlocked;
  final bool done;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;

  const _Marker({
    super.key,
    required this.icon,
    this.number,
    required this.unlocked,
    required this.done,
    required this.radius,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fill = !unlocked
        ? const Color(0xFFB0BEC5)
        : color ?? (done ? const Color(0xFFC8E6C9) : const Color(0xFFFFF59D));
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: unlocked ? 1 : 0.5,
        child: Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF5D4037), width: 3),
            boxShadow: const [
              BoxShadow(blurRadius: 6, color: Colors.black26, offset: Offset(0, 3)),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: radius, color: const Color(0xFF5D4037)),
              if (number != null)
                Positioned(
                  right: 2,
                  bottom: 0,
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF263238),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailPainter extends CustomPainter {
  final List<Offset> points;

  _RailPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final cx = (a.dx + b.dx) / 2;
      path.cubicTo(cx, a.dy, cx, b.dy, b.dx, b.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF546E7A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFECEFF1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_RailPainter old) => old.points != points;
}
