import 'package:flutter/material.dart';

import '../../features/story/lines.dart';
import '../../features/story/models.dart';
import '../audio/speech.dart';
import '../layout.dart';
import 'pamuk.dart';

/// Telefon dikey tutulunca oyun yerine "telefonu yan çevir" sahnesi: Pamuk
/// ve dönen bir telefon simgesi, replik sesle okunur. Tabletlerde dikey
/// kullanım serbesttir. Menü ve düğme yok; çevirince oyun kendiliğinden gelir.
class OrientationGuard extends StatefulWidget {
  final Widget child;

  const OrientationGuard({super.key, required this.child});

  @override
  State<OrientationGuard> createState() => _OrientationGuardState();
}

class _OrientationGuardState extends State<OrientationGuard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();
  bool _said = false;

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (!Layout.phonePortrait(size)) {
      _said = false;
      return widget.child;
    }
    if (!_said) {
      _said = true;
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => Speech.instance.say(Lines.rotatePhone.text));
    }
    return Material(
      color: const Color(0xFF311B92),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _spin,
              builder: (context, child) => Transform.rotate(
                angle: Curves.easeInOut.transform(_spin.value) * 1.5708,
                child: child,
              ),
              child: const Icon(Icons.phone_android,
                  size: 120, color: Color(0xFFFFD54F)),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                Lines.rotatePhone.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Pamuk(mood: PamukMood.thinking, size: 160),
          ],
        ),
      ),
    );
  }
}
