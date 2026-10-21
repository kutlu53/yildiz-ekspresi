import 'package:flutter/widgets.dart';

/// Ekran sınıfları. Tasarım yatay ekran içindir (tahta, tablet, yatay
/// telefon). Telefon yatayda yükseklik az olduğu için "sıkışık" düzen:
/// Pamuk sütunu daralır, tabelalar saatin yanına geçer, nesneler küçülür.
class Layout {
  Layout._();

  /// Yükseklik 480 pikselin altında: yatay telefon.
  static bool compact(BuildContext context) =>
      MediaQuery.sizeOf(context).height < 480;

  /// Genişlik 900 pikselin altında: dar yatay ekran (telefon, küçük tablet).
  static bool narrow(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 900;

  /// Dikey ve dar: telefon dikey tutuluyor; oyun bu yönde oynanmaz.
  static bool phonePortrait(Size size) =>
      size.width < size.height && size.width < 600;

  /// Sıkışık düzende ölçek katsayısı.
  static double scale(BuildContext context) => compact(context) ? 0.72 : 1;
}
