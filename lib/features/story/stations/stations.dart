import '../models.dart';
import 'station1_garaj.dart';
import 'station2_ilk_hat.dart';
import 'station3_kopru.dart';
import 'station4_fener.dart';
import 'station5_istasyon.dart';
import 'station6_gece.dart';
import 'station7_pazar.dart';
import 'station8_vadi.dart';
import 'station9_etek.dart';
import 'extras.dart';
import 'station10_yuva.dart';

/// Tüm duraklar (1-10).
class StationRegistry {
  StationRegistry._();

  static final List<Station> stations = [
    station1,
    station2,
    station3,
    station4,
    station5,
    station6,
    station7,
    station8,
    station9,
    station10,
  ];

  /// Oyun sonu modu: haritadan açılan, ilerlemeye sayılmayan içerikler.
  static Station quickClock({int? seed}) => quickClockStation(seed: seed);
  static Station get timeGates => timeGatesStation;

  /// Sınıf ön ayarı: 2. sınıf 1-3 ve 6-7, 3. sınıf 1-8, 4. sınıf / null tümü.
  static List<Station> forGrade(int? grade) {
    final numbers = switch (grade) {
      2 => const {1, 2, 3, 6, 7},
      3 => const {1, 2, 3, 4, 5, 6, 7, 8},
      _ => null,
    };
    if (numbers == null) return stations;
    return [for (final s in stations) if (numbers.contains(s.number)) s];
  }

  /// Sınıfa göre sıradaki durak: tamamlananın üstündeki ilk durak.
  static Station? nextFor(int? grade, int completed) {
    for (final s in forGrade(grade)) {
      if (s.number > completed) return s;
    }
    return null;
  }

  static Station? byNumber(int number) {
    for (final s in stations) {
      if (s.number == number) return s;
    }
    return null;
  }

  /// "2.read" gibi bir anahtardan sahneyi bulur (ısınma için).
  static Scene? sceneByKey(String key) {
    final dot = key.indexOf('.');
    if (dot < 0) return null;
    final number = int.tryParse(key.substring(0, dot));
    final id = key.substring(dot + 1);
    final station = number == null ? null : byNumber(number);
    if (station == null) return null;
    for (final s in station.scenes) {
      if (s.id == id) return s;
    }
    return null;
  }

  static VagonItem? itemById(String id) {
    for (final s in stations) {
      if (s.reward.id == id) return s.reward;
    }
    return null;
  }
}
