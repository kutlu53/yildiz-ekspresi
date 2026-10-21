/// Haftanın günleri: 0 Pazartesi ... 6 Pazar. Döngüsel hesaplar (n gün
/// sonra, kaç gün var) UI'dan bağımsızdır; Durak 7 ve takvim sahneleri
/// bu sınıfı kullanır.
class Week {
  Week._();

  static const names = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  static const ordinals = [
    'birinci',
    'ikinci',
    'üçüncü',
    'dördüncü',
    'beşinci',
    'altıncı',
    'yedinci',
  ];

  static const monday = 0;
  static const tuesday = 1;
  static const wednesday = 2;
  static const thursday = 3;
  static const friday = 4;
  static const saturday = 5;
  static const sunday = 6;

  /// Gün adı; 7 ve üstü ile eksi değerler döngüsel sarar.
  static String name(int day) => names[normalize(day)];

  static int normalize(int day) => ((day % 7) + 7) % 7;

  /// `n` gün sonra (eksi `n` gün önce).
  static int after(int day, int n) => normalize(day + n);

  /// `from` gününden `to` gününe kaç gün var (0-6; aynı günse 0).
  static int daysUntil(int from, int to) => normalize(to - from);

  /// "n gün sonra" yolundaki günler, başlangıç hariç, hedef dâhil.
  static List<int> path(int from, int steps) =>
      [for (var k = 1; k <= steps; k++) after(from, k)];
}
