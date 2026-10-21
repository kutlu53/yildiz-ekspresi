import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/core/clock_time.dart';
import 'package:zaman_bekcisi/features/camera/hold_detector.dart';

void main() {
  const t3 = ClockTime(3, 0);
  const t6 = ClockTime(6, 0);

  test('aynı değer 1,5 sn sürünce doğrulanır', () {
    final d = HoldDetector<ClockTime>();
    expect(d.update(t3, Duration.zero).progress, 0);
    final mid = d.update(t3, const Duration(milliseconds: 750));
    expect(mid.progress, closeTo(0.5, 1e-9));
    expect(mid.justConfirmed, isFalse);
    final done = d.update(t3, const Duration(milliseconds: 1500));
    expect(done.progress, 1);
    expect(done.justConfirmed, isTrue);
    expect(d.confirmed, t3);
  });

  test('doğrulama yalnızca bir kez tetiklenir', () {
    final d = HoldDetector<ClockTime>();
    d.update(t3, Duration.zero);
    d.update(t3, const Duration(seconds: 2));
    final again = d.update(t3, const Duration(seconds: 3));
    expect(again.justConfirmed, isFalse);
    expect(again.progress, 1);
  });

  test('değer değişince sayaç sıfırlanır', () {
    final d = HoldDetector<ClockTime>();
    d.update(t3, Duration.zero);
    d.update(t3, const Duration(seconds: 1));
    final changed = d.update(t6, const Duration(milliseconds: 1100));
    expect(changed.progress, 0);
    final later = d.update(t6, const Duration(milliseconds: 1600));
    expect(later.progress, closeTo(1 / 3, 1e-9));
  });

  test('null okuma adayı düşürür', () {
    final d = HoldDetector<ClockTime>();
    d.update(t3, Duration.zero);
    d.update(null, const Duration(seconds: 1));
    expect(d.candidate, isNull);
    final restart = d.update(t3, const Duration(seconds: 2));
    expect(restart.progress, 0);
  });

  test('reset sonrası aynı değer yeniden doğrulanabilir', () {
    final d = HoldDetector<ClockTime>();
    d.update(t3, Duration.zero);
    d.update(t3, const Duration(seconds: 2));
    d.reset();
    d.update(t3, const Duration(seconds: 3));
    expect(d.update(t3, const Duration(seconds: 5)).justConfirmed, isTrue);
  });
}
