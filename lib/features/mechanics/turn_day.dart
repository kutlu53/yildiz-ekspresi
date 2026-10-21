import 'package:flutter/material.dart';

import '../../core/clock_time.dart';
import '../../core/turkish_time.dart';
import '../../shared/widgets/draggable_clock.dart';
import '../../shared/widgets/scenery_view.dart';
import '../story/lines.dart';
import '../story/models.dart';
import 'mechanic_frame.dart';

/// Gün Turu (Say'ın saat biçimi): çocuk akrebi sayıdan sayıya sürükler, her
/// adımda bir saat geçer ve dünyadaki nesne (pencere) o saate göre değişir.
/// Akrep iki tam tur atınca (24 saat) sahne biter. Yalnız bir adım ileri
/// kabul edilir; sıçrama ve geri gitme yok sayılır.
class TurnDayMechanic extends StatefulWidget {
  final SceneController controller;

  /// Başlangıç saati (0-23). Sayaç buradan 24 adım ilerler.
  final int startHour;
  final bool speakCounts;
  final ClockFrameStyle frame;
  final Line? intro;
  final Line? done;

  /// Belirli adımlarda okunacak replikler (ör. 12. saatte "öğlen oldu").
  final Map<int, Line> milestones;

  /// Dünyadaki nesne: o anki saat (startHour + geçen saat) ile çizilir.
  final Widget Function(int hour, int elapsed)? prop;

  const TurnDayMechanic({
    super.key,
    required this.controller,
    this.startHour = 6,
    this.speakCounts = true,
    this.frame = ClockFrameStyle.cab,
    this.intro,
    this.done,
    this.milestones = const {},
    this.prop,
  });

  @override
  State<TurnDayMechanic> createState() => _TurnDayMechanicState();
}

class _TurnDayMechanicState extends State<TurnDayMechanic> {
  int _elapsed = 0;
  int _celebrate = 0;
  bool _finished = false;

  int get _hour => (widget.startHour + _elapsed) % 24;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.intro != null) await widget.controller.say(widget.intro!);
    });
  }

  void _onChanged(ClockTime next) {
    if (_finished) return;
    if (next.hour % 12 != (_hour + 1) % 12) return;
    setState(() => _elapsed++);
    final milestone = widget.milestones[_elapsed];
    if (milestone != null) {
      widget.controller.say(milestone);
    } else if (widget.speakCounts) {
      widget.controller.sayText(TurkishTime.number(_elapsed));
    }
    if (_elapsed >= 24) _finish();
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
            widget.prop!(_hour, _elapsed),
            const SizedBox(width: 16),
          ],
          Flexible(child: _HourDots(elapsed: _elapsed)),
        ],
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: ClockFrame(
            style: widget.frame,
            child: DraggableClock(
              time: ClockTime(_hour, 0),
              draggable: _finished ? const {} : const {ClockHand.hour},
              glowHands: _elapsed == 0 ? const {ClockHand.hour} : const {},
              onChanged: _onChanged,
            ),
          ),
        ),
      ),
    );
  }
}

/// 24 nokta, iki sıra: her sıra akrebin bir turu.
class _HourDots extends StatelessWidget {
  final int elapsed;

  const _HourDots({required this.elapsed});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < 2; row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Wrap(
              spacing: 4,
              children: [
                for (var i = row * 12; i < row * 12 + 12; i++)
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < elapsed
                          ? (row == 0
                              ? const Color(0xFFFFB300)
                              : const Color(0xFF5C6BC0))
                          : Colors.white54,
                      border: Border.all(color: const Color(0xFF546E7A)),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
