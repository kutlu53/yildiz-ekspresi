import 'package:flutter/material.dart';

import '../../core/clock_time.dart';
import '../../shared/widgets/clock_face.dart';
import '../../shared/widgets/draggable_clock.dart';
import '../../shared/widgets/scenery_view.dart';
import '../story/lines.dart';
import '../story/models.dart';
import 'mechanic_frame.dart';

/// Elleri Tak: yerde duran kısa kırmızı ve uzun mavi eller kadranın
/// merkezine sürüklenir. Önce akrep istenir; yelkovan önce bırakılırsa
/// geri sıçrar ve Pamuk açıklar.
class AttachHandsMechanic extends StatefulWidget {
  final SceneController controller;
  final ClockTime time;
  final ClockFrameStyle frame;

  const AttachHandsMechanic({
    super.key,
    required this.controller,
    this.time = const ClockTime(3, 0),
    this.frame = ClockFrameStyle.cab,
  });

  @override
  State<AttachHandsMechanic> createState() => _AttachHandsMechanicState();
}

class _AttachHandsMechanicState extends State<AttachHandsMechanic> {
  final Set<ClockHand> _attached = {};
  int _celebrate = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.controller.say(Lines.s1AttachFirst);
    });
  }

  ClockHand get _expected =>
      _attached.contains(ClockHand.hour) ? ClockHand.minute : ClockHand.hour;

  Future<void> _drop(ClockHand hand) async {
    if (_busy || _attached.contains(hand)) return;
    setState(() => _busy = true);
    if (hand != _expected) {
      widget.controller.mistake();
      await widget.controller.say(Lines.s1WrongFirst);
      if (mounted) setState(() => _busy = false);
      return;
    }
    setState(() {
      _attached.add(hand);
      _celebrate++;
    });
    if (hand == ClockHand.hour) {
      await widget.controller.say(Lines.s1AttachHourDone);
      if (mounted) setState(() => _busy = false);
    } else {
      await widget.controller.say(Lines.s1AttachMinuteDone);
      if (mounted) widget.controller.complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MechanicFrame(
      celebrate: _celebrate,
      body: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: ClockFrame(
            style: widget.frame,
            child: DragTarget<ClockHand>(
              onWillAcceptWithDetails: (_) => true,
              onAcceptWithDetails: (d) => _drop(d.data),
              builder: (context, candidates, _) => DraggableClock(
                time: widget.time,
                draggable: const {},
                visibleHands: _attached,
                glowNumerals: candidates.isNotEmpty,
              ),
            ),
          ),
        ),
      ),
      footer: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        spacing: 16,
        runSpacing: 8,
        children: [
          _HandPiece(
            hand: ClockHand.hour,
            attached: _attached.contains(ClockHand.hour),
            highlight: _expected == ClockHand.hour,
          ),
          _HandPiece(
            hand: ClockHand.minute,
            attached: _attached.contains(ClockHand.minute),
            highlight: _expected == ClockHand.minute &&
                _attached.contains(ClockHand.hour),
          ),
        ],
      ),
    );
  }
}

class _HandPiece extends StatelessWidget {
  final ClockHand hand;
  final bool attached;
  final bool highlight;

  const _HandPiece({
    required this.hand,
    required this.attached,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final isHour = hand == ClockHand.hour;
    final piece = CustomPaint(
      size: Size(isHour ? 90 : 140, 36),
      painter: _PiecePainter(isHour: isHour),
    );
    if (attached) {
      return Opacity(opacity: 0.15, child: piece);
    }
    return Draggable<ClockHand>(
      data: hand,
      feedback: piece,
      childWhenDragging: Opacity(opacity: 0.3, child: piece),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: highlight ? ClockStyle.glow.withValues(alpha: 0.5) : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: piece,
      ),
    );
  }
}

class _PiecePainter extends CustomPainter {
  final bool isHour;

  _PiecePainter({required this.isHour});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isHour ? ClockStyle.hourHand : ClockStyle.minuteHand
      ..strokeWidth = isHour ? 16 : 10
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    canvas.drawLine(Offset(8, y), Offset(size.width - 8, y), paint);
  }

  @override
  bool shouldRepaint(_PiecePainter old) => old.isHour != isHour;
}
