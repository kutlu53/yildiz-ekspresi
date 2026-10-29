import 'package:flutter/material.dart';

import '../../shared/audio/sfx.dart';
import '../../shared/audio/speech.dart';
import '../../shared/layout.dart';
import '../../shared/widgets/pamuk.dart';
import '../../shared/widgets/scenery_view.dart';
import '../../shared/widgets/star_burst.dart';
import '../../shared/widgets/train.dart';
import 'models.dart';

/// Kısa sinematikleri oynatır: her çekimde dekor, tren, Pamuk ve bir replik.
/// Düğme yok; ekrana dokunmak bir sonraki çekime geçirir.
class CinematicPlayer extends StatefulWidget {
  final List<CinematicShot> shots;
  final Scenery scenery;
  final double season;
  final int wagons;
  final bool scarf;
  final VoidCallback onDone;

  /// Durak sonu: ilk çekimde büyük konfeti.
  final bool celebrate;

  const CinematicPlayer({
    super.key,
    required this.shots,
    required this.scenery,
    required this.season,
    required this.onDone,
    this.wagons = 1,
    this.scarf = false,
    this.celebrate = false,
  });

  @override
  State<CinematicPlayer> createState() => _CinematicPlayerState();
}

class _CinematicPlayerState extends State<CinematicPlayer> {
  int _index = 0;
  int _generation = 0;
  bool _done = false;
  bool _speaking = false;
  int _confetti = 0;

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    _done = true;
    Sfx.instance.chug(false);
    super.dispose();
  }

  void _cue(CinematicShot shot, CinematicShot? previous) {
    if (shot.trainMoving && !(previous?.trainMoving ?? false)) {
      Sfx.instance.play(SfxId.whistle, volume: 0.8);
      Sfx.instance.play(SfxId.steam, volume: 0.5);
    }
    Sfx.instance.chug(shot.trainMoving);
    if (shot.items.isNotEmpty && (previous?.items.isEmpty ?? true)) {
      Sfx.instance.play(SfxId.item);
    }
    if (shot.credits) Sfx.instance.play(SfxId.cheer);
    if ((widget.celebrate && previous == null) || shot.credits) {
      setState(() => _confetti++);
    }
  }

  Future<void> _run() async {
    final gen = ++_generation;
    for (var i = _index; i < widget.shots.length; i++) {
      if (_done || gen != _generation) return;
      setState(() => _index = i);
      final shot = widget.shots[i];
      _cue(shot, i > 0 ? widget.shots[i - 1] : null);
      final started = DateTime.now();
      if (shot.line != null) {
        setState(() => _speaking = true);
        await Speech.instance.say(shot.line!.text);
        if (_done || gen != _generation) return;
        setState(() => _speaking = false);
      }
      final remaining = shot.duration - DateTime.now().difference(started);
      if (remaining > Duration.zero) {
        await Future<void>.delayed(remaining);
      }
      if (_done || gen != _generation) return;
    }
    _finish();
  }

  void _advance() {
    if (_done) return;
    if (_index + 1 >= widget.shots.length) {
      _finish();
      return;
    }
    Speech.instance.stop();
    setState(() {
      _index++;
      _speaking = false;
    });
    _run();
  }

  void _finish() {
    if (_done) return;
    _done = true;
    Speech.instance.stop();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final shot = widget.shots[_index];
    final mood = _speaking && shot.mood != PamukMood.sleepy
        ? PamukMood.talking
        : shot.mood;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _advance,
      child: SceneryView(
        scenery: shot.scenery ?? widget.scenery,
        season: widget.season,
        moving: shot.trainMoving,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (shot.showTrain)
              Positioned(
                left: 24,
                bottom: 0,
                child: Train(
                  wagons: widget.wagons,
                  moving: shot.trainMoving,
                  height: Layout.compact(context) ? 64 : 130,
                ),
              ),
            if (shot.items.isNotEmpty)
              Positioned(
                left: 24,
                right: 24,
                top: 24,
                child: Center(child: _Shelf(items: shot.items)),
              ),
            if (shot.showPamuk)
              Positioned(
                right: 24,
                bottom: 40,
                child: Pamuk(mood: mood, size: 220, scarf: widget.scarf),
              ),
            if (shot.credits) const Center(child: _Credits()),
            StarBurst(play: _confetti, big: true, silent: true),
            if (shot.line != null)
              Positioned(
                left: 24,
                right: 24,
                bottom: 280,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _Caption(
                        key: ValueKey(shot.line!.id), text: shot.line!.text),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Yuvanın rafı: toplanan eşyalar sırayla belirir.
class _Shelf extends StatelessWidget {
  final List<VagonItem> items;

  const _Shelf({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF5D4037),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 10,
        children: [
          for (var i = 0; i < items.length; i++)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 500 + i * 350),
              curve: Curves.easeOutBack,
              builder: (context, v, child) =>
                  Transform.scale(scale: v, child: child),
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF8E1),
                  shape: BoxShape.circle,
                ),
                child: Icon(items[i].icon, size: 32, color: const Color(0xFF5D4037)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Jenerik: başlık ve kısa teşekkür; metin aynı anda sesle de okunur.
class _Credits extends StatelessWidget {
  const _Credits();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: Color(0xFFFFD54F), size: 48),
          SizedBox(height: 8),
          Text(
            'Yıldız Ekspresi',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Makinist: Sen\nYol arkadaşı: Pamuk',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, color: Colors.white70),
          ),
          SizedBox(height: 12),
          Text(
            'Son',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFFFFD54F),
            ),
          ),
        ],
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  final String text;

  const _Caption({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 560),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Color(0xFF263238),
        ),
      ),
    );
  }
}
