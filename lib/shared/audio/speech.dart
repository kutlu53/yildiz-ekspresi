import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Türkçe seslendirme. Şimdilik TTS; gerçek ses kaydı geldiğinde `Line`
/// kimlikleriyle eşleşen dosyalar bu sınıfın içinden çalınacak, çağıran
/// kod değişmeyecek.
///
/// Pilot notu (2026-10-29, "bazen konuşmuyor"): iki neden bulundu ve
/// giderildi. (1) `stop()` sonrası motorun geç gelen iptal/bitiş olayı yeni
/// repliğin bekleyicisini anında kapatıyor, sıradaki replik de yeni başlayan
/// konuşmayı kesiyordu; artık konuşma başladıktan hemen sonra gelen olaylar
/// yok sayılır ve gerçek bir durdurmadan sonra kısa süre beklenir (Chrome'da
/// cancel() hemen ardından speak() düşebiliyor). (2) Motor ilk açılışta geç
/// cevap verince TTS oturum boyunca kapanıyordu; artık birkaç kez denenir.
class Speech {
  Speech._();

  static final Speech instance = Speech._();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool _available = true;
  int _initAttempts = 0;
  bool enabled = true;
  Completer<void>? _current;
  DateTime? _speakStartedAt;
  bool _speakingNow = false;

  /// Eklenti cevap vermezse (motor yok, test ortamı) bu süre sonunda bu
  /// deneme başarısız sayılır; oyun hiçbir zaman bir replikte donmaz.
  static const _initTimeout = Duration(seconds: 3);
  static const _speakTimeout = Duration(seconds: 3);
  static const _maxInitAttempts = 2;

  /// Konuşma başladıktan sonra bu kadar kısa sürede gelen bitiş/iptal olayı
  /// bir önceki konuşmaya aittir; yok sayılır.
  static const _staleEventWindow = Duration(milliseconds: 250);

  /// Gerçek bir durdurmadan sonra motorun toparlanması için beklenir.
  static const _afterStopDelay = Duration(milliseconds: 80);

  Future<void> _init() async {
    if (_ready) return;
    if (!_available) return;
    _initAttempts++;
    try {
      await Future.wait([
        _tts.setLanguage('tr-TR'),
        _tts.setSpeechRate(kIsWeb ? 0.85 : 0.45),
        _tts.setPitch(0.95),
        _tts.setVolume(1),
      ]).timeout(_initTimeout);
      _tts.setStartHandler(_onStart);
      _tts.setCompletionHandler(_onEnd);
      _tts.setCancelHandler(_onEnd);
      _tts.setErrorHandler((_) => _onEnd());
      _ready = true;
    } catch (e) {
      debugPrint('TTS başlatılamadı ($_initAttempts. deneme): $e');
      if (_initAttempts >= _maxInitAttempts) _available = false;
    }
  }

  void _onStart() {
    _speakingNow = true;
  }

  void _onEnd() {
    final started = _speakStartedAt;
    if (started != null &&
        DateTime.now().difference(started) < _staleEventWindow) {
      // Önceki konuşmanın geç gelen olayı; yeni konuşmayı kapatma.
      return;
    }
    _speakingNow = false;
    final c = _current;
    if (c != null && !c.isCompleted) c.complete();
  }

  /// Metni okur ve bitene kadar bekler. TTS yoksa metin uzunluğuna göre
  /// bekler ki sinematik tempo bozulmasın. Kapalıysa hemen döner.
  Future<void> say(String text) async {
    if (!enabled) {
      await stop();
      return;
    }
    await _init();
    await stop();
    if (!_ready) {
      await Future<void>.delayed(_estimate(text));
      return;
    }
    final completer = Completer<void>();
    _current = completer;
    _speakStartedAt = DateTime.now();
    try {
      await _tts.speak(text).timeout(_speakTimeout);
    } catch (e) {
      debugPrint('TTS hata: $e');
      if (!completer.isCompleted) completer.complete();
    }
    await completer.future.timeout(
      _estimate(text) + const Duration(seconds: 3),
      onTimeout: () {},
    );
    if (identical(_current, completer)) {
      _current = null;
      _speakingNow = false;
    }
  }

  /// Beklemeden okur (geri bildirim ünlemleri için).
  void sayNow(String text) {
    unawaited(say(text));
  }

  Future<void> stop() async {
    final c = _current;
    if (c != null && !c.isCompleted) c.complete();
    _current = null;
    if (!_ready) return;
    final wasSpeaking = _speakingNow || c != null;
    _speakingNow = false;
    _speakStartedAt = null;
    if (!wasSpeaking) return;
    try {
      await _tts.stop();
    } catch (_) {}
    await Future<void>.delayed(_afterStopDelay);
  }

  Duration _estimate(String text) =>
      Duration(milliseconds: 400 + text.length * 70);
}
