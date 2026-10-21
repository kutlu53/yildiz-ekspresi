import 'dart:math' as math;

import '../../../core/clock_time.dart';
import '../../mechanics/pick_clock.dart';
import '../../mechanics/read_clock.dart';

/// Tam saat turu: doğru cevap ve iki farklı tam saat çeldirici.
ReadClockRound fullHourRound(ClockTime shown, {int seed = 0}) {
  final rnd = math.Random(seed);
  final hours = <int>{shown.hour % 12};
  while (hours.length < 3) {
    hours.add(rnd.nextInt(12));
  }
  final options = hours.map((h) => ClockTime(h, 0)).toList()..shuffle(rnd);
  return ReadClockRound(shown: shown, options: options);
}

/// Dijital-analog eşleme turu: doğru saat ve iki çeldirici. Çeldiriciler
/// bilerek karıştırılabilir olanlardır: akrep ile yelkovan yer değiştirmiş
/// (3:25 için 5:15) ve yalnız dakikası farklı (3:25 için 3:45).
PickClockRound digitalRound(ClockTime target, {int seed = 0}) {
  final rnd = math.Random(seed);
  final h = target.hour % 12;
  final m = target.minute;
  final swapped = ClockTime(m ~/ 5 == 0 ? (h + 6) % 12 : m ~/ 5, h * 5);
  var otherMinute = ((m ~/ 5 + 3 + rnd.nextInt(6)) % 12) * 5;
  if (m % 5 != 0) otherMinute = (m + 10 + rnd.nextInt(30)) % 60;
  final sameHour = ClockTime(h, otherMinute);
  final options = <ClockTime>[target];
  for (final c in [swapped, sameHour, ClockTime((h + 5) % 12, m)]) {
    if (options.length == 3) break;
    if (options.any((o) => o.sameOnDial(c))) continue;
    options.add(c);
  }
  options.shuffle(rnd);
  return PickClockRound(target: target, options: options);
}

/// 5'er dakika turu: aynı saatin üç farklı 5'lik dakikası (doğru dâhil).
ReadClockRound fiveMinuteRound(ClockTime shown, {int seed = 0}) {
  final rnd = math.Random(seed);
  final h = shown.hour % 12;
  final minutes = <int>{shown.minute};
  while (minutes.length < 3) {
    minutes.add(rnd.nextInt(12) * 5);
  }
  final options = minutes.map((m) => ClockTime(h, m)).toList()..shuffle(rnd);
  return ReadClockRound(shown: shown, options: options);
}

/// Buçuk/çeyrek turu: aynı saatin tam, buçuk, çeyrek geçe ve çeyrek kala
/// hâllerinden üçü (doğru olan dâhil).
ReadClockRound quarterRound(ClockTime shown, {int seed = 0}) {
  final rnd = math.Random(seed);
  final h = shown.hour % 12;
  final candidates = [0, 15, 30, 45]
      .where((m) => m != shown.minute)
      .map((m) => ClockTime(h, m))
      .toList()
    ..shuffle(rnd);
  final options = [ClockTime(h, shown.minute), ...candidates.take(2)]
    ..shuffle(rnd);
  return ReadClockRound(shown: shown, options: options);
}
