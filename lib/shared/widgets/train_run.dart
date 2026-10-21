import 'package:flutter/material.dart';

import '../audio/sfx.dart';
import 'train.dart';

/// Sahnede duran tren; `go` açılınca düdük çalar, buhar savurur ve
/// `from` konumundan `to` konumuna (genişlik oranı) gider. `fadeOut` açıkken
/// varış noktasında kaybolur (tünele giriş). Bitince `onDone` çağrılır.
class TrainRun extends StatefulWidget {
  final bool go;
  final int wagons;
  final double height;
  final double from;
  final double to;
  final bool fadeOut;
  final Duration duration;
  final VoidCallback? onDone;

  const TrainRun({
    super.key,
    required this.go,
    this.wagons = 1,
    this.height = 90,
    this.from = 0.05,
    this.to = 1.3,
    this.fadeOut = false,
    this.duration = const Duration(milliseconds: 2600),
    this.onDone,
  });

  @override
  State<TrainRun> createState() => _TrainRunState();
}

class _TrainRunState extends State<TrainRun> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        Sfx.instance.chug(false);
        widget.onDone?.call();
      }
    });

  @override
  void initState() {
    super.initState();
    if (widget.go) _start();
  }

  @override
  void didUpdateWidget(TrainRun old) {
    super.didUpdateWidget(old);
    if (!old.go && widget.go) _start();
  }

  void _start() {
    Sfx.instance.play(SfxId.whistle, volume: 0.8);
    Sfx.instance.play(SfxId.steam, volume: 0.5);
    Sfx.instance.chug(true);
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    Sfx.instance.chug(false);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final trainW = widget.height * (2.2 + widget.wagons * 1.4);
      return AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final f = Curves.easeInCubic.transform(_c.value);
          final x = (widget.from + (widget.to - widget.from) * f) * w - trainW / 2;
          final alpha = widget.fadeOut ? (1 - (f - 0.7).clamp(0, 0.3) / 0.3) : 1.0;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: x,
                bottom: 0,
                child: Opacity(opacity: alpha.clamp(0.0, 1.0), child: child),
              ),
            ],
          );
        },
        child: Train(
          wagons: widget.wagons,
          moving: _c.isAnimating || widget.go,
          height: widget.height,
        ),
      );
    });
  }
}
