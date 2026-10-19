import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/heist.dart';
import 'package:jangan_bangunin_angsa_app/game/tuning.dart';

void main() {
  test('links within 3s build a combo', () {
    final c = Combo(const Tuning())
      ..link(0)
      ..link(1)
      ..link(3.9);
    expect(c.count, 3);
    expect(c.points, 120 + 240 + 360);
    expect(c.best, 3);
  });

  test('a gap over 3s starts over', () {
    final c = Combo(const Tuning())
      ..link(0)
      ..link(1)
      ..link(4.1);
    expect(c.count, 1);
    expect(c.points, 120);
    expect(c.best, 2);
    expect(c.total, 120 + 240 + 120);
  });

  test('leftAt counts down the window', () {
    expect(Combo(const Tuning()).leftAt(0), 0);
    final c = Combo(const Tuning())..link(2);
    expect(c.leftAt(2.5), 2.5);
    expect(c.leftAt(6), 0);
  });
}
