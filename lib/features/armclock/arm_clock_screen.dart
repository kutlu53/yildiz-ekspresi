import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/clock_time.dart';
import '../../core/turkish_time.dart';
import '../../shared/audio/sfx.dart';
import '../../shared/audio/speech.dart';
import '../../shared/widgets/draggable_clock.dart';
import '../../shared/widgets/pamuk.dart';
import '../../shared/widgets/scenery_view.dart';
import '../../shared/widgets/star_burst.dart';
import '../camera/pose_frame.dart';
import '../camera/pose_overlay_painter.dart';
import '../camera/pose_source.dart';
import '../story/lines.dart';
import '../story/models.dart';
import '../story/progress_store.dart';
import 'arm_clock_game.dart';

enum _Phase { calibrate, countdown, playing, between, result }

/// "Kol Saati": süreli, puanlı mini oyun. Kamera varsa çocuk kollarıyla
/// saati gösterir (sol kol akrep, sağ kol yelkovan); kamera yoksa ya da izin
/// verilmezse aynı oyun kadranı sürükleyerek oynanır. Görüntü yalnızca
/// cihazda işlenir, kaydedilmez, sunucuya gitmez.
class ArmClockScreen extends StatefulWidget {
  /// Kamerayı hiç denemeden sürükleme modunda başlat (test, kamerasız cihaz).
  final bool forceDrag;
  final int? seed;

  const ArmClockScreen({super.key, this.forceDrag = false, this.seed});

  @override
  State<ArmClockScreen> createState() => _ArmClockScreenState();
}

class _ArmClockScreenState extends State<ArmClockScreen>
    with SingleTickerProviderStateMixin {

  late final PoseSource _source = createPoseSource();
  late ArmClockGame _game = ArmClockGame.standard(seed: widget.seed);
  /// Oyun saati: kare zamanlayıcıdan gelir (testte sahte zamanla ilerler).
  late final Ticker _ticker = createTicker(_onTick);
  Duration _now = Duration.zero;
  final _store = ProgressStore.instance;

  StreamSubscription<PoseFrame>? _sub;
  Timer? _timer;
  _Phase _phase = _Phase.calibrate;
  bool _cameraMode = false;
  bool _cameraLoading = false;
  String? _cameraError;
  PoseFrame _frame = PoseFrame.empty;
  double _hold = 0;
  double _remaining = 1;
  int _countdown = 3;
  int _lastPoints = 0;
  int _celebrate = 0;
  ClockTime _dragTime = const ClockTime(12, 0);
  Duration _poseSeenSince = Duration.zero;
  bool _poseSeen = false;

  @override
  void initState() {
    super.initState();
    _cameraMode = !widget.forceDrag && _source.isSupported;
    _ticker.start();
    Sfx.instance.music(MusicTheme.winter);
    WidgetsBinding.instance.addPostFrameCallback((_) => _begin());
  }

  Future<void> _begin() async {
    if (_cameraMode) {
      await _startCamera();
    } else {
      _say(Lines.armIntroDrag);
    }
  }

  Future<void> _startCamera() async {
    setState(() {
      _cameraLoading = true;
      _cameraError = null;
    });
    _say(Lines.armIntroCamera);
    try {
      _sub ??= _source.frames.listen(_onFrame);
      await _source.start();
      if (mounted) setState(() => _cameraLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cameraLoading = false;
        _cameraError = '$e';
        _cameraMode = false;
      });
      _say(Lines.armCameraFallback);
    }
  }

  void _onTick(Duration elapsed) {
    _now = elapsed;
    if (_phase != _Phase.playing) return;
    final r = _game.remaining(_now);
    if (r != _remaining) setState(() => _remaining = r);
    if (r <= 0) _apply(_game.update(null, _now));
  }

  void _say(Line line) => unawaited(Speech.instance.say(line.text));
  void _sayText(String text) => unawaited(Speech.instance.say(text));

  void _onFrame(PoseFrame frame) {
    if (!mounted) return;
    final now = _now;
    final read = _phase == _Phase.playing ? _game.current.level.read(frame) : null;
    setState(() => _frame = frame);
    if (_phase == _Phase.calibrate) {
      final both = frame.hourArm != null && frame.minuteArm != null;
      if (both && !_poseSeen) {
        _poseSeen = true;
        _poseSeenSince = now;
      } else if (!both) {
        _poseSeen = false;
      }
      if (both && now - _poseSeenSince > const Duration(milliseconds: 1200)) {
        _startCountdown();
      }
      return;
    }
    if (_phase == _Phase.playing) _apply(_game.update(read, now));
  }

  void _startCountdown() {
    if (_phase != _Phase.calibrate) return;
    setState(() {
      _phase = _Phase.countdown;
      _countdown = 3;
    });
    _say(Lines.armReady);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_countdown <= 1) {
        t.cancel();
        _startRound();
      } else {
        setState(() => _countdown--);
        Sfx.instance.play(SfxId.tick, volume: 0.6);
      }
    });
  }

  void _startRound() {
    _game.startRound(_now);
    setState(() {
      _phase = _Phase.playing;
      _remaining = 1;
      _hold = 0;
      _dragTime = const ClockTime(12, 0);
    });
    _sayText(TurkishTime.spoken(_game.current.target));
    _timer?.cancel();
  }

  void _apply(ArmClockUpdate u) {
    switch (u.event) {
      case ArmClockEvent.none:
        setState(() => _hold = u.holdProgress);
        return;
      case ArmClockEvent.confirmed:
        Sfx.instance.play(SfxId.success);
        setState(() {
          _lastPoints = u.points;
          _celebrate++;
        });
        _sayText('${TurkishTime.number(u.points)} puan!');
      case ArmClockEvent.timeout:
        Sfx.instance.play(SfxId.wind, volume: 0.6);
        setState(() => _lastPoints = 0);
        _say(Lines.armTimeout);
      case ArmClockEvent.finished:
        break;
    }
    _timer?.cancel();
    if (_game.finished) {
      _finish();
      return;
    }
    setState(() => _phase = _Phase.between);
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) _startRound();
    });
  }

  Future<void> _finish() async {
    setState(() => _phase = _Phase.result);
    Sfx.instance.play(SfxId.cheer);
    if (_game.score > _store.progress.armClockBest) {
      await _store.setArmClockBest(_game.score);
    }
    if (!mounted) return;
    _sayText('${TurkishTime.number(_game.score)} puan, '
        '${TurkishTime.number(_game.stars)} yıldız. ${Lines.armDone.text}');
  }

  void _replay() {
    _timer?.cancel();
    setState(() {
      _game = ArmClockGame.standard();
      _phase = _cameraMode ? _Phase.calibrate : _Phase.countdown;
      _poseSeen = false;
      _countdown = 3;
    });
    if (!_cameraMode) _startCountdown();
  }

  void _onDragEnd() {
    if (_phase != _Phase.playing) return;
    _apply(_game.update(_dragTime, _now, instant: true));
  }

  @override
  void dispose() {
    _ticker.dispose();
    _timer?.cancel();
    _sub?.cancel();
    _source.dispose();
    Speech.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SceneryView(
        scenery: Scenery.snowfield,
        season: 0.9,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(flex: 7, child: _stage()),
                    SizedBox(width: 230, child: _side()),
                  ],
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: _HomeButton(onTap: () => Navigator.of(context).maybePop()),
              ),
              StarBurst(play: _celebrate, silent: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stage() {
    final target = _phase == _Phase.playing || _phase == _Phase.between
        ? _game.current.target
        : null;
    final Widget view;
    if (_cameraMode) {
      view = Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: AspectRatio(
          aspectRatio: _frame.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _source.buildPreview(),
              IgnorePointer(
                child: CustomPaint(
                  painter: PoseOverlayPainter(
                    frame: _frame,
                    target: target,
                    matched: _hold >= 1,
                  ),
                ),
              ),
              if (_cameraLoading)
                const Center(child: CircularProgressIndicator(color: Colors.white)),
            ],
          ),
        ),
      );
    } else {
      view = Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ClockFrame(
              style: ClockFrameStyle.ice,
              child: DraggableClock(
                time: _dragTime,
                draggable: _phase == _Phase.playing
                    ? const {ClockHand.hour, ClockHand.minute}
                    : const {},
                minuteStep: _phase == _Phase.playing ? _game.current.level.minuteStep.clamp(1, 30) : 5,
                onChanged: (t) => setState(() => _dragTime = t),
                onDragEnd: _onDragEnd,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _TopBar(
            remaining: _phase == _Phase.playing ? _remaining : null,
            score: _game.score,
            round: _game.index + 1,
            total: _game.rounds.length,
            streak: _game.streak,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  view,
                  if (_phase == _Phase.calibrate && _cameraMode)
                    _Veil(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.accessibility_new, size: 80, color: Colors.white),
                          const SizedBox(height: 8),
                          Text(
                            _cameraError == null
                                ? Lines.armCalibrate.text
                                : Lines.armCameraFallback.text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ],
                      ),
                    ),
                  if (_phase == _Phase.calibrate && !_cameraMode)
                    _Veil(
                      child: _BigTap(
                        key: const ValueKey('arm-start'),
                        icon: Icons.play_arrow_rounded,
                        label: 'Başla',
                        onTap: _startCountdown,
                      ),
                    ),
                  if (_phase == _Phase.countdown)
                    _Veil(
                      child: Text(
                        '$_countdown',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 120, fontWeight: FontWeight.w900),
                      ),
                    ),
                  if (_phase == _Phase.playing)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 10,
                      child: Center(
                        child: _Prompt(
                          text: TurkishTime.spoken(_game.current.target),
                          digital: _game.current.target.digital12,
                          hold: _hold,
                        ),
                      ),
                    ),
                  if (_phase == _Phase.between)
                    _Veil(
                      child: Text(
                        _lastPoints > 0 ? '+$_lastPoints' : Lines.armTimeout.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _lastPoints > 0 ? const Color(0xFFFFD54F) : Colors.white,
                          fontSize: _lastPoints > 0 ? 96 : 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  if (_phase == _Phase.result)
                    _Veil(
                      child: _Result(
                        score: _game.score,
                        stars: _game.stars,
                        best: _store.progress.armClockBest,
                        onReplay: _replay,
                        onHome: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _side() {
    final mood = switch (_phase) {
      _Phase.result => PamukMood.happy,
      _Phase.playing => PamukMood.thinking,
      _ => PamukMood.idle,
    };
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            _cameraMode ? Lines.armPrivacy.text : Lines.armDragHint.text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF263238)),
          ),
        ),
        Pamuk(mood: mood, size: 190),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final double? remaining;
  final int score;
  final int round;
  final int total;
  final int streak;

  const _TopBar({
    required this.remaining,
    required this.score,
    required this.round,
    required this.total,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white54,
              borderRadius: BorderRadius.circular(11),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: remaining ?? 1,
              child: Container(
                decoration: BoxDecoration(
                  color: (remaining ?? 1) > 0.3 ? const Color(0xFF4FC3F7) : const Color(0xFFFF8A65),
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _Chip(icon: Icons.star, text: '$score', color: const Color(0xFFFFD54F)),
        const SizedBox(width: 8),
        _Chip(icon: Icons.local_fire_department, text: '$streak', color: const Color(0xFFFF8A65)),
        const SizedBox(width: 8),
        _Chip(icon: Icons.flag, text: '$round/$total', color: Colors.white70),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _Chip({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF263238),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _Prompt extends StatelessWidget {
  final String text;
  final String digital;
  final double hold;

  const _Prompt({required this.text, required this.digital, required this.hold});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
                fontSize: 30, fontWeight: FontWeight.w800, color: Color(0xFF263238)),
          ),
          const SizedBox(width: 14),
          Text(
            digital,
            style: const TextStyle(fontSize: 22, color: Color(0xFF546E7A)),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              value: hold,
              strokeWidth: 6,
              color: const Color(0xFF66BB6A),
              backgroundColor: Colors.black12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Veil extends StatelessWidget {
  final Widget child;

  const _Veil({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: child,
    );
  }
}

class _BigTap extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BigTap({super.key, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: Color(0xFFFFB300),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 80, color: const Color(0xFF263238)),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final VoidCallback onTap;

  const _HomeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('arm-home'),
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(color: Color(0xFF263238), shape: BoxShape.circle),
        child: const Icon(Icons.train, color: Colors.white, size: 32),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  final int score;
  final int stars;
  final int best;
  final VoidCallback onReplay;
  final VoidCallback onHome;

  const _Result({
    required this.score,
    required this.stars,
    required this.best,
    required this.onReplay,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Icon(Icons.star_rounded,
                  size: 72,
                  color: i < stars ? const Color(0xFFFFD54F) : Colors.white24),
          ],
        ),
        Text(
          '$score',
          style: const TextStyle(
              color: Colors.white, fontSize: 80, fontWeight: FontWeight.w900),
        ),
        Text(
          'En iyi: $best',
          style: const TextStyle(color: Colors.white70, fontSize: 20),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BigTap(
              key: const ValueKey('arm-replay'),
              icon: Icons.replay_rounded,
              label: 'Bir daha',
              onTap: onReplay,
            ),
            const SizedBox(width: 40),
            _BigTap(
              key: const ValueKey('arm-exit'),
              icon: Icons.train,
              label: 'Trene dön',
              onTap: onHome,
            ),
          ],
        ),
      ],
    );
  }
}
