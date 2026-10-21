import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../shared/layout.dart';
import '../../shared/widgets/pamuk.dart';
import '../../shared/widgets/scenery_view.dart';
import 'models.dart';

/// Sahne yerleşimi: durağın dekoru tam ekran, mekanik solda dünyanın içinde,
/// Pamuk sağ altta konuşma balonuyla. Üst çubuk, düğme ya da menü yok.
/// Pamuk'a dokunmak son söyleneni tekrar ettirir.
class SceneScaffold extends StatelessWidget {
  final Scenery scenery;
  final double season;
  final ValueListenable<String?> caption;
  final ValueListenable<PamukMood> mood;

  /// Her artışta Pamuk sallanır (yanlış) ya da zıplar (doğru).
  final ValueListenable<int>? wobble;
  final ValueListenable<int>? jump;
  final bool scarf;
  final VoidCallback onPamukTap;
  final Widget child;

  const SceneScaffold({
    super.key,
    required this.scenery,
    required this.season,
    required this.caption,
    required this.mood,
    required this.onPamukTap,
    required this.child,
    this.wobble,
    this.jump,
    this.scarf = false,
  });

  @override
  Widget build(BuildContext context) {
    final narrow = Layout.narrow(context);
    final compact = Layout.compact(context);
    final sideWidth = compact ? 150.0 : (narrow ? 190.0 : 250.0);
    final pamukSize = compact ? 120.0 : (narrow ? 150.0 : 190.0);
    return SceneryView(
      scenery: scenery,
      season: season,
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0.15, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: child,
              ),
            ),
            SizedBox(
              width: sideWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ValueListenableBuilder<String?>(
                    valueListenable: caption,
                    builder: (context, text, _) => AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: text == null
                          ? const SizedBox(height: 8)
                          : _Bubble(
                              key: ValueKey(text),
                              text: text,
                              compact: compact || narrow,
                            ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onPamukTap,
                    child: PamukReactor(
                      wobble: wobble,
                      jump: jump,
                      child: ValueListenableBuilder<PamukMood>(
                        valueListenable: mood,
                        builder: (context, m, _) =>
                            Pamuk(mood: m, size: pamukSize, scarf: scarf),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pamuk'un bedensel tepkileri: `wobble` artınca sağa sola sallanır,
/// `jump` artınca havaya zıplar. Ruh hâlinden bağımsız, kısa ve abartısız.
class PamukReactor extends StatefulWidget {
  final ValueListenable<int>? wobble;
  final ValueListenable<int>? jump;
  final Widget child;

  const PamukReactor({
    super.key,
    required this.child,
    this.wobble,
    this.jump,
  });

  @override
  State<PamukReactor> createState() => _PamukReactorState();
}

class _PamukReactorState extends State<PamukReactor>
    with TickerProviderStateMixin {
  late final AnimationController _wobble = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final AnimationController _jump = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  @override
  void initState() {
    super.initState();
    widget.wobble?.addListener(_onWobble);
    widget.jump?.addListener(_onJump);
  }

  @override
  void didUpdateWidget(PamukReactor old) {
    super.didUpdateWidget(old);
    if (old.wobble != widget.wobble) {
      old.wobble?.removeListener(_onWobble);
      widget.wobble?.addListener(_onWobble);
    }
    if (old.jump != widget.jump) {
      old.jump?.removeListener(_onJump);
      widget.jump?.addListener(_onJump);
    }
  }

  @override
  void dispose() {
    widget.wobble?.removeListener(_onWobble);
    widget.jump?.removeListener(_onJump);
    _wobble.dispose();
    _jump.dispose();
    super.dispose();
  }

  void _onWobble() => _wobble.forward(from: 0);
  void _onJump() => _jump.forward(from: 0);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_wobble, _jump]),
      builder: (context, child) {
        final w = _wobble.isAnimating
            ? math.sin(_wobble.value * math.pi * 4) * 0.08 * (1 - _wobble.value)
            : 0.0;
        final j = _jump.isAnimating
            ? -math.sin(_jump.value * math.pi) * 36
            : 0.0;
        return Transform.translate(
          offset: Offset(0, j),
          child: Transform.rotate(angle: w, child: child),
        );
      },
      child: widget.child,
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool compact;

  const _Bubble({super.key, required this.text, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: compact ? 14 : 17,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF263238),
        ),
      ),
    );
  }
}
