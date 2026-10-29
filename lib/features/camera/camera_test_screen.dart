import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/angle_mapper.dart';
import '../../core/clock_time.dart';
import '../../shared/widgets/clock_face.dart';
import 'hold_detector.dart';
import 'pose_frame.dart';
import 'pose_overlay_painter.dart';
import 'pose_source.dart';

enum _Status { idle, loading, running, error }

/// Faz 0: kameradan omuz-bilek açısını okuyup kadran üstünde iki çizgi
/// (akrep/yelkovan) gösteren deneme ekranı. Amaç doğruluk ve performansı
/// sınıf cihazlarında ölçmek; oyunlaştırma yok.
class CameraTestScreen extends StatefulWidget {
  const CameraTestScreen({super.key});

  @override
  State<CameraTestScreen> createState() => _CameraTestScreenState();
}

class _CameraTestScreenState extends State<CameraTestScreen> {
  static const _targets = <ClockTime>[
    ClockTime(12, 0),
    ClockTime(3, 0),
    ClockTime(6, 0),
    ClockTime(9, 0),
    ClockTime(1, 30),
    ClockTime(4, 15),
    ClockTime(7, 45),
    ClockTime(10, 5),
  ];

  late final PoseSource _source = createPoseSource();
  StreamSubscription<PoseFrame>? _sub;
  final _stopwatch = Stopwatch()..start();
  final _hold = HoldDetector<ClockTime>();

  _Status _status = _Status.idle;
  String? _error;
  PoseFrame _frame = PoseFrame.empty;
  ClockTime? _read;
  double _holdProgress = 0;
  ClockTime? _target;
  bool _matched = false;
  int _confirmCount = 0;

  int _minuteStep = 30;
  double _tolerance = 15;

  @override
  void initState() {
    super.initState();
    if (_source.isSupported) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  Future<void> _start() async {
    setState(() {
      _status = _Status.loading;
      _error = null;
    });
    try {
      _sub ??= _source.frames.listen(_onFrame);
      await _source.start();
      if (mounted) setState(() => _status = _Status.running);
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = _Status.error;
          _error = _describeError(e);
        });
      }
    }
  }

  String _describeError(Object e) => describeCameraError(e);

  void _onFrame(PoseFrame frame) {
    final hour = frame.hourArm?.angle;
    final minute = frame.minuteArm?.angle;
    ClockTime? read;
    if (hour != null && minute != null) {
      read = AngleMapper.readClock(
        hourAngle: hour,
        minuteAngle: minute,
        minuteStep: _minuteStep,
        minuteTolerance: _tolerance,
        hourTolerance: _tolerance + 5,
      );
    }

    final update = _hold.update(read, _stopwatch.elapsed);
    final matched =
        _target != null && read != null && read.sameOnDial(_target!);
    if (update.justConfirmed && matched) _confirmCount++;

    setState(() {
      _frame = frame;
      _read = read;
      _holdProgress = update.progress;
      _matched = matched && update.progress >= 1;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kamera Testi (Faz 0)'),
      ),
      body: !_source.isSupported
          ? _UnsupportedView(reason: _source.unsupportedReason)
          : Column(
              children: [
                const _PrivacyBanner(),
                Expanded(child: _buildPreviewArea()),
                _buildReadout(),
              ],
            ),
    );
  }

  Widget _buildPreviewArea() {
    return Container(
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
                  target: _target,
                  matched: _matched,
                ),
              ),
            ),
            if (_status == _Status.loading)
              const _Overlay(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Kamera ve model yükleniyor...',
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              ),
            if (_status == _Status.error)
              _Overlay(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_off,
                        color: Colors.white, size: 48),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _error ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _start,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tekrar dene'),
                    ),
                  ],
                ),
              ),
            if (_status == _Status.running && !_frame.hasPose)
              const Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: _Hint(
                    'Üst gövden çerçeveye girsin, 1,5-2 m geri çekil.'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadout() {
    final hour = _frame.hourArm?.angle;
    final minute = _frame.minuteArm?.angle;
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _AngleChip(
                  label: 'Akrep (sol kol)',
                  color: ClockStyle.hourHand,
                  angle: hour,
                ),
                const SizedBox(width: 12),
                _AngleChip(
                  label: 'Yelkovan (sağ kol)',
                  color: ClockStyle.minuteHand,
                  angle: minute,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _read?.digital12 ?? '--:--',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: _matched ? Colors.green.shade700 : null,
                        ),
                      ),
                      Text(
                        '${_frame.fps.toStringAsFixed(0)} kare/sn',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _holdProgress,
                minHeight: 10,
                color: _matched ? Colors.green : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Hedef:'),
                ChoiceChip(
                  label: const Text('Yok'),
                  selected: _target == null,
                  onSelected: (_) => setState(() {
                    _target = null;
                    _hold.reset();
                  }),
                ),
                for (final t in _targets)
                  ChoiceChip(
                    label: Text(t.digital12),
                    selected: _target == t,
                    onSelected: (_) => setState(() {
                      _target = t;
                      _hold.reset();
                    }),
                  ),
                if (_target != null)
                  Text('Doğrulama: $_confirmCount',
                      style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Adım:'),
                const SizedBox(width: 8),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 60, label: Text('Tam')),
                    ButtonSegment(value: 30, label: Text('Yarım')),
                    ButtonSegment(value: 15, label: Text('Çeyrek')),
                    ButtonSegment(value: 5, label: Text('5 dk')),
                  ],
                  selected: {_minuteStep},
                  onSelectionChanged: (s) => setState(() {
                    _minuteStep = s.first;
                    _hold.reset();
                  }),
                ),
                const SizedBox(width: 16),
                Text('Tolerans ±${_tolerance.toStringAsFixed(0)}°'),
                Expanded(
                  child: Slider(
                    value: _tolerance,
                    min: 8,
                    max: 25,
                    divisions: 17,
                    onChanged: (v) => setState(() => _tolerance = v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AngleChip extends StatelessWidget {
  final String label;
  final Color color;
  final double? angle;

  const _AngleChip({
    required this.label,
    required this.color,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12)),
          Text(
            angle == null ? '--' : '${angle!.toStringAsFixed(0)}°',
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyBanner extends StatelessWidget {
  const _PrivacyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.green.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.green.shade800, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Görüntü yalnızca bu cihazda işlenir; kaydedilmez, '
              'internete gönderilmez.',
              style: TextStyle(color: Colors.green.shade900),
            ),
          ),
        ],
      ),
    );
  }
}

class _Overlay extends StatelessWidget {
  final Widget child;

  const _Overlay({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;

  const _Hint(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }
}

class _UnsupportedView extends StatelessWidget {
  final String reason;

  const _UnsupportedView({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, size: 64),
            const SizedBox(height: 16),
            Text(reason,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
