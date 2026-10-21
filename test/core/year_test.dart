import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/core/week.dart';
import 'package:zaman_bekcisi/core/year.dart';

void main() {
  test('ay adları, gün sayıları ve yumruk kuralı', () {
    expect(Year.name(0), 'Ocak');
    expect(Year.name(12), 'Ocak');
    expect(Year.daysIn(1), 28);
    expect(Year.daysIn(3), 30);
    expect(Year.daysIn(6), 31);
    expect(Year.daysIn(7), 31); // Temmuz-Ağustos çift tepe
    expect(Year.onKnuckle(0), isTrue);
    expect(Year.onKnuckle(8), isFalse);
    expect(Year.days.reduce((a, b) => a + b), 365);
  });

  test('mevsimler', () {
    expect(Year.seasonOf(2), Year.spring);
    expect(Year.seasonOf(7), Year.summer);
    expect(Year.seasonOf(10), Year.autumn);
    expect(Year.seasonOf(11), Year.winter);
    expect(Year.seasonOf(0), Year.winter);
    expect(Year.monthsOf(Year.winter), [0, 1, 11]);
    for (var s = 0; s < 4; s++) {
      expect(Year.monthsOf(s).length, 3);
    }
  });

  test('takvim: haftanın günü ve n. gün', () {
    // Mart 1 Pazar ise 14 Mart Cumartesi.
    expect(Year.weekdayOf(firstWeekday: Week.sunday, day: 14), Week.saturday);
    // Kasım 1 Çarşamba ise ilk Pazartesi 6 Kasım.
    expect(Year.nthWeekday(firstWeekday: Week.wednesday, weekday: Week.monday), 6);
    expect(Year.nthWeekday(firstWeekday: Week.monday, weekday: Week.monday), 1);
    expect(Year.nthWeekday(firstWeekday: Week.monday, weekday: Week.monday, n: 2), 8);
    expect(Year.dateSpoken(14, 2), 'on dört Mart');
  });
}
