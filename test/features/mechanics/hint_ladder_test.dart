import 'package:flutter_test/flutter_test.dart';
import 'package:zaman_bekcisi/features/mechanics/hint_ladder.dart';

void main() {
  test('basamaklar sırayla açılır ve 3\'te durur', () {
    final h = HintLadder();
    expect(h.level, 0);
    expect(h.glowHand, isFalse);
    h.fail();
    expect(h.glowHand, isTrue);
    expect(h.glowNumerals, isFalse);
    h.fail();
    expect(h.glowNumerals, isTrue);
    expect(h.showAnswer, isFalse);
    h.fail();
    h.fail();
    expect(h.level, 3);
    expect(h.showAnswer, isTrue);
    expect(h.mistakes, 4);
    h.reset();
    expect(h.level, 0);
  });
}
