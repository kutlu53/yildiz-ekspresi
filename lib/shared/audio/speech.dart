import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Türkçe seslendirme. Şimdilik TTS; gerçek ses kaydı geldiğinde `Line`
/// kimlikleriyle eşleşen dosyalar bu sınıfın içinden çalınacak, çağıran
/// kod değişmeyecek.
class Speech {
  Speech._();

  static final Speech instance = Speech._();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool _available = true;
  bool enabled = true;
  Completer<void>? _current;

  /// Eklenti cevap vermezse (motor yok, test ortamı) bu süre sonunda TTS
  /// devre dışı sayılır; oyun hiçbir zaman bir replikte donmaz.
  static const _initTimeout = Duration(seconds: 3);

  Future<void> _init() async {
    if (_ready) return;
    _ready = true;
    try {
      await Future.wait([
        _tts.setLanguage('tr-TR'),
        _tts.setSpeechRate(kIsWeb ? 0.85 : 0.45),
        _tts.setPitch(0.95),
        _tts.setVolume(1),
      ]).timeout(_initTimeout);
      _tts.setCompletionHandler(() => _current?.complete());
      _tts.setCancelHandler(() => _current?.complete());
      _tts.setErrorHandler((_) => _current?.complete());
    } catch (e) {
      debugPrint('TTS başlatılamadı: $e');
      _available = false;
    }
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
    if (!_available) {
      await Future<void>.delayed(_estimate(text));
      return;
    }
    final completer = Completer<void>();
    _current = completer;
    try {
      await _tts.speak(text).timeout(_initTimeout);
    } catch (e) {
      debugPrint('TTS hata: $e');
      if (!completer.isCompleted) completer.complete();
    }
    await completer.future.timeout(
      _estimate(text) + const Duration(seconds: 3),
      onTimeout: () {},
    );
    if (identical(_current, completer)) _current = null;
  }

  /// Beklemeden okur (geri bildirim ünlemleri için).
  void sayNow(String text) {
    unawaited(say(text));
  }

  Future<void> stop() async {
    final c = _current;
    if (c != null && !c.isCompleted) c.complete();
    _current = null;
    if (_available && _ready) {
      try {
        await _tts.stop();
      } catch (_) {}
    }
  }

  Duration _estimate(String text) =>
      Duration(milliseconds: 400 + text.length * 70);
}
