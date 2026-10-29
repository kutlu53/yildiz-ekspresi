import 'package:flutter/material.dart';

import '../../shared/audio/sfx.dart';
import '../../shared/widgets/pamuk.dart';
import '../../shared/widgets/route_map.dart';
import '../../shared/widgets/scenery_view.dart';
import '../../shared/widgets/train.dart';
import '../armclock/arm_clock_screen.dart';
import '../teacher/teacher_panel.dart';
import 'cinematic_player.dart';
import 'finale.dart';
import 'lines.dart';
import 'models.dart';
import 'progress_store.dart';
import 'station_player.dart';
import 'stations/prolog.dart';
import 'stations/stations.dart';

enum _Step { title, prolog, travel, station, replay, end }

/// Hikâyenin tamamı tek akış: başlık → prolog → (yolculuk → durak)... → son.
/// Menü yok. Başlıkta Pamuk'a dokunmak hikâyeyi başlatır (tarayıcıda sesin
/// açılması için gereken tek dokunuş budur). Pamuk'a uzun basmak gizli
/// öğretmen menüsünü açar. Başlıktaki haritada tren tamamlanan durakta
/// durur; açık bir durağa dokunmak onu yeniden oynatır (oyun sonu modu),
/// hikâye bitince kar tanesi Hızlı Saat'i, kapı Zaman Kapıları'nı açar.
class StoryFlow extends StatefulWidget {
  const StoryFlow({super.key});

  @override
  State<StoryFlow> createState() => _StoryFlowState();
}

class _StoryFlowState extends State<StoryFlow> {
  final _store = ProgressStore.instance;
  _Step _step = _Step.title;
  Station? _station;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    Sfx.instance.loadSettings();
    _store.load().then((_) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  Progress get _p => _store.progress;

  List<Station> get _stations => StationRegistry.forGrade(_p.grade);

  Station? _nextStation() =>
      StationRegistry.nextFor(_p.grade, _p.completedStation);

  /// Sınıfın son durağı da bitti mi?
  bool get _finished =>
      _stations.isNotEmpty && _p.completedStation >= _stations.last.number;

  /// Yolculuğun tamamı (Yuva dâhil) bitti mi?
  bool get _allDone =>
      _p.completedStation >= StationRegistry.stations.last.number;

  int _replayGen = 0;

  void _replay(Station s) {
    if (!_loaded) return;
    setState(() {
      _station = s;
      _replayGen++;
      _step = _Step.replay;
    });
  }

  /// Kol Saati mini oyunu ayrı bir ekranda açılır; dönüşte başlık tazelenir.
  Future<void> _openArmClock() async {
    if (!_loaded) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => const ArmClockScreen(),
    ));
    if (mounted) setState(() {});
  }

  /// Haritadaki durağa dokunuş: sıradaki durak hikâyeyi sürdürür, tamamlanmış
  /// durak yeniden oynanır.
  void _openStation(Station s) {
    if (!_loaded) return;
    if (s.number == _p.currentStation) {
      _start();
    } else {
      _replay(s);
    }
  }

  void _start() {
    if (!_loaded) return;
    Sfx.instance.music(MusicTheme.autumn);
    if (!_p.prologSeen) {
      setState(() => _step = _Step.prolog);
      return;
    }
    _goToNextStation();
  }

  void _goToNextStation() {
    final next = _nextStation();
    if (next == null) {
      Sfx.instance.music(MusicTheme.night);
      setState(() => _step = _Step.end);
      return;
    }
    final resuming = (_p.sceneIndex[next.number] ?? 0) > 0;
    setState(() {
      _station = next;
      _step = resuming ? _Step.station : _Step.travel;
    });
  }

  Future<void> _onPrologDone() async {
    await _store.markPrologSeen();
    _goToNextStation();
  }

  Future<void> _teacherMenu() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => TeacherPanel(
        onJump: (s) => setState(() {
          _station = s;
          _step = _Step.station;
        }),
      ),
    ));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final wagons = 1 + _p.items.length;
    final scarf = _p.items.contains('scarf');

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 700),
        child: switch (_step) {
          _Step.title => _TitleScreen(
              key: const ValueKey('title'),
              ready: _loaded,
              onStart: _start,
              onTeacher: _teacherMenu,
              completed: _p.completedStation,
              next: _nextStation()?.number,
              available: {for (final s in _stations) s.number},
              allUnlocked: _p.teacherUnlockedAll,
              finished: _finished,
              onStation: _openStation,
              onQuickClock: () => _replay(StationRegistry.quickClock()),
              onTimeGates: () => _replay(StationRegistry.timeGates),
              onArmClock: _openArmClock,
            ),
          _Step.prolog => CinematicPlayer(
              key: const ValueKey('prolog'),
              shots: prologShots,
              scenery: Scenery.station,
              season: 0,
              onDone: _onPrologDone,
            ),
          _Step.travel => CinematicPlayer(
              key: ValueKey('travel-${_station!.number}'),
              shots: [
                CinematicShot(
                  line: _station!.travelLine,
                  mood: PamukMood.happy,
                  duration: const Duration(seconds: 5),
                  scenery: Scenery.track,
                  trainMoving: true,
                ),
              ],
              scenery: Scenery.track,
              season: _station!.season,
              wagons: wagons,
              scarf: scarf,
              onDone: () => setState(() => _step = _Step.station),
            ),
          _Step.station => StationPlayer(
              key: ValueKey('station-${_station!.number}'),
              station: _station!,
              onDone: _goToNextStation,
            ),
          _Step.replay => StationPlayer(
              key: ValueKey('replay-${_station!.number}-$_replayGen'),
              station: _station!,
              replay: true,
              onDone: () => setState(() => _step = _Step.title),
            ),
          _Step.end => CinematicPlayer(
              key: const ValueKey('end'),
              shots: _allDone
                  ? finalShots(_p.items)
                  : _finished
                      ? const [
                          CinematicShot(
                            line: Lines.gradeEnd,
                            mood: PamukMood.happy,
                            duration: Duration(seconds: 6),
                          ),
                          CinematicShot(
                            line: Lines.endBye,
                            mood: PamukMood.sleepy,
                            duration: Duration(seconds: 3),
                          ),
                        ]
                      : const [
                      CinematicShot(
                        line: Lines.endSoon,
                        mood: PamukMood.thinking,
                        duration: Duration(seconds: 6),
                        trainMoving: true,
                      ),
                      CinematicShot(
                        line: Lines.endBye,
                        mood: PamukMood.happy,
                        duration: Duration(seconds: 3),
                      ),
                    ],
              scenery: Scenery.den,
              season: 1,
              wagons: wagons,
              scarf: scarf,
              onDone: () => setState(() => _step = _Step.title),
            ),
        },
      ),
    );
  }
}

/// Başlık: Pamuk bankta uyuyor. Dokununca uyanır ve hikâye başlar. Ortada
/// yol haritası: tren tamamlanan durakta, açık duraklar dokunulabilir.
class _TitleScreen extends StatefulWidget {
  final bool ready;
  final VoidCallback onStart;
  final VoidCallback onTeacher;
  final int completed;
  final int? next;
  final Set<int> available;
  final bool allUnlocked;
  final bool finished;
  final ValueChanged<Station> onStation;
  final VoidCallback onQuickClock;
  final VoidCallback onTimeGates;
  final VoidCallback onArmClock;

  const _TitleScreen({
    super.key,
    required this.ready,
    required this.onStart,
    required this.onTeacher,
    required this.completed,
    required this.next,
    required this.available,
    required this.allUnlocked,
    required this.finished,
    required this.onStation,
    required this.onQuickClock,
    required this.onTimeGates,
    required this.onArmClock,
  });

  @override
  State<_TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<_TitleScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final narrow = size.width < 900;
    final short = size.height < 480;
    return SceneryView(
      scenery: Scenery.station,
      season: 0,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              left: 24,
              bottom: 0,
              child: Train(wagons: 1, height: short ? 64 : 120),
            ),
            Positioned(
              left: 40,
              top: short ? 16 : 40,
              child: Text(
                'Yıldız Ekspresi',
                style: (narrow
                        ? Theme.of(context).textTheme.headlineMedium
                        : Theme.of(context).textTheme.displayMedium)
                    ?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF311B92),
                    ),
              ),
            ),
            if (widget.ready)
              Positioned(
                left: 24,
                right: narrow ? 200 : 330,
                top: short ? 70 : 120,
                bottom: short ? 70 : 110,
                child: RouteMap(
                  stations: StationRegistry.stations,
                  completed: widget.completed,
                  next: widget.next,
                  available: widget.available,
                  allUnlocked: widget.allUnlocked,
                  finished: widget.finished,
                  onStation: widget.onStation,
                  onQuickClock: widget.onQuickClock,
                  onTimeGates: widget.onTimeGates,
                  onArmClock: widget.onArmClock,
                ),
              ),
            Positioned(
              right: narrow ? 24 : 60,
              bottom: short ? 30 : 70,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.ready ? widget.onStart : null,
                onLongPress: widget.onTeacher,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: Tween(begin: 0.4, end: 1.0).animate(_pulse),
                      child: const Icon(Icons.touch_app_rounded,
                          size: 56, color: Color(0xFF311B92)),
                    ),
                    Pamuk(mood: PamukMood.sleepy, size: short ? 150 : 240),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
