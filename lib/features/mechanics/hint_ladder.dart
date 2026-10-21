/// Yardım basamakları: yanlışta önce ilgili el parlar, sonra sayılar, en son
/// Pamuk cevabı gösterir. Ceza yok; her yanlış bir basamak yukarı çıkar.
class HintLadder {
  int _mistakes = 0;

  int get mistakes => _mistakes;

  /// 0: yardım yok, 1: el parlar, 2: sayılar da parlar, 3: cevap gösterilir.
  int get level => _mistakes.clamp(0, 3);

  bool get glowHand => level >= 1;
  bool get glowNumerals => level >= 2;
  bool get showAnswer => level >= 3;

  void fail() => _mistakes++;

  void reset() => _mistakes = 0;
}
