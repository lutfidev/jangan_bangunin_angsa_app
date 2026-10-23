import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/camera.dart';

void main() {
  test('a world no wider than the screen never scrolls', () {
    final c = Camera(worldWidth: 844)..snap(800, 1, floorY: 270);
    expect(c.x, 0);
    c.tick(1, 10, -1, floorY: 270);
    expect(c.x, 0);
  });

  test('a snap centres a little ahead of Milo, inside the house', () {
    final c = Camera(worldWidth: 2000);
    expect((c..snap(236, 1, floorY: 270)).x, 0);
    expect((c..snap(1000, 1, floorY: 270)).x, 1000 + 120 - 422);
    expect((c..snap(1990, 1, floorY: 270)).x, 2000 - 844);
  });

  test('turning round eases the camera over', () {
    final c = Camera(worldWidth: 2000)..snap(1000, 1, floorY: 270);
    c.tick(0.2, 1000, -1, floorY: 270);
    expect(c.x, closeTo(698 - (698 - 458) * (1 - math.exp(-1)), 0.5));
  });

  test('one long tick eases as far as many short ones', () {
    final a = Camera(worldWidth: 2000)..snap(1000, 1, floorY: 270);
    final b = Camera(worldWidth: 2000)..snap(1000, 1, floorY: 270);
    a.tick(0.1, 1000, -1, floorY: 270);
    for (var i = 0; i < 10; i++) {
      b.tick(0.01, 1000, -1, floorY: 270);
    }
    expect(a.x, closeTo(b.x, 0.01));
  });

  test('sees what overlaps the screen', () {
    final c = Camera(worldWidth: 2000)..snap(236, 1, floorY: 270);
    expect(c.sees(690, 830), isTrue);
    expect(c.sees(890, 1030), isFalse);
  });

  test('one storey tall, it never moves up or down', () {
    final c = Camera(worldWidth: 844)..snap(800, 1, floorY: 270);
    expect(c.y, 0);
    c.tick(1, 800, 1, floorY: 660);
    expect(c.y, 0);
  });

  test('it frames his floor line where the screen has its floor', () {
    final c = Camera(worldWidth: 2000, worldHeight: 1170);
    expect((c..snap(236, 1, floorY: 660)).y, 390);
    expect((c..snap(236, 1, floorY: 270)).y, 0);
    expect((c..snap(236, 1, floorY: 1050)).y, 780);
    expect((c..snap(236, 1, floorY: 465)).y, 195);
  });

  test('climbing a storey eases it up', () {
    final c = Camera(worldWidth: 2000, worldHeight: 1170)..snap(1000, 1, floorY: 660);
    c.tick(0.2, 1000, 1, floorY: 270);
    expect(c.y, closeTo(390 * math.exp(-1), 0.5));
  });

  test('sees what overlaps the screen, up and down too', () {
    final c = Camera(worldWidth: 2000, worldHeight: 1170)..snap(236, 1, floorY: 660);
    expect(c.sees(690, 830, top: 500, bottom: 660), isTrue);
    expect(c.sees(690, 830, top: 160, bottom: 270), isFalse);
  });
}
