import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/unlocks.dart';

void main() {
  test('one night of socks opens everything, one at a time', () {
    expect(Unlock.lightSleeper.socks, 1);
    expect(Unlock.kazoo.socks, 2);
    expect(Unlock.mirror.socks, 3);
  });

  test('a threshold opens at its count', () {
    expect(Unlock.kazoo.openWith(1), isFalse);
    expect(Unlock.kazoo.openWith(2), isTrue);
    expect(Unlock.kazoo.openWith(3), isTrue);
  });
}
