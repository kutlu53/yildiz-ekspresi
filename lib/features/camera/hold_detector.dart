/// Bir değerin belirli süre sabit kalıp kalmadığını izler.
///
/// Kamera modunda poz 1,5-2 sn sabit kalınca doğrulanır; bu sınıf UI'dan
/// bağımsızdır ve zamanı dışarıdan alır, böylece test edilebilir.
class HoldDetector<T> {
  final Duration holdDuration;

  T? _candidate;
  Duration? _candidateSince;
  T? _confirmed;

  HoldDetector({this.holdDuration = const Duration(milliseconds: 1500)});

  /// Son doğrulanan değer; `reset` çağrılana kadar kalır.
  T? get confirmed => _confirmed;

  /// Şu an izlenen aday.
  T? get candidate => _candidate;

  /// Yeni bir okuma verir. `now` monoton bir zaman olmalı.
  /// Dönen değer 0-1 arası ilerleme ve bu çağrıda doğrulama olup olmadığı.
  HoldUpdate update(T? value, Duration now) {
    if (value == null) {
      _candidate = null;
      _candidateSince = null;
      return const HoldUpdate(progress: 0, justConfirmed: false);
    }

    if (value != _candidate) {
      _candidate = value;
      _candidateSince = now;
      return const HoldUpdate(progress: 0, justConfirmed: false);
    }

    final held = now - _candidateSince!;
    final progress = holdDuration.inMicroseconds == 0
        ? 1.0
        : (held.inMicroseconds / holdDuration.inMicroseconds).clamp(0.0, 1.0);

    if (progress >= 1 && _confirmed != value) {
      _confirmed = value;
      return HoldUpdate(progress: 1, justConfirmed: true);
    }
    return HoldUpdate(progress: progress, justConfirmed: false);
  }

  void reset() {
    _candidate = null;
    _candidateSince = null;
    _confirmed = null;
  }
}

class HoldUpdate {
  final double progress;
  final bool justConfirmed;

  const HoldUpdate({required this.progress, required this.justConfirmed});
}
