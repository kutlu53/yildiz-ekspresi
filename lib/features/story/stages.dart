import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../shared/audio/sfx.dart';
import '../../shared/widgets/train_run.dart';
import '../mechanics/mechanic_frame.dart';
import '../mechanics/read_clock.dart';

/// Sahne yerleşimleri: saat küçülür ve dünyanın içine yerleşir, dünyadaki
/// nesne büyür ve doğru cevabın ödülü bir olay olur (tren kalkar, tünele
/// girer). Mekanikler `stage` kancasıyla bunları kullanır; sahneler durak
/// bağımsızdır, duraklar yalnız saat ve metin verir.

/// Kabin: solda panele gömülü saat ve tarife, sağda büyük kalkış kolu, altta
/// bekleyen tren. Saat doğru kurulunca kol "kurulur"; çocuk kolu aşağı
/// çekince düdük çalar ve tren kadrajdan çıkar.
class CabStage extends StatefulWidget {
  final Widget clock;
  final String boardText;
  final bool armed;
  final VoidCallback onPulled;
  final VoidCallback onStuck;
  final VoidCallback onDeparted;

  const CabStage({
    super.key,
    required this.clock,
    required this.boardText,
    required this.armed,
    required this.onPulled,
    required this.onStuck,
    required this.onDeparted,
  });

  @override
  State<CabStage> createState() => _CabStageState();
}

class _CabStageState extends State<CabStage> {
  bool _pulled = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final clockSide = math.min(c.maxHeight * 0.5, c.maxWidth * 0.32);
      return Stack(
        children: [
          Positioned.fill(
            bottom: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 5,
                  child: _Panel(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DigitalBoard(text: widget.boardText, fontSize: 40),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: clockSide,
                          height: clockSide,
                          child: widget.clock,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: BigLever(
                      armed: widget.armed,
                      onPulled: () {
                        setState(() => _pulled = true);
                        widget.onPulled();
                      },
                      onStuck: widget.onStuck,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 110,
            child: TrainRun(
              go: _pulled,
              wagons: 2,
              height: 90,
              from: 0.3,
              to: 1.4,
              onDone: widget.onDeparted,
            ),
          ),
        ],
      );
    });
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF4E342E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF3E2723), width: 6),
        boxShadow: const [
          BoxShadow(blurRadius: 12, color: Colors.black45, offset: Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}

/// Büyük kalkış kolu. `armed` değilken çekilince az kıpırdar, geri gelir ve
/// `onStuck` çağrılır; `armed` ise yeterince çekilince aşağıda kilitlenir,
/// `onPulled` çağrılır.
class BigLever extends StatefulWidget {
  final bool armed;
  final VoidCallback onPulled;
  final VoidCallback onStuck;

  const BigLever({
    super.key,
    required this.armed,
    required this.onPulled,
    required this.onStuck,
  });

  @override
  State<BigLever> createState() => _BigLeverState();
}

class _BigLeverState extends State<BigLever> {
  double _drag = 0;
  bool _pulled = false;
  bool _stuckSaid = false;

  void _update(DragUpdateDetails d) {
    if (_pulled) return;
    setState(() {
      final max = widget.armed ? 1.0 : 0.15;
      _drag = (_drag + d.delta.dy / 140).clamp(0.0, max);
    });
    if (widget.armed && _drag >= 0.6) {
      setState(() {
        _pulled = true;
        _drag = 1;
      });
      Sfx.instance.play(SfxId.gear, volume: 0.6);
      widget.onPulled();
    }
  }

  void _end(DragEndDetails d) {
    if (_pulled) return;
    if (!widget.armed) {
      if (_drag > 0.05 && !_stuckSaid) {
        _stuckSaid = true;
        Sfx.instance.play(SfxId.wrong, volume: 0.4);
        widget.onStuck();
      }
    }
    setState(() => _drag = 0);
  }

  @override
  Widget build(BuildContext context) {
    final glow = widget.armed && !_pulled;
    return GestureDetector(
      key: const ValueKey('big-lever'),
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: _update,
      onVerticalDragEnd: _end,
      child: SizedBox(
        width: 150,
        height: 230,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: 90,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF546E7A),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            AnimatedRotation(
              turns: -0.22 + 0.44 * _drag,
              duration: const Duration(milliseconds: 120),
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      shape: BoxShape.circle,
                      boxShadow: glow
                          ? const [
                              BoxShadow(
                                  color: Color(0xFFFFD54F),
                                  blurRadius: 24,
                                  spreadRadius: 4),
                            ]
                          : const [
                              BoxShadow(
                                  color: Colors.black38,
                                  blurRadius: 6,
                                  offset: Offset(0, 3)),
                            ],
                    ),
                  ),
                  Container(width: 14, height: 150, color: const Color(0xFF263238)),
                ],
              ),
            ),
            if (glow)
              const Positioned(
                top: 0,
                child: Icon(Icons.arrow_downward_rounded,
                    size: 40, color: Color(0xFFFFD54F)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Yük treni manevra yapıyor: her vagonda bir saat yazılı. Solda direkte
/// istasyon saati; çocuk, saatle aynı olan vagona dokunur. Vagonlar ileri
/// geri salınır (hep görünür), seçilen vagon sallanır ya da parlar.
class WagonSigns extends StatefulWidget {
  final Widget clock;
  final List<ReadOption> options;

  const WagonSigns({super.key, required this.clock, required this.options});

  @override
  State<WagonSigns> createState() => _WagonSignsState();
}

class _WagonSignsState extends State<WagonSigns>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          flex: 3,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 200, height: 200, child: widget.clock),
                Container(width: 14, height: 60, color: const Color(0xFF37474F)),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth;
            final wagonW = math.min(150.0, w / 3.6);
            return AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final shunt = math.sin(_c.value * 2 * math.pi) * w * 0.06;
                return SizedBox(
                  height: 160,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: -40,
                        right: -40,
                        bottom: 10,
                        child: Container(height: 6, color: const Color(0xFF546E7A)),
                      ),
                      for (var i = 0; i < widget.options.length; i++)
                        Positioned(
                          left: w * (0.04 + i * 0.32) + shunt + widget.options[i].shakeDx,
                          bottom: 14 + math.sin(_c.value * 2 * math.pi * 3 + i) * 2,
                          child: _Wagon(
                            key: ValueKey('wagon-${widget.options[i].label}'),
                            width: wagonW,
                            label: widget.options[i].label,
                            highlighted: widget.options[i].highlighted,
                            onTap: widget.options[i].onTap,
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}

class _Wagon extends StatelessWidget {
  final double width;
  final String label;
  final bool highlighted;
  final VoidCallback? onTap;

  const _Wagon({
    super.key,
    required this.width,
    required this.label,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: width,
            height: 90,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: highlighted ? const Color(0xFFFFF59D) : const Color(0xFF8D6E63),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: highlighted ? const Color(0xFFFBC02D) : const Color(0xFF4E342E),
                width: 4,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: highlighted ? const Color(0xFF263238) : Colors.white,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var k = 0; k < 2; k++)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: width * 0.16),
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFF263238),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tünel kapısı: solda kulede saat, sağda büyük kapı; doğru kurulunca
/// kanatlar açılır, içeriden ışık dolar ve tren tünele girip kaybolur.
class GateStage extends StatelessWidget {
  final Widget clock;
  final bool open;
  final VoidCallback onEntered;

  const GateStage({
    super.key,
    required this.clock,
    required this.open,
    required this.onEntered,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final clockSide = math.min(c.maxHeight * 0.42, c.maxWidth * 0.28);
      final gateW = math.min(c.maxWidth * 0.34, 300.0);
      return Stack(
        children: [
          Positioned(
            left: 16,
            top: 8,
            child: Column(
              children: [
                SizedBox(width: clockSide, height: clockSide, child: clock),
                Container(
                  width: clockSide * 0.7,
                  height: c.maxHeight - clockSide - 16,
                  color: const Color(0xFF78909C),
                ),
              ],
            ),
          ),
          Positioned(
            right: 24,
            bottom: 0,
            child: _BigGate(open: open, width: gateW, height: c.maxHeight * 0.8),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 110,
            child: TrainRun(
              go: open,
              wagons: 2,
              height: 90,
              from: 0.3,
              to: 0.86,
              fadeOut: true,
              onDone: onEntered,
            ),
          ),
        ],
      );
    });
  }
}

class _BigGate extends StatelessWidget {
  final bool open;
  final double width;
  final double height;

  const _BigGate({required this.open, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final r = Radius.circular(width / 2);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: r),
        color: const Color(0xFF455A64),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFE082).withValues(alpha: open ? 0.9 : 0),
            blurRadius: open ? 40 : 0,
            spreadRadius: open ? 10 : 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: r),
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: open
                      ? const [Color(0xFFFFFDE7), Color(0xFFFFB300)]
                      : const [Color(0xFF37474F), Color(0xFF1A1A2E)],
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 900),
              left: open ? -width / 2 : 0,
              top: 0,
              bottom: 0,
              width: width / 2,
              child: Container(color: const Color(0xFF8D6E63)),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 900),
              right: open ? -width / 2 : 0,
              top: 0,
              bottom: 0,
              width: width / 2,
              child: Container(color: const Color(0xFF8D6E63)),
            ),
          ],
        ),
      ),
    );
  }
}
