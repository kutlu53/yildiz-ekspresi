import 'dart:async';
import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ses efektleri. Dosyalar `assets/sfx/<id>.wav`; şimdilik `tool/gen_sfx.py`
/// ile sentezlenir, gerçek kayıt geldiğinde aynı adla değiştirilir.
enum SfxId {
  tick, // el bir adıma oturdu
  pop, // kart/parça yerine oturdu
  success, // sahne içi küçük başarı
  cheer, // durak bitti
  wrong, // yanlış (yumuşak)
  whistle, // tren düdüğü
  steam, // buhar
  bell, // köprü zili
  gear, // dişli, kapı, köprü
  chime, // fener, kilit
  drop, // damla
  snore, // Pamuk horlar
  wind, // kar/rüzgâr
  item, // vagona eşya eklendi
  chug, // tren yolda (döngü)
}

/// Arka plan müziği: sonbahar (durak 1-5), gece (6-7), kış (8-10).
enum MusicTheme { autumn, night, winter }

/// Ses efektleri ve müzik. Tek örnek; test ortamında ve ses kapalıyken
/// hiçbir eklenti çağrısı yapmaz, yalnızca `log` tutar.
class Sfx {
  Sfx._();

  static final Sfx instance = Sfx._();

  static const _prefEnabled = 'sfx.enabled';
  static const _prefMusic = 'sfx.music';

  /// Test ortamında eklenti yoktur; sesler yalnızca günlüğe yazılır.
  static final bool inTest =
      !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  bool enabled = true;
  bool musicEnabled = true;
  double musicVolume = 0.25;

  /// Müzik aralıklı çalar: tema bir kez çalınır, bu kadar susulur, yeniden
  /// çalınır. Sürekli döngü pilotta sinir bozucu bulundu (2026-10-29).
  Duration musicGap = const Duration(seconds: 45);

  /// Son çalınan efektler (testler ve hata ayıklama için).
  final List<SfxId> log = [];
  MusicTheme? currentTheme;
  bool chugging = false;

  final List<AudioPlayer> _pool = [];
  int _next = 0;
  AudioPlayer? _music;
  Timer? _musicTimer;
  StreamSubscription<void>? _musicDone;
  AudioPlayer? _chug;

  static MusicTheme themeFor(int stationNumber) {
    if (stationNumber <= 5) return MusicTheme.autumn;
    if (stationNumber <= 7) return MusicTheme.night;
    return MusicTheme.winter;
  }

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled = prefs.getBool(_prefEnabled) ?? true;
      musicEnabled = prefs.getBool(_prefMusic) ?? true;
    } catch (_) {}
  }

  Future<void> setEnabled(bool value) async {
    enabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefEnabled, value);
    } catch (_) {}
  }

  Future<void> setMusicEnabled(bool value) async {
    musicEnabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefMusic, value);
    } catch (_) {}
    if (!value) {
      await stopMusic();
    } else if (currentTheme != null) {
      final theme = currentTheme;
      currentTheme = null;
      await music(theme);
    }
  }

  AudioPlayer _player() {
    if (_pool.length < 6) {
      final p = AudioPlayer();
      _pool.add(p);
      return p;
    }
    final p = _pool[_next];
    _next = (_next + 1) % _pool.length;
    return p;
  }

  /// Efekti çalar; beklemez, hata fırlatmaz.
  void play(SfxId id, {double volume = 1}) {
    if (!enabled) return;
    log.add(id);
    if (log.length > 200) log.removeAt(0);
    if (inTest) return;
    try {
      final p = _player();
      unawaited(p.stop().then((_) =>
          p.play(AssetSource('sfx/${id.name}.wav'), volume: volume)));
    } catch (e) {
      debugPrint('Ses çalınamadı ($id): $e');
    }
  }

  /// Dokunsal tık: el bir adıma oturdu (mobilde hafif titreşim).
  void tick() {
    play(SfxId.tick, volume: 0.5);
    if (!kIsWeb && !inTest) {
      unawaited(HapticFeedback.selectionClick());
    }
  }

  /// Temayı başlatır; aynı tema zaten seçiliyse dokunmaz. `null` durdurur.
  /// Tema bir kez çalınır, `musicGap` kadar susulur, yeniden çalınır; sürekli
  /// döngü yoktur.
  Future<void> music(MusicTheme? theme) async {
    if (theme == null) {
      await stopMusic();
      return;
    }
    if (theme == currentTheme) return;
    currentTheme = theme;
    _musicTimer?.cancel();
    if (!enabled || !musicEnabled || inTest) return;
    await _playTheme(theme);
  }

  Future<void> _playTheme(MusicTheme theme) async {
    try {
      final p = _music ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      _musicDone ??= p.onPlayerComplete.listen((_) => _scheduleNext());
      await p.stop();
      await p.play(AssetSource('sfx/music_${theme.name}.wav'),
          volume: musicVolume);
    } catch (e) {
      debugPrint('Müzik çalınamadı: $e');
    }
  }

  /// Parça bitti: sessizlikten sonra aynı temayı yeniden çalar.
  void _scheduleNext() {
    _musicTimer?.cancel();
    final theme = currentTheme;
    if (theme == null) return;
    _musicTimer = Timer(musicGap, () {
      if (currentTheme == theme && enabled && musicEnabled) {
        unawaited(_playTheme(theme));
      }
    });
  }

  Future<void> stopMusic() async {
    currentTheme = null;
    _musicTimer?.cancel();
    _musicTimer = null;
    try {
      await _music?.stop();
    } catch (_) {}
  }

  /// Tren yolda: çuf çuf döngüsü.
  Future<void> chug(bool on) async {
    if (on == chugging) return;
    chugging = on;
    if (on) log.add(SfxId.chug);
    if (!enabled || inTest) return;
    try {
      if (on) {
        final p = _chug ??= AudioPlayer()..setReleaseMode(ReleaseMode.loop);
        await p.stop();
        await p.play(AssetSource('sfx/chug.wav'), volume: 0.5);
      } else {
        await _chug?.stop();
      }
    } catch (e) {
      debugPrint('Çuf çuf çalınamadı: $e');
    }
  }
}

/// Bir değer değişince efekt çalar: `trigger` eski değerinden farklı olduğunda
/// (ve `when` doğruysa) `id` çalınır. Dünyadaki nesneler (kapı, kol, fener)
/// bununla sarılır; nesne kodu sessiz kalır.
class Cue extends StatefulWidget {
  final Object? trigger;
  final SfxId id;
  final bool when;
  final double volume;
  final Widget child;

  const Cue({
    super.key,
    required this.trigger,
    required this.id,
    required this.child,
    this.when = true,
    this.volume = 1,
  });

  @override
  State<Cue> createState() => _CueState();
}

class _CueState extends State<Cue> {
  @override
  void didUpdateWidget(Cue old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && widget.when) {
      Sfx.instance.play(widget.id, volume: widget.volume);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
