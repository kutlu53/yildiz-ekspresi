import 'package:flutter/material.dart';

import '../../core/clock_time.dart';
import '../../core/turkish_time.dart';
import '../../shared/widgets/draggable_clock.dart';
import '../../shared/widgets/scenery_view.dart';
import '../story/lines.dart';
import '../story/models.dart';
import 'mechanic_frame.dart';

/// Say: yelkovan yalnız ileri ve adım adım sürüklenir; her adımda sayı
/// söylenir (isteğe bağlı). Bir tam tur (60 dk) tamamlanınca sahne biter.
/// Durak 1'de gözlem (akrep bir sayı ilerler), Durak 4'te 5'er sayma.
class CountMinutesMechanic extends StatefulWidget {
  final SceneController controller;
  final ClockTime start;
  final int step;
  final bool speakCounts;
  final bool linkHands;
  final ClockFrameStyle frame;
  final Line? intro;
  final Line? done;

  /// Dünyadaki nesne (fener gibi): her adımda `elapsed` dakika ile çizilir.
  final Widget Function(int elapsed, bool finished)? prop;

  const CountMinutesMechanic({
    super.key,
    required this.controller,
    required this.start,
    this.step = 5,
    this.speakCounts = false,
    this.linkHands = true,
    this.frame = ClockFrameStyle.cab,
    this.intro,
    this.done,
    this.prop,
  });

  @override
  State<CountMinutesMechanic> createState() => _CountMinutesMechanicState();
}

class _CountMinutesMechanicState extends State<CountMinutesMechanic> {
  late ClockTime _time = widget.start;
  int _elapsed = 0;
  int _celebrate = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.intro != null) await widget.controller.say(widget.intro!);
    });
  }

  void _onChanged(ClockTime next) {
    if (_finished) return;
    final expected = (_time.minute + widget.step) % 60;
    if (next.minute != expected) return; // yalnız bir adım ileri kabul edilir
    setState(() {
      _time = next;
      _elapsed += widget.step;
    });
    if (widget.speakCounts) {
      widget.controller.sayText(TurkishTime.number(_elapsed));
    }
    if (_elapsed >= 60) _finish();
  }

  Future<void> _finish() async {
    setState(() {
      _finished = true;
      _celebrate++;
    });
    await widget.controller.say(widget.done ?? Lines.great);
    if (mounted) widget.controller.complete();
  }

  @override
  Widget build(BuildContext context) {
    return MechanicFrame(
      celebrate: _celebrate,
      header: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.prop != null) ...[
            widget.prop!(_elapsed, _finished),
            const SizedBox(width: 16),
          ],
          Flexible(child: _Progress(elapsed: _elapsed, step: widget.step)),
        ],
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: ClockFrame(
            style: widget.frame,
            child: DraggableClock(
              time: _time,
              draggable: _finished ? const {} : const {ClockHand.minute},
              minuteStep: widget.step,
              linkHands: widget.linkHands,
              // Sayım bitince akrep parlar: bir saatte bir sayı ilerlediği
              // ancak böyle fark ediliyor (pilot: "akrep hareket etmiyor").
              glowHands: _finished
                  ? const {ClockHand.hour}
                  : (_elapsed == 0 ? const {ClockHand.minute} : const {}),
              onChanged: _onChanged,
            ),
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  final int elapsed;
  final int step;

  const _Progress({required this.elapsed, required this.step});

  @override
  Widget build(BuildContext context) {
    final total = 60 ~/ step;
    final done = elapsed ~/ step;
    return Wrap(
      spacing: 6,
      children: [
        for (var i = 0; i < total; i++)
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < done ? const Color(0xFFFFB300) : Colors.white54,
              border: Border.all(color: const Color(0xFF546E7A)),
            ),
          ),
      ],
    );
  }
}
