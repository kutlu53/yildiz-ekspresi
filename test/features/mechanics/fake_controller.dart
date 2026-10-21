import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/features/story/lines.dart';
import 'package:zaman_bekcisi/features/story/models.dart';
import 'package:zaman_bekcisi/shared/widgets/draggable_clock.dart';

class FakeController implements SceneController {
  int completed = 0;
  int mistakes = 0;
  final List<String> spoken = [];

  @override
  void complete() => completed++;

  @override
  void mistake() => mistakes++;

  @override
  Future<void> say(Line line) async => spoken.add(line.text);

  @override
  Future<void> sayText(String text) async => spoken.add(text);
}

Widget wrap(Widget child) => MaterialApp(
      home: Scaffold(body: SizedBox(width: 900, height: 700, child: child)),
    );

void setScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Kadran geometrisi: DraggableClock'un merkezi ve yarıçapı.
({Offset center, double radius}) clockGeometry(WidgetTester tester) {
  final rect = tester.getRect(find.byType(DraggableClock));
  final radius = math.min(rect.width, rect.height) / 2;
  return (center: rect.center, radius: radius);
}

Offset pointAt(Offset center, double radius, double angleDeg, double frac) {
  final rad = (angleDeg - 90) * math.pi / 180;
  return center + Offset(math.cos(rad), math.sin(rad)) * radius * frac;
}

/// Bir eli `fromAngle` yönünden `toAngle` yönüne sürükler.
Future<void> dragHand(
  WidgetTester tester, {
  required double fromAngle,
  required double toAngle,
  required double frac,
  int steps = 6,
}) async {
  final g = clockGeometry(tester);
  final gesture = await tester.startGesture(
      pointAt(g.center, g.radius, fromAngle, frac));
  await tester.pump(const Duration(milliseconds: 16));
  for (var i = 1; i <= steps; i++) {
    final a = fromAngle + (toAngle - fromAngle) * i / steps;
    await gesture.moveTo(pointAt(g.center, g.radius, a, frac));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pump(const Duration(milliseconds: 16));
}
