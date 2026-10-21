import 'package:flutter/material.dart';

import '../../shared/layout.dart';
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
    final compact = Layout.compact(context);
    final stage = Padding(
      padding: EdgeInsets.all(compact ? 6 : 12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          body,
          StarBurst(play: celebrate),
        ],
      ),
    );

    // Yatay telefon: tabelalar saatin altına sığmaz, sağına geçer.
    if (compact && footer != null) {
      return Column(
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: header,
            ),
          Expanded(
            child: Row(
              children: [
                Expanded(flex: 5, child: stage),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
                    child: SingleChildScrollView(child: Center(child: footer)),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (header != null)
          Padding(
            padding: EdgeInsets.fromLTRB(16, compact ? 4 : 8, 16, 4),
            child: header,
          ),
        Expanded(child: stage),
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
    final s = Layout.scale(context);
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
              // Dikkat: `alignment` verilmez; verilirse tabela tüm genişliğe yayılır.
              constraints: BoxConstraints(minWidth: 140 * s, minHeight: 76 * s),
              padding: EdgeInsets.symmetric(horizontal: 20 * s, vertical: 12 * s),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: highlighted
                      ? const Color(0xFFFBC02D)
                      : const Color(0xFF4E342E),
                  width: 4,
                ),
              ),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 34 * s,
                    fontWeight: FontWeight.w800,
                    color: highlighted ? const Color(0xFF263238) : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        Container(width: 10, height: 26 * s, color: const Color(0xFF4E342E)),
      ],
    );
  }
}
