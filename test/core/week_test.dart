import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/core/week.dart';

void main() {
  test('gün adları ve sıra', () {
    expect(Week.name(Week.monday), 'Pazartesi');
    expect(Week.name(Week.sunday), 'Pazar');
    expect(Week.name(7), 'Pazartesi');
    expect(Week.name(-1), 'Pazar');
    expect(Week.ordinals[Week.saturday], 'altıncı');
  });

  test('n gün sonra döngüsel sarar', () {
    expect(Week.after(Week.thursday, 2), Week.saturday);
    expect(Week.after(Week.saturday, 2), Week.monday);
    expect(Week.after(Week.sunday, 1), Week.monday);
    expect(Week.after(Week.friday, 7), Week.friday);
    expect(Week.after(Week.monday, -1), Week.sunday);
  });

  test('kaç gün var', () {
    expect(Week.daysUntil(Week.tuesday, Week.saturday), 4);
    expect(Week.daysUntil(Week.saturday, Week.tuesday), 3);
    expect(Week.daysUntil(Week.sunday, Week.sunday), 0);
  });

  test('yol başlangıç hariç hedef dâhil', () {
    expect(Week.path(Week.saturday, 3), [Week.sunday, Week.monday, Week.tuesday]);
    expect(Week.path(Week.friday, 7).last, Week.friday);
    expect(Week.path(Week.friday, 7).length, 7);
  });
}
