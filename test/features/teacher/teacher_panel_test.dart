import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zaman_bekcisi/features/story/models.dart';
import 'package:zaman_bekcisi/features/story/progress_store.dart';
import 'package:zaman_bekcisi/features/teacher/teacher_panel.dart';

void main() {
  group('ProgressStore', () {
    test('öğrenci profilleri ayrı kayıt tutar, hata sayısı birikir', () async {
      SharedPreferences.setMockInitialValues({});
      final store = ProgressStore.instance;
      await store.load();
      await store.reset();
      await store.addStudent('Ayşe');
      await store.selectStudent('Ayşe');
      expect(store.currentStudent, 'Ayşe');
      await store.completeStation(2, 'scarf');
      await store.addRetry('3.bell');
      await store.addRetry('3.bell');
      await store.addRetry('2.read');
      expect(store.progress.mistakes['3.bell'], 2);
      expect(store.progress.retryScenes, ['3.bell', '2.read']); // tekrar tek

      await store.selectStudent(ProgressStore.defaultStudent);
      expect(store.progress.completedStation, 0);
      expect(store.progress.mistakes, isEmpty);

      final ayse = await store.progressOf('Ayşe');
      expect(ayse.completedStation, 2);

      await store.setGrade(2);
      await store.reset();
      expect(store.progress.grade, 2, reason: 'sıfırlama sınıf ayarını korur');

      await store.removeStudent('Ayşe');
      expect(store.students, [ProgressStore.defaultStudent]);
    });
  });

  group('TeacherPanel', () {
    testWidgets('rapor, sınıf ayarı ve durağa atlama', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final store = ProgressStore.instance;
      await store.load();
      await store.reset();
      await store.setGrade(null);
      await store.addRetry('3.bell');
      await store.addRetry('3.bell');
      Station? jumped;

      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => TeacherPanel(onJump: (s) => jumped = s),
              )),
              child: const Text('aç'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();

      expect(find.text('Öğretmen Paneli'), findsOneWidget);
      expect(find.text('Çarklı Köprü · Zili Çal'), findsOneWidget);
      expect(find.text('2'), findsWidgets); // hata sayısı rozeti

      await tester.tap(find.text('2. sınıf'));
      await tester.pumpAndSettle();
      expect(store.progress.grade, 2);
      expect(find.text('Duraklar: 1, 2, 3, 6, 7'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Can');
      await tester.tap(find.byIcon(Icons.person_add));
      await tester.pumpAndSettle();
      expect(store.students, contains('Can'));

      await tester.tap(find.text('İlk Hat: Tren Tam Saatte Kalkar'));
      await tester.pumpAndSettle();
      expect(jumped?.number, 2);
      expect(find.text('Öğretmen Paneli'), findsNothing);
    });

    test('describeScene', () {
      expect(describeScene('3.bell'), 'Çarklı Köprü · Zili Çal');
      expect(describeScene('9.quick'), 'Kar Dağı Eteği · Hızlı Saat');
      expect(describeScene('x'), 'x');
    });
  });
}
