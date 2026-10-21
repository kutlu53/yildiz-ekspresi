import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/core/clock_time.dart';
import 'package:zaman_bekcisi/core/turkish_time.dart';

void main() {
  group('TurkishTime.number', () {
    test('tekler ve onlar', () {
      expect(TurkishTime.number(5), 'beş');
      expect(TurkishTime.number(10), 'on');
      expect(TurkishTime.number(25), 'yirmi beş');
      expect(TurkishTime.number(48), 'kırk sekiz');
      expect(TurkishTime.number(0), 'sıfır');
      expect(TurkishTime.number(60), 'altmış');
    });

    test('yüzler', () {
      expect(TurkishTime.number(100), 'yüz');
      expect(TurkishTime.number(120), 'yüz yirmi');
      expect(TurkishTime.number(365), 'üç yüz altmış beş');
      expect(TurkishTime.number(200), 'iki yüz');
    });
  });

  group('TurkishTime.spoken24', () {
    test('günün bölümü ve saat', () {
      expect(TurkishTime.spoken24(const ClockTime(7, 0)), 'sabah yedi');
      expect(TurkishTime.spoken24(const ClockTime(12, 0)), 'öğlen on iki');
      expect(TurkishTime.spoken24(const ClockTime(15, 0)), 'öğleden sonra üç');
      expect(TurkishTime.spoken24(const ClockTime(20, 30)), 'akşam sekiz buçuk');
      expect(TurkishTime.spoken24(const ClockTime(3, 0)), 'gece üç');
      expect(TurkishTime.spoken24(const ClockTime(0, 0)), 'gece yarısı on iki');
      expect(TurkishTime.spoken24(const ClockTime(23, 0)), 'gece on bir');
    });
  });

  group('TurkishTime.spoken', () {
    test('tam saat', () {
      expect(TurkishTime.spoken(const ClockTime(3, 0)), 'saat üç');
      expect(TurkishTime.spoken(const ClockTime(0, 0)), 'saat on iki');
      expect(TurkishTime.spoken(const ClockTime(15, 0)), 'saat üç');
    });

    test('buçuk', () {
      expect(TurkishTime.spoken(const ClockTime(3, 30)), 'üç buçuk');
      expect(TurkishTime.spoken(const ClockTime(12, 30)), 'on iki buçuk');
    });

    test('çeyrek geçiyor (-i hâli)', () {
      expect(TurkishTime.spoken(const ClockTime(3, 15)), 'üçü çeyrek geçiyor');
      expect(TurkishTime.spoken(const ClockTime(4, 15)), 'dördü çeyrek geçiyor');
      expect(TurkishTime.spoken(const ClockTime(6, 15)), 'altıyı çeyrek geçiyor');
      expect(TurkishTime.spoken(const ClockTime(1, 15)), 'biri çeyrek geçiyor');
    });

    test('çeyrek var (-e hâli, bir sonraki saat)', () {
      expect(TurkishTime.spoken(const ClockTime(3, 45)), 'dörde çeyrek var');
      expect(TurkishTime.spoken(const ClockTime(11, 45)), 'on ikiye çeyrek var');
      expect(TurkishTime.spoken(const ClockTime(5, 45)), 'altıya çeyrek var');
    });

    test('geçiyor ve var', () {
      expect(TurkishTime.spoken(const ClockTime(3, 20)), 'üçü yirmi geçiyor');
      expect(TurkishTime.spoken(const ClockTime(7, 48)), 'sekize on iki var');
      expect(TurkishTime.spoken(const ClockTime(9, 5)), 'dokuzu beş geçiyor');
    });
  });

  group('TurkishTime.spokenDigital', () {
    test('tam saat ve dakikalı', () {
      expect(TurkishTime.spokenDigital(const ClockTime(3, 0)), 'saat üç');
      expect(TurkishTime.spokenDigital(const ClockTime(7, 48)), 'yedi kırk sekiz');
    });
  });
}
