import 'clock_time.dart';

/// Saatin Türkçe sözlü karşılığı: "saat üç", "üç buçuk", "üçü çeyrek geçiyor",
/// "dörde on var". Pamuk'un replikleri ve TTS bu sınıfı kullanır.
class TurkishTime {
  TurkishTime._();

  static const _hourNominative = [
    'on iki', 'bir', 'iki', 'üç', 'dört', 'beş',
    'altı', 'yedi', 'sekiz', 'dokuz', 'on', 'on bir',
  ];

  /// "-i" hâli: üçü, dördü, altıyı...
  static const _hourAccusative = [
    'on ikiyi', 'biri', 'ikiyi', 'üçü', 'dördü', 'beşi',
    'altıyı', 'yediyi', 'sekizi', 'dokuzu', 'onu', 'on biri',
  ];

  /// "-e" hâli: üçe, dörde, altıya...
  static const _hourDative = [
    'on ikiye', 'bire', 'ikiye', 'üçe', 'dörde', 'beşe',
    'altıya', 'yediye', 'sekize', 'dokuza', 'ona', 'on bire',
  ];

  static const _ones = [
    '', 'bir', 'iki', 'üç', 'dört', 'beş', 'altı', 'yedi', 'sekiz', 'dokuz',
  ];
  static const _tens = [
    '', 'on', 'yirmi', 'otuz', 'kırk', 'elli',
    'altmış', 'yetmiş', 'seksen', 'doksan',
  ];

  /// 0-999 arası sayının yazıyla okunuşu ("yüz yirmi", "üç yüz altmış beş").
  static String number(int n) {
    assert(n >= 0 && n < 1000);
    if (n == 0) return 'sıfır';
    final parts = <String>[];
    final h = n ~/ 100;
    if (h == 1) parts.add('yüz');
    if (h > 1) parts.add('${_ones[h]} yüz');
    final t = _tens[(n % 100) ~/ 10];
    final o = _ones[n % 10];
    if (t.isNotEmpty) parts.add(t);
    if (o.isNotEmpty) parts.add(o);
    return parts.join(' ');
  }

  /// Kadrandaki saat adı: "üç", "on iki".
  static String hourName(ClockTime t) => _hourNominative[t.hour % 12];

  /// Günlük konuşma: "saat üç", "üç buçuk", "üçü çeyrek geçiyor",
  /// "dörde çeyrek var", "üçü yirmi geçiyor", "dörde on var".
  static String spoken(ClockTime t) {
    final h = t.hour % 12;
    final next = (h + 1) % 12;
    final m = t.minute;
    if (m == 0) return 'saat ${_hourNominative[h]}';
    if (m == 30) return '${_hourNominative[h]} buçuk';
    if (m == 15) return '${_hourAccusative[h]} çeyrek geçiyor';
    if (m == 45) return '${_hourDative[next]} çeyrek var';
    if (m < 30) return '${_hourAccusative[h]} ${number(m)} geçiyor';
    return '${_hourDative[next]} ${number(60 - m)} var';
  }

  /// Günün bölümü: gece, sabah, öğlen, öğleden sonra, akşam.
  static String dayPart(int hour) {
    final h = hour % 24;
    if (h < 5) return 'gece';
    if (h < 11) return 'sabah';
    if (h < 13) return 'öğlen';
    if (h < 18) return 'öğleden sonra';
    if (h < 22) return 'akşam';
    return 'gece';
  }

  /// 24 saatlik sözlü okunuş: "sabah yedi", "öğleden sonra üç",
  /// "gece yarısı on iki", "akşam sekiz buçuk".
  static String spoken24(ClockTime t) {
    final h = t.hour % 24;
    if (h == 0 && t.minute == 0) return 'gece yarısı on iki';
    final base = t.minute == 0 ? _hourNominative[h % 12] : spoken(t);
    return '${dayPart(h)} $base';
  }

  /// Dijital okunuş: "üç sıfır beş" yerine "üç, beş" biçiminde sade;
  /// "saat üç" için "üç, sıfır sıfır" söylenmez, tam saatte "saat üç".
  static String spokenDigital(ClockTime t) {
    final h = _hourNominative[t.hour % 12];
    if (t.minute == 0) return 'saat $h';
    return '$h ${number(t.minute)}';
  }
}
