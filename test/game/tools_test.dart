import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/tools.dart';

void main() {
  test('a flight lands after its duration', () {
    final f = Flight(fromX: 0, fromY: 212, toX: 100, duration: 0.5);
    f.advance(0.25);
    expect(f.progress, 0.5);
    expect(f.landed, isFalse);
    f.advance(0.3);
    expect(f.progress, 1);
    expect(f.landed, isTrue);
  });

  test('the mouse walks and stops at the wall', () {
    final m = ToyMouse(x: 800, dir: 1);
    expect(m.advance(1, 70, min: 0, max: 844), (800.0, 844.0));
    expect(m.x, 844);
    expect(m.stopped, isTrue);
    expect(m.advance(1, 70, min: 0, max: 844), (844.0, 844.0));
  });

  test('the mouse walks left too', () {
    final m = ToyMouse(x: 100, dir: -1);
    expect(m.advance(0.5, 70, min: 0, max: 844), (100.0, 65.0));
    expect(m.stopped, isFalse);
  });

  test('a stopped mouse stays put', () {
    final m = ToyMouse(x: 100, dir: 1)..stop();
    m.advance(1, 70, min: 0, max: 844);
    expect(m.x, 100);
  });
}
