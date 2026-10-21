import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/features/mechanics/mechanic_frame.dart';
import 'package:zaman_bekcisi/shared/audio/speech.dart';
import 'package:zaman_bekcisi/shared/layout.dart';
import 'package:zaman_bekcisi/shared/widgets/orientation_guard.dart';

void main() {
  test('ekran sınıfları', () {
    expect(Layout.phonePortrait(const Size(390, 844)), isTrue);
    expect(Layout.phonePortrait(const Size(844, 390)), isFalse);
    expect(Layout.phonePortrait(const Size(768, 1024)), isFalse, reason: 'tablet dikey serbest');
  });

  testWidgets('dikey telefonda çevir sahnesi, yatayda oyun', (tester) async {
    Speech.instance.enabled = false;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpWidget(const MaterialApp(
      home: OrientationGuard(child: Text('OYUN')),
    ));
    await tester.pump();
    expect(find.text('OYUN'), findsNothing);
    expect(find.byIcon(Icons.phone_android), findsOneWidget);

    tester.view.physicalSize = const Size(844, 390);
    await tester.pump();
    expect(find.text('OYUN'), findsOneWidget);
  });

  testWidgets('tabela genişlemez, sıkışık düzende küçülür', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(1000, 700);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Wrap(children: [WoodenSign(text: '3:00')])),
    ));
    final wide = tester.getSize(find.byType(WoodenSign));
    expect(wide.width, lessThan(260));

    tester.view.physicalSize = const Size(844, 390);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Wrap(children: [WoodenSign(text: '3:00')])),
    ));
    final small = tester.getSize(find.byType(WoodenSign));
    expect(small.width, lessThan(wide.width));
    expect(small.height, lessThan(wide.height));
  });

  testWidgets('MechanicFrame sıkışık düzende tabelaları yana alır', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(844, 390);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: MechanicFrame(
          body: ColoredBox(key: ValueKey('body'), color: Colors.red, child: SizedBox.expand()),
          footer: WoodenSign(text: '7:00'),
        ),
      ),
    ));
    final body = tester.getRect(find.byKey(const ValueKey('body')));
    final sign = tester.getRect(find.byType(WoodenSign));
    expect(sign.left, greaterThan(body.right - 1));
    expect(tester.takeException(), isNull);
  });
}
