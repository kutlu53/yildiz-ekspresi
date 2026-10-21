import 'package:flutter/material.dart';

import '../../core/year.dart';

/// Yumruk tepeleri: 12 ay bir sıra tepe ve çukur olarak çizilir; tepedeki
/// aylar 31, çukurdakiler 30 (Şubat 28) gün çeker. Seçili ayın tepesinde
/// küçük bir ev durur; `reveal` açıkken evin penceresinde gün sayısı yazar.
class KnuckleHills extends StatelessWidget {
  final int highlight;
  final bool reveal;

  const KnuckleHills({super.key, required this.highlight, this.reveal = false});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2.6,
      child: CustomPaint(
        painter: KnuckleHillsPainter(highlight: highlight, reveal: reveal),
      ),
    );
  }
}

class KnuckleHillsPainter extends CustomPainter {
  final int highlight;
  final bool reveal;

  KnuckleHillsPainter({required this.highlight, required this.reveal});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final slot = w / 12;
    final base = h * 0.82;

    // Zemin
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, base, w, h - base), const Radius.circular(8)),
      Paint()..color = const Color(0xFF8D6E63),
    );

    for (var i = 0; i < 12; i++) {
      final knuckle = Year.onKnuckle(i);
      final small = i == 1; // Şubat
      final height = knuckle ? h * 0.52 : (small ? h * 0.16 : h * 0.26);
      final cx = slot * (i + 0.5);
      final selected = i == highlight;
      final hill = Paint()
        ..color = selected
            ? const Color(0xFFFFD54F)
            : knuckle
                ? const Color(0xFF66BB6A)
                : const Color(0xFFA5D6A7);
      final path = Path()
        ..moveTo(cx - slot * 0.55, base)
        ..quadraticBezierTo(cx - slot * 0.5, base - height, cx, base - height)
        ..quadraticBezierTo(cx + slot * 0.5, base - height, cx + slot * 0.55, base)
        ..close();
      canvas.drawPath(path, hill);
      if (selected) {
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFFFFB300)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
      }

      // Ay numarası
      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            fontSize: slot * 0.32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, base + (h - base) / 2 - tp.height / 2));

      // Ev
      if (selected) {
        final top = base - height;
        final hw = slot * 0.5;
        final hh = slot * 0.42;
        final house = Rect.fromCenter(center: Offset(cx, top - hh / 2 - 2), width: hw, height: hh);
        canvas.drawRect(house, Paint()..color = const Color(0xFFFFF8E1));
        canvas.drawPath(
          Path()
            ..moveTo(house.left - 4, house.top)
            ..lineTo(cx, house.top - hh * 0.6)
            ..lineTo(house.right + 4, house.top)
            ..close(),
          Paint()..color = const Color(0xFFE53935),
        );
        final win = Rect.fromCenter(
            center: house.center, width: hw * 0.7, height: hh * 0.55);
        canvas.drawRRect(
          RRect.fromRectAndRadius(win, const Radius.circular(3)),
          Paint()..color = reveal ? const Color(0xFFFFF59D) : const Color(0xFF90CAF9),
        );
        if (reveal) {
          final num = TextPainter(
            text: TextSpan(
              text: '${Year.daysIn(i)}',
              style: TextStyle(
                fontSize: win.height * 0.8,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF263238),
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          num.paint(canvas, win.center - Offset(num.width / 2, num.height / 2));
        }
      }
    }
  }

  @override
  bool shouldRepaint(KnuckleHillsPainter old) =>
      old.highlight != highlight || old.reveal != reveal;
}
