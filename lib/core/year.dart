import 'turkish_time.dart';

/// Yılın ayları (0 Ocak ... 11 Aralık), gün sayıları, mevsimler ve basit
/// takvim hesapları. UI'dan bağımsız; Durak 8 ve takvim sahneleri kullanır.
class Year {
  Year._();

  static const months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  static const days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

  static const seasons = ['İlkbahar', 'Yaz', 'Sonbahar', 'Kış'];
  static const spring = 0;
  static const summer = 1;
  static const autumn = 2;
  static const winter = 3;

  static int normalize(int month) => ((month % 12) + 12) % 12;

  static String name(int month) => months[normalize(month)];

  static int daysIn(int month) => days[normalize(month)];

  /// Yumruk kuralı: tepedeki aylar 31 çeker.
  static bool onKnuckle(int month) => daysIn(month) == 31;

  /// Ayın mevsimi: Mart-Mayıs ilkbahar, Haziran-Ağustos yaz,
  /// Eylül-Kasım sonbahar, Aralık-Şubat kış.
  static int seasonOf(int month) {
    final m = normalize(month);
    if (m >= 2 && m <= 4) return spring;
    if (m >= 5 && m <= 7) return summer;
    if (m >= 8 && m <= 10) return autumn;
    return winter;
  }

  static List<int> monthsOf(int season) =>
      [for (var m = 0; m < 12; m++) if (seasonOf(m) == season) m];

  /// Ayın ilk günü `firstWeekday` (0 Pazartesi) ise `day` hangi gün?
  static int weekdayOf({required int firstWeekday, required int day}) =>
      (firstWeekday + day - 1) % 7;

  /// Ayın `n`. (1'den başlar) verilen haftanın günü hangi tarih?
  static int nthWeekday({
    required int firstWeekday,
    required int weekday,
    int n = 1,
  }) {
    final offset = ((weekday - firstWeekday) % 7 + 7) % 7;
    return 1 + offset + (n - 1) * 7;
  }

  /// "on dört Mart" biçiminde sözlü tarih.
  static String dateSpoken(int day, int month) =>
      '${TurkishTime.number(day)} ${name(month)}';
}
