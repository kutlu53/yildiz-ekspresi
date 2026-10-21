import 'package:flutter/material.dart';

import '../../shared/widgets/star_burst.dart';

/// Mekaniklerin ortak yerleşimi: üstte dünyadaki nesne (pano, kol, kapı),
/// ortada saat, altta varsa tabelalar. Onay düğmesi yok; etkileşimin kendisi
/// (eli bırakmak, tabelaya dokunmak) sonucu verir.
class MechanicFrame extends StatelessWidget {
  final Widget? header;
  final Widget body;
  final Widget? footer;
  final int celebrate;

  const MechanicFrame({
    super.key,
    this.header,
    required this.body,
    this.footer,
    this.celebrate = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: header,
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                body,
                StarBurst(play: celebrate),
              ],
            ),
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: footer,
          ),
      ],
    );
  }
}

/// Tarife panosu / dijital saat gösterimi.
class DigitalBoard extends StatelessWidget {
  final String text;
  final double fontSize;

  const DigitalBoard({super.key, required this.text, this.fontSize = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF263238),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB300), width: 3),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: const Color(0xFFFFEB3B),
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Ahşap tabela: okuma seçenekleri dünyadaki nesne olarak görünür.
class WoodenSign extends StatelessWidget {
  final String text;
  final bool highlighted;
  final VoidCallback? onTap;

  const WoodenSign({
    super.key,
    required this.text,
    this.highlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: highlighted ? const Color(0xFFFFF59D) : const Color(0xFF8D6E63),
          elevation: 4,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              constraints: const BoxConstraints(minWidth: 140, minHeight: 76),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: highlighted
                      ? const Color(0xFFFBC02D)
                      : const Color(0xFF4E342E),
                  width: 4,
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: highlighted ? const Color(0xFF263238) : Colors.white,
                ),
              ),
            ),
          ),
        ),
        Container(width: 10, height: 26, color: const Color(0xFF4E342E)),
      ],
    );
  }
}
