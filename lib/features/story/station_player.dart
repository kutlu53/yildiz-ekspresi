import 'dart:async';

import 'package:flutter/material.dart';

import '../../shared/audio/sfx.dart';
import '../../shared/audio/speech.dart';
import 'cinematic_player.dart';
import 'lines.dart';
import 'models.dart';
import 'progress_store.dart';
import 'scene_scaffold.dart';
import 'stations/stations.dart';

enum _Phase { warmup, intro, scenes, outro }

/// Bir durağı baştan sona oynatır: giriş sinematiği, sahneler, kapanış.
/// Çıkış düğmesi yok; akış kendiliğinden ilerler ve `onDone` ile biter.
/// Her sahne sonunda ilerleme kaydedilir; yarım kalan durak kaldığı
/// sahneden devam eder. Önceki oturumda yanlış yapılan bir sahne varsa önce
/// o "ısınma" olarak gelir. Çocuk 12 sn hareketsiz kalırsa Pamuk son
/// söylediğini tekrar eder; Pamuk'a dokunmak da tekrar ettirir.
class StationPlayer extends StatefulWidget {
  final Station station;
  final VoidCallback onDone;

  /// Yeniden oynatma (oyun sonu modu): baştan başlar, ilerlemeye yazmaz,
  /// ödül vermez.
  final bool replay;

  const StationPlayer({
    super.key,
    required this.station,
    required this.onDone,
    this.replay = false,
  });

  @override
  State<StationPlayer> createState() => _StationPlayerState();
}

class _StationPlayerState extends State<StationPlayer>
    implements SceneController {
  static const _idleRepeat = Duration(seconds: 12);

  final _store = ProgressStore.instance;
  final _caption = ValueNotifier<String?>(null);
  final _mood = ValueNotifier<PamukMood>(PamukMood.idle);
  final _wobble = ValueNotifier<int>(0);
  final _jump = ValueNotifier<int>(0);

  _Phase _phase = _Phase.intro;
  int _sceneIndex = 0;
  Scene? _warmup;
  int _generation = 0;
  String? _lastSpoken;
  Timer? _idle;
  bool _speaking = false;

  Station get station => widget.station;

  @override
  void initState() {
    super.initState();
    Sfx.instance.music(Sfx.themeFor(station.number));
    _prepare();
  }

  Future<void> _prepare() async {
    final progress = _store.progress;
    final resume = widget.replay
        ? 0
        : (progress.sceneIndex[station.number] ?? 0)
            .clamp(0, station.scenes.length - 1);
    final retryKey = widget.replay ? null : await _store.takeRetry();
    if (retryKey != null && retryKey != station.sceneKey(resume)) {
      _warmup = StationRegistry.sceneByKey(retryKey);
    }
    if (!mounted) return;
    setState(() {
      _sceneIndex = resume;
      if (_warmup != null) {
        _phase = _Phase.warmup;
      } else if (resume > 0) {
        _phase = _Phase.scenes;
      } else {
        _phase = _Phase.intro;
      }
    });
    if (resume > 0 && _warmup == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => say(Lines.resume));
    }
  }

  @override
  void dispose() {
    _idle?.cancel();
    Speech.instance.stop();
    _caption.dispose();
    _mood.dispose();
    _wobble.dispose();
    _jump.dispose();
    super.dispose();
  }

  void _resetIdle() {
    _idle?.cancel();
    if (_phase != _Phase.scenes && _phase != _Phase.warmup) return;
    _idle = Timer(_idleRepeat, _repeat);
  }

  void _repeat() {
    if (_speaking) {
      _resetIdle();
      return;
    }
    final text = _lastSpoken;
    if (text != null) sayText(text);
  }

  // SceneController

  @override
  void complete() {
    if (!mounted) return;
    _jump.value++;
    switch (_phase) {
      case _Phase.warmup:
        setState(() {
          _warmup = null;
          _phase = _sceneIndex > 0 ? _Phase.scenes : _Phase.intro;
          _generation++;
          _caption.value = null;
        });
      case _Phase.scenes:
        final next = _sceneIndex + 1;
        if (next < station.scenes.length) {
          if (!widget.replay) _store.setSceneIndex(station.number, next);
          setState(() {
            _sceneIndex = next;
            _generation++;
            _caption.value = null;
          });
        } else {
          _idle?.cancel();
          Sfx.instance.play(SfxId.cheer);
          setState(() => _phase = _Phase.outro);
        }
      default:
        break;
    }
  }

  @override
  void mistake() {
    Sfx.instance.play(SfxId.wrong, volume: 0.6);
    _wobble.value++;
    if (_phase == _Phase.scenes && !widget.replay) {
      _store.addRetry(station.sceneKey(_sceneIndex));
    }
  }

  int _praise = 0;

  @override
  Future<void> say(Line line) {
    if (line.id == Lines.great.id || line.id == Lines.wellDone.id) {
      _praise = (_praise + 1) % Lines.praise.length;
      return sayText(Lines.praise[_praise].text);
    }
    return sayText(line.text);
  }

  @override
  Future<void> sayText(String text) async {
    if (!mounted) return;
    _lastSpoken = text;
    _caption.value = text;
    _mood.value = PamukMood.talking;
    _speaking = true;
    await Speech.instance.say(text);
    _speaking = false;
    if (mounted && _mood.value == PamukMood.talking) {
      _mood.value = PamukMood.idle;
    }
    _resetIdle();
  }

  Future<void> _finishStation() async {
    if (!widget.replay) {
      Sfx.instance.play(SfxId.item);
      await _store.completeStation(station.number, station.reward.id);
    }
    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _store.progress;
    final scarf = progress.items.contains('scarf');
    final wagons = 1 + progress.items.length;

    switch (_phase) {
      case _Phase.intro:
        return CinematicPlayer(
          key: const ValueKey('intro'),
          shots: station.intro,
          scenery: station.scenery,
          season: station.season,
          wagons: wagons,
          scarf: scarf,
          onDone: () => setState(() {
            _phase = _Phase.scenes;
            _resetIdle();
          }),
        );
      case _Phase.outro:
        return CinematicPlayer(
          key: const ValueKey('outro'),
          shots: station.outro,
          scenery: station.scenery,
          season: station.season,
          wagons: wagons + 1,
          scarf: scarf || station.reward.id == 'scarf',
          celebrate: true,
          onDone: _finishStation,
        );
      case _Phase.warmup:
      case _Phase.scenes:
        final scene = _phase == _Phase.warmup
            ? _warmup!
            : station.scenes[_sceneIndex];
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _resetIdle(),
          child: SceneScaffold(
            scenery: station.scenery,
            season: station.season,
            caption: _caption,
            mood: _mood,
            wobble: _wobble,
            jump: _jump,
            scarf: scarf,
            onPamukTap: _repeat,
            child: KeyedSubtree(
              key: ValueKey('${_phase.name}-$_sceneIndex-$_generation'),
              child: scene.build(context, this),
            ),
          ),
        );
    }
  }
}
