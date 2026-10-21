import 'dart:math' as math;

import '../../core/angle_mapper.dart';
import '../../core/clock_time.dart';
import '../camera/hold_detector.dart';
import '../camera/pose_frame.dart';

/// "Kol Saati" mini oyununun saf Dart mantığı: turlar, süre, puan, seri.
/// UI'dan bağımsızdır; zamanı dışarıdan alır, bu yüzden test edilebilir.
///
/// Çocuk kollarıyla saati gösterir: sol kol akrep, sağ kol yelkovan. Her
/// turda söylenen saat belirli süre içinde gösterilip 1,5 sn sabit
/// tutulunca puan alınır; kalan süre ve seri puanı artırır. Süre dolarsa
/// ceza yok, sıradaki saate geçilir.
class ArmClockLevel {
  final String name;
  final int minuteStep;
  final double minuteTolerance;
  final double hourTolerance;
  final Duration roundTime;

  const ArmClockLevel({
    required this.name,
    required this.minuteStep,
    required this.minuteTolerance,
    required this.hourTolerance,
    required this.roundTime,
  });

  static const full = ArmClockLevel(
    name: 'tam saatler',
    minuteStep: 60,
    minuteTolerance: 22,
    hourTolerance: 22,
    roundTime: Duration(seconds: 12),
  );
  static const half = ArmClockLevel(
    name: 'buçuklar',
    minuteStep: 30,
    minuteTolerance: 20,
    hourTolerance: 22,
    roundTime: Duration(seconds: 11),
  );
  static const quarter = ArmClockLevel(
    name: 'çeyrekler',
    minuteStep: 15,
    minuteTolerance: 16,
    hourTolerance: 20,
    roundTime: Duration(seconds: 10),
  );
  static const five = ArmClockLevel(
    name: 'beşer dakika',
    minuteStep: 5,
    minuteTolerance: 13,
    hourTolerance: 18,
    roundTime: Duration(seconds: 9),
  );

  /// Kamera kolunun okuyabileceği saat; tolerans dışında null.
  ClockTime? read(PoseFrame frame) {
    final hour = frame.hourArm?.angle;
    final minute = frame.minuteArm?.angle;
    if (hour == null || minute == null) return null;
    return AngleMapper.readClock(
      hourAngle: hour,
      minuteAngle: minute,
      minuteStep: minuteStep == 60 ? 30 : minuteStep,
      minuteTolerance: minuteTolerance,
      hourTolerance: hourTolerance,
    );
  }

  /// Bu seviyede rastgele bir hedef (dakika adıma oturur).
  ClockTime randomTarget(math.Random rnd, {ClockTime? avoid}) {
    for (var i = 0; i < 20; i++) {
      final h = rnd.nextInt(12);
      final m = minuteStep == 60 ? 0 : rnd.nextInt(60 ~/ minuteStep) * minuteStep;
      final t = ClockTime(h, m);
      if (avoid == null || !t.sameOnDial(avoid)) return t;
    }
    return ClockTime(rnd.nextInt(12), 0);
  }
}

class ArmClockRound {
  final ClockTime target;
  final ArmClockLevel level;

  const ArmClockRound({required this.target, required this.level});
}

enum ArmClockEvent { none, confirmed, timeout, finished }

class ArmClockUpdate {
  final ArmClockEvent event;
  final int points;
  final double holdProgress;

  /// Okunan saat (hedef olmasa da) kadran bindirmesi için.
  final ClockTime? read;

  const ArmClockUpdate({
    required this.event,
    this.points = 0,
    this.holdProgress = 0,
    this.read,
  });
}

class ArmClockGame {
  static const basePoints = 100;
  static const timeBonus = 100;
  static const streakBonus = 25;
  static const maxStreakBonus = 100;

  final List<ArmClockRound> rounds;
  final HoldDetector<ClockTime> _hold;

  int _index = 0;
  int score = 0;
  int streak = 0;
  int confirmed = 0;
  Duration? _roundStart;
  bool finished = false;

  ArmClockGame({required this.rounds, Duration hold = const Duration(milliseconds: 1500)})
      : _hold = HoldDetector<ClockTime>(holdDuration: hold);

  /// Standart oyun: 10 tur, kolaydan zora (3 tam, 3 buçuk, 2 çeyrek, 2 beşer).
  factory ArmClockGame.standard({int? seed, Duration hold = const Duration(milliseconds: 1500)}) {
    final rnd = math.Random(seed ?? DateTime.now().millisecondsSinceEpoch);
    const plan = [
      ArmClockLevel.full, ArmClockLevel.full, ArmClockLevel.full,
      ArmClockLevel.half, ArmClockLevel.half, ArmClockLevel.half,
      ArmClockLevel.quarter, ArmClockLevel.quarter,
      ArmClockLevel.five, ArmClockLevel.five,
    ];
    final rounds = <ArmClockRound>[];
    ClockTime? last;
    for (final level in plan) {
      final t = level.randomTarget(rnd, avoid: last);
      rounds.add(ArmClockRound(target: t, level: level));
      last = t;
    }
    return ArmClockGame(rounds: rounds, hold: hold);
  }

  int get index => _index;
  ArmClockRound get current => rounds[_index];
  int get maxScore => rounds.length * (basePoints + timeBonus) +
      _streakTotal(rounds.length);

  static int _streakTotal(int n) {
    var sum = 0;
    for (var s = 1; s < n; s++) {
      sum += math.min(streakBonus * s, maxStreakBonus);
    }
    return sum;
  }

  /// 0-3 yıldız.
  int get stars {
    final r = score / maxScore;
    if (r >= 0.75) return 3;
    if (r >= 0.45) return 2;
    if (r >= 0.15) return 1;
    return 0;
  }

  /// Turu başlatır (süre sayacı `now`dan başlar).
  void startRound(Duration now) {
    _roundStart = now;
    _hold.reset();
  }

  /// Kalan süre oranı 0-1.
  double remaining(Duration now) {
    final start = _roundStart;
    if (start == null) return 1;
    final total = current.level.roundTime.inMicroseconds;
    final left = total - (now - start).inMicroseconds;
    return (left / total).clamp(0.0, 1.0);
  }

  /// Yeni bir okuma (kamera karesinden ya da sürüklemeden). Sürükleme modu
  /// için `instant` açıkken sabit tutma beklenmez.
  ArmClockUpdate update(ClockTime? read, Duration now, {bool instant = false}) {
    if (finished || _roundStart == null) {
      return ArmClockUpdate(event: ArmClockEvent.none, read: read);
    }
    final target = current.target;
    final matched = read != null && read.sameOnDial(target);

    if (remaining(now) <= 0) {
      streak = 0;
      return _advance(ArmClockEvent.timeout, 0, read);
    }

    if (instant) {
      if (!matched) return ArmClockUpdate(event: ArmClockEvent.none, read: read);
      return _confirm(now, read);
    }

    final h = _hold.update(matched ? target : null, now);
    if (h.justConfirmed) return _confirm(now, read);
    return ArmClockUpdate(event: ArmClockEvent.none, holdProgress: h.progress, read: read);
  }

  ArmClockUpdate _confirm(Duration now, ClockTime? read) {
    final bonus = (remaining(now) * timeBonus).round();
    final streakPts = math.min(streakBonus * streak, maxStreakBonus);
    final points = basePoints + bonus + streakPts;
    score += points;
    streak++;
    confirmed++;
    return _advance(ArmClockEvent.confirmed, points, read);
  }

  ArmClockUpdate _advance(ArmClockEvent event, int points, ClockTime? read) {
    _roundStart = null;
    _hold.reset();
    if (_index + 1 >= rounds.length) {
      finished = true;
      return ArmClockUpdate(event: event, points: points, read: read);
    }
    _index++;
    return ArmClockUpdate(event: event, points: points, read: read);
  }
}
