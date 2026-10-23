import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/camera.dart';

void main() {
  test('a world no wider than the screen never scrolls', () {
    final c = Camera(worldWidth: 844)..snap(800, 1);
    expect(c.x, 0);
    c.tick(1, 10, -1);
    expect(c.x, 0);
  });

  test('a snap centres a little ahead of Milo, inside the house', () {
    final c = Camera(worldWidth: 2000);
    expect((c..snap(236, 1)).x, 0);
    expect((c..snap(1000, 1)).x, 1000 + 120 - 422);
    expect((c..snap(1990, 1)).x, 2000 - 844);
  });

  test('turning round eases the camera over', () {
    final c = Camera(worldWidth: 2000)..snap(1000, 1);
    c.tick(0.2, 1000, -1);
    expect(c.x, closeTo(698 - (698 - 458) * (1 - math.exp(-1)), 0.5));
  });

  test('one long tick eases as far as many short ones', () {
    final a = Camera(worldWidth: 2000)..snap(1000, 1);
    final b = Camera(worldWidth: 2000)..snap(1000, 1);
    a.tick(0.1, 1000, -1);
    for (var i = 0; i < 10; i++) {
      b.tick(0.01, 1000, -1);
    }
    expect(a.x, closeTo(b.x, 0.01));
  });

  test('sees what overlaps the screen', () {
    final c = Camera(worldWidth: 2000)..snap(236, 1);
    expect(c.sees(690, 830), isTrue);
    expect(c.sees(890, 1030), isFalse);
  });
}
