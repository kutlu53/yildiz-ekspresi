import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../shared/audio/sfx.dart';
import '../../shared/layout.dart';
import '../story/lines.dart';
import '../story/models.dart';
import 'hint_ladder.dart';
import 'mechanic_frame.dart';

/// Yerleştirilecek kart: etkinlik, gün, ay gibi.
class PlaceCard {
  final String id;
  final String label;
  final IconData icon;

  /// Kartın ait olduğu yuva.
  final String slotId;

  const PlaceCard({
    required this.id,
    required this.label,
    required this.icon,
    required this.slotId,
  });
}

/// Kartın bırakılacağı yuva: saat dilimi, sıra, vagon.
class PlaceSlot {
  final String id;

  /// Yuvanın sesli adı: "sabah yedi", "Pazartesi", "ilkbahar".
  final String spoken;

  /// Yuvanın dünyadaki görünümü (küçük saat, pencere, taş).
  final Widget Function(BuildContext context, bool filled, bool glow) build;

  /// Kaç kart alır (mevsim vagonu üç ay alır).
  final int capacity;

  const PlaceSlot({
    required this.id,
    required this.spoken,
    required this.build,
    this.capacity = 1,
  });
}

/// Sırala / Eşleştir (kart biçimi): dağınık kartlar dünyadaki yuvalara
/// sürüklenir. Doğru yuva kartı kabul eder ve sesle okur; yanlış yuva kartı
/// geri gönderir, Pamuk olayı söyler (gece yarısı kahvaltı?), yardım
/// merdiveni doğru yuvayı parlatır. Tüm kartlar yerleşince sahne biter.
class PlaceCardsMechanic extends StatefulWidget {
  final SceneController controller;
  final List<PlaceCard> cards;
  final List<PlaceSlot> slots;
  final Line? intro;
  final Line? wrongLine;
  final Line? done;
  final int shuffleSeed;

  /// Dünyadaki nesne: son doğru yerleştirilen yuva ile çizilir.
  final Widget Function(PlaceSlot? lastFilled)? prop;

  const PlaceCardsMechanic({
    super.key,
    required this.controller,
    required this.cards,
    required this.slots,
    this.intro,
    this.wrongLine,
    this.done,
    this.shuffleSeed = 0,
    this.prop,
  });

  @override
  State<PlaceCardsMechanic> createState() => _PlaceCardsMechanicState();
}

class _PlaceCardsMechanicState extends State<PlaceCardsMechanic> {
  final _ladder = HintLadder();
  late final List<PlaceCard> _pending = List.of(widget.cards)
    ..shuffle(math.Random(widget.shuffleSeed));
  final Map<String, List<PlaceCard>> _placed = {};
  PlaceSlot? _lastFilled;
  PlaceCard? _lastWrong;
  int _celebrate = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.intro != null) await widget.controller.say(widget.intro!);
    });
  }

  bool _accepts(PlaceSlot slot) =>
      (_placed[slot.id]?.length ?? 0) < slot.capacity;

  Future<void> _drop(PlaceSlot slot, PlaceCard card) async {
    if (_busy || !_accepts(slot)) return;
    setState(() => _busy = true);
    if (card.slotId == slot.id) {
      Sfx.instance.play(SfxId.pop);
      setState(() {
        _pending.remove(card);
        _placed.putIfAbsent(slot.id, () => []).add(card);
        _lastFilled = slot;
        _lastWrong = null;
        _ladder.reset();
        _celebrate++;
      });
      await widget.controller.sayText('${slot.spoken}: ${card.label}');
      if (!mounted) return;
      if (_pending.isEmpty) {
        await widget.controller.say(widget.done ?? Lines.great);
        if (mounted) widget.controller.complete();
        return;
      }
    } else {
      widget.controller.mistake();
      setState(() {
        _ladder.fail();
        _lastWrong = card;
      });
      await widget.controller
          .sayText('${slot.spoken}, ${card.label.toLowerCase()}?');
      if (!mounted) return;
      switch (_ladder.level) {
        case 1:
          await widget.controller.say(widget.wrongLine ?? Lines.notYet);
        case 2:
          await widget.controller.say(Lines.tryAgain);
        default:
          await widget.controller.say(Lines.showYou);
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final glowSlot = _ladder.level >= 2 && _lastWrong != null
        ? _lastWrong!.slotId
        : null;

    return MechanicFrame(
      celebrate: _celebrate,
      header: widget.prop?.call(_lastFilled),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final slot in widget.slots)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: DragTarget<PlaceCard>(
                  onWillAcceptWithDetails: (_) => _accepts(slot) && !_busy,
                  onAcceptWithDetails: (d) => _drop(slot, d.data),
                  builder: (context, candidates, _) {
                    final filled = (_placed[slot.id]?.length ?? 0) > 0;
                    final hover = candidates.isNotEmpty;
                    return Column(
                      children: [
                        slot.build(context, filled, glowSlot == slot.id),
                        const SizedBox(height: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          constraints: const BoxConstraints(minHeight: 84),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: hover
                                ? const Color(0xFFFFF59D)
                                : Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: glowSlot == slot.id
                                  ? const Color(0xFFFFD54F)
                                  : const Color(0xFF546E7A),
                              width: glowSlot == slot.id ? 4 : 2,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final c in _placed[slot.id] ?? const [])
                                CardTile(card: c, placed: true),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      footer: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          for (final c in _pending)
            Draggable<PlaceCard>(
              data: c,
              feedback: Material(
                color: Colors.transparent,
                child: CardTile(card: c, lifted: true),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: CardTile(card: c),
              ),
              onDragStarted: () {
                Sfx.instance.play(SfxId.tick, volume: 0.5);
                widget.controller.sayText(c.label);
              },
              child: CardTile(
                card: c,
                glow: _ladder.showAnswer && _lastWrong == c,
              ),
            ),
        ],
      ),
    );
  }
}

/// Kart görünümü: simge ve kısa etiket (etiket sesle de okunur).
class CardTile extends StatelessWidget {
  final PlaceCard card;
  final bool placed;
  final bool lifted;
  final bool glow;

  const CardTile({
    super.key,
    required this.card,
    this.placed = false,
    this.lifted = false,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = Layout.scale(context);
    return Container(
      width: 104 * s,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: placed ? const Color(0xFFC8E6C9) : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: glow ? const Color(0xFFFFD54F) : const Color(0xFF8D6E63),
          width: glow ? 4 : 3,
        ),
        boxShadow: lifted
            ? const [BoxShadow(blurRadius: 12, color: Colors.black45)]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(card.icon, size: 34 * s, color: const Color(0xFF5D4037)),
          const SizedBox(height: 2),
          Text(
            card.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15 * s,
              fontWeight: FontWeight.w700,
              color: Color(0xFF263238),
            ),
          ),
        ],
      ),
    );
  }
}
