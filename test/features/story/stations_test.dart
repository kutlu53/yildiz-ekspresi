import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/features/story/stations/stations.dart';

void main() {
  test('duraklar sıralı, her sahne anahtarı ve eşya kimliği tekil', () {
    final stations = StationRegistry.stations;
    expect(stations.length, 10);
    for (var i = 0; i < stations.length; i++) {
      expect(stations[i].number, i + 1);
      expect(stations[i].scenes, isNotEmpty);
      expect(stations[i].intro, isNotEmpty);
      expect(stations[i].outro, isNotEmpty);
    }
    final keys = <String>{};
    for (final s in stations) {
      for (var i = 0; i < s.scenes.length; i++) {
        final key = s.sceneKey(i);
        expect(keys.add(key), isTrue, reason: '$key tekrar ediyor');
        expect(StationRegistry.sceneByKey(key), same(s.scenes[i]));
      }
    }
    final items = stations.map((s) => s.reward.id).toSet();
    expect(items.length, stations.length);
    expect(StationRegistry.itemById('lantern')?.name, 'Fener');
  });

  test('Durak 4 Fener Tüneli: say, kur, damla', () {
    final s4 = StationRegistry.byNumber(4)!;
    expect(s4.place, 'Fener Tüneli');
    expect(s4.scenes.map((s) => s.id), ['count', 'set', 'drip']);
  });

  test('Durak 5 Büyük İstasyon: pano, peron, sözlü, kapı', () {
    final s5 = StationRegistry.byNumber(5)!;
    expect(s5.place, 'Büyük İstasyon');
    expect(s5.scenes.map((s) => s.id), ['board', 'platform', 'spoken', 'gate']);
    expect(StationRegistry.itemById('ticket')?.name, 'Bilet');
  });

  test('Durak 6 Gece Hattı: pencere, gün, on beş', () {
    final s6 = StationRegistry.byNumber(6)!;
    expect(s6.place, 'Gece Hattı');
    expect(s6.scenes.map((s) => s.id), ['window', 'day', 'fifteen']);
    expect(StationRegistry.itemById('star_map')?.name, 'Yıldız haritası');
  });

  test('Durak 7 Pazar Kasabası: taşlar, pano, av', () {
    final s7 = StationRegistry.byNumber(7)!;
    expect(s7.place, 'Pazar Kasabası');
    expect(s7.scenes.map((s) => s.id), ['stones', 'board', 'hunt']);
    expect(StationRegistry.itemById('honey')?.name, 'Bal kavanozu');
  });

  test('Durak 8 Mevsim Vadisi: kasabalar, evler, vagonlar, takvim', () {
    final s8 = StationRegistry.byNumber(8)!;
    expect(s8.place, 'Mevsim Vadisi');
    expect(s8.scenes.map((s) => s.id), ['towns', 'houses', 'wagons', 'calendar']);
    expect(StationRegistry.itemById('leaves'), isNotNull);
  });

  test('Durak 9 Kar Dağı Eteği: terazi, tarife, hızlı saat', () {
    final s9 = StationRegistry.byNumber(9)!;
    expect(s9.place, 'Kar Dağı Eteği');
    expect(s9.scenes.map((s) => s.id), ['balance', 'timetable', 'quick']);
    expect(StationRegistry.itemById('key')?.name, 'Yuvanın anahtarı');
    expect(s9.season, greaterThan(0.7)); // kar yağar
  });

  test('sınıf ön ayarı: 2. sınıf 1-3 ve 6-7, 3. sınıf 1-8, tümü 10', () {
    expect(StationRegistry.forGrade(2).map((s) => s.number), [1, 2, 3, 6, 7]);
    expect(StationRegistry.forGrade(3).length, 8);
    expect(StationRegistry.forGrade(4).length, 10);
    expect(StationRegistry.forGrade(null).length, 10);
    expect(StationRegistry.nextFor(2, 3)?.number, 6); // 4-5 atlanır
    expect(StationRegistry.nextFor(2, 7), isNull);
    expect(StationRegistry.nextFor(null, 7)?.number, 8);
  });

  test('Durak 10 Yuva: beş dişli, beş karışık görev', () {
    final s10 = StationRegistry.byNumber(10)!;
    expect(s10.place, 'Yuva');
    expect(s10.scenes.map((s) => s.id), ['set', 'read', 'day', 'calendar', 'balance']);
    expect(s10.season, 1);
    expect(StationRegistry.byNumber(11), isNull);
  });
}
