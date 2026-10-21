import 'package:flutter/material.dart';

import '../../shared/audio/sfx.dart';
import '../../shared/widgets/steam_puffs.dart';

/// Kalkış kolu: hedef saat kurulunca iner.
class LeverProp extends StatelessWidget {
  final bool down;

  const LeverProp({super.key, required this.down});

  @override
  Widget build(BuildContext context) {
    return Cue(trigger: down, id: SfxId.whistle, when: down, child: _build());
  }

  Widget _build() {
    return SizedBox(
      width: 60,
      height: 70,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(top: -40, child: SteamPuffs(active: down, size: 70)),
          Container(
            width: 44,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFF546E7A),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          AnimatedRotation(
            turns: down ? 0.18 : -0.18,
            duration: const Duration(milliseconds: 500),
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(width: 6, height: 44, color: const Color(0xFF263238)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tünel kapısı: açılınca iki kanat yana kayar.
class GateProp extends StatelessWidget {
  final bool open;

  const GateProp({super.key, required this.open});

  @override
  Widget build(BuildContext context) {
    return Cue(trigger: open, id: SfxId.gear, when: open, child: _build());
  }

  Widget _build() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 700),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFE082).withValues(alpha: open ? 0.9 : 0),
            blurRadius: open ? 28 : 0,
            spreadRadius: open ? 6 : 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        child: SizedBox(
          width: 90,
          height: 70,
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 700),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: open
                        ? const [Color(0xFFFFFDE7), Color(0xFFFFB300)]
                        : const [Color(0xFF37474F), Color(0xFF263238)],
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 700),
                left: open ? -45 : 0,
                top: 0,
                bottom: 0,
                width: 45,
                child: Container(color: const Color(0xFF8D6E63)),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 700),
                right: open ? -45 : 0,
                top: 0,
                bottom: 0,
                width: 45,
                child: Container(color: const Color(0xFF8D6E63)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Köprü: inince yatay olur.
class BridgeProp extends StatelessWidget {
  final bool down;

  const BridgeProp({super.key, required this.down});

  @override
  Widget build(BuildContext context) {
    return Cue(trigger: down, id: SfxId.gear, when: down, child: _build());
  }

  Widget _build() {
    return SizedBox(
      width: 100,
      height: 70,
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Container(width: 100, height: 10, color: const Color(0xFF4FC3F7)),
          AnimatedRotation(
            turns: down ? 0 : -0.2,
            duration: const Duration(milliseconds: 800),
            alignment: Alignment.bottomLeft,
            child: Container(
              width: 100,
              height: 14,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF8D6E63),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tünel feneri: `level` 0-1 arası parlaklık; `lit` sönükse alev yok.
/// Durak 4'te her beş dakikada biraz daha parlar, 60'ta tam parlak.
class LanternProp extends StatelessWidget {
  final bool lit;
  final double level;

  const LanternProp({super.key, required this.lit, this.level = 1});

  @override
  Widget build(BuildContext context) {
    return Cue(trigger: lit, id: SfxId.chime, when: lit, child: _build());
  }

  Widget _build() {
    final glow = lit ? (0.25 + 0.75 * level.clamp(0.0, 1.0)) : 0.0;
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 90 * glow,
            height: 90 * glow,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFB300).withValues(alpha: 0.25),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 20, height: 6, color: const Color(0xFF37474F)),
              Container(
                width: 36,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF37474F),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 24,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      const Color(0xFF263238),
                      const Color(0xFFFFE082),
                      glow,
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  alignment: Alignment.center,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: lit ? 1 : 0,
                    child: Container(
                      width: 10,
                      height: 12 + 12 * level.clamp(0.0, 1.0),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF8F00),
                        borderRadius: BorderRadius.all(
                          Radius.elliptical(5, 10),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Damla saati: her dakika bir damla; `drops` kadar damla kapta birikir.
class DripClockProp extends StatelessWidget {
  final int drops;
  final bool done;

  const DripClockProp({super.key, required this.drops, this.done = false});

  @override
  Widget build(BuildContext context) {
    return Cue(
      trigger: drops,
      id: SfxId.drop,
      when: drops > 0,
      volume: 0.7,
      child: _build(),
    );
  }

  Widget _build() {
    final shown = drops.clamp(0, 10);
    final fill = shown / 10;
    return SizedBox(
      width: 120,
      height: 90,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFF78909C),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
              ),
              const Icon(Icons.water_drop, size: 18, color: Color(0xFF4FC3F7)),
              Container(
                width: 46,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF455A64),
                  border: Border.all(
                    color: done
                        ? const Color(0xFFFFB300)
                        : const Color(0xFF78909C),
                    width: 3,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(10),
                  ),
                ),
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 40,
                  height: 34 * fill,
                  color: const Color(0xFF4FC3F7),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 60,
            child: Wrap(
              spacing: 2,
              runSpacing: 2,
              children: [
                for (var i = 0; i < shown; i++)
                  const Icon(
                    Icons.water_drop,
                    size: 14,
                    color: Color(0xFF4FC3F7),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vagon kapısı: doğru kurulunca kapı yana kayar, içeride ışık görünür.
class DoorProp extends StatelessWidget {
  final bool open;

  const DoorProp({super.key, required this.open});

  @override
  Widget build(BuildContext context) {
    return Cue(trigger: open, id: SfxId.pop, when: open, child: _build());
  }

  Widget _build() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 70,
        height: 80,
        child: Stack(
          children: [
            Container(color: const Color(0xFFFFF59D)),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              left: open ? -62 : 0,
              top: 0,
              bottom: 0,
              width: 70,
              child: Container(
                color: const Color(0xFF2E7D32),
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  width: 36,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB3E5FC),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bilet: üzerinde dijital saat yazan küçük kart.
class TicketProp extends StatelessWidget {
  final String text;

  const TicketProp({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB8860B), width: 3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.train, color: Color(0xFF5D4037), size: 30),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: Color(0xFF263238),
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarife panosu: birkaç tren satırı; seçili satır parlar, çevrilince
/// onay işareti alır.
class TimetableProp extends StatelessWidget {
  final List<String> rows;
  final int highlighted;
  final bool done;

  const TimetableProp({
    super.key,
    required this.rows,
    required this.highlighted,
    this.done = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF263238),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB300), width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 3),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: i == highlighted
                    ? const Color(0xFFFFEB3B)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    i < highlighted || (i == highlighted && done)
                        ? Icons.check_circle
                        : Icons.train,
                    color: i == highlighted
                        ? const Color(0xFF263238)
                        : const Color(0xFFFFEB3B),
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    rows[i],
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: i == highlighted
                          ? const Color(0xFF263238)
                          : const Color(0xFFFFEB3B),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Büyük saat kilidi: beş dişli, dönen dişliler altın olur; kapı dişli
/// sayısı kadar aralanır. `turning` açıkken sıradaki dişli de döner.
class LockProp extends StatelessWidget {
  final int gears;
  final int total;
  final bool turning;

  const LockProp({
    super.key,
    required this.gears,
    this.total = 5,
    this.turning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Cue(
      trigger: turning,
      id: SfxId.gear,
      when: turning,
      child: _build(),
    );
  }

  Widget _build() {
    final open = (gears + (turning ? 1 : 0)) / total;
    return SizedBox(
      width: 260,
      height: 84,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Kapı: iki kanat aralanır
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: SizedBox(
              width: 70,
              height: 84,
              child: Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Color.lerp(
                            const Color(0xFFFFE082),
                            const Color(0xFFFFFDE7),
                            open,
                          )!,
                          const Color(0xFFFFB300),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFFFE082,
                          ).withValues(alpha: 0.8 * open),
                          blurRadius: 24 * open,
                          spreadRadius: 4 * open,
                        ),
                      ],
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 600),
                    left: -35 * open,
                    top: 0,
                    bottom: 0,
                    width: 35,
                    child: Container(color: const Color(0xFF6D4C41)),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 600),
                    right: -35 * open,
                    top: 0,
                    bottom: 0,
                    width: 35,
                    child: Container(color: const Color(0xFF6D4C41)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          for (var i = 0; i < total; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedRotation(
                turns: i < gears ? 1 : (turning && i == gears ? 0.5 : 0),
                duration: const Duration(milliseconds: 900),
                child: Icon(
                  Icons.settings,
                  size: 28,
                  color: i < gears || (turning && i == gears)
                      ? const Color(0xFFFFB300)
                      : const Color(0xFF78909C),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
