import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/body.dart';
import 'package:jangan_bangunin_angsa_app/game/geom.dart';
import 'package:jangan_bangunin_angsa_app/game/tuning.dart';

import 'fixtures.dart';

const t = Tuning();

/// Night 3 built by hand, world edges included, so these tests don't
/// depend on the level parser.
Geometry world() => const Geometry(
  floorY: 270,
  solids: [
    Solid(Box(0, 270, 300, 390), Surface.tile),
    Solid(Box(300, 270, 410, 390), Surface.wood),
    Solid(Box(410, 270, 600, 390), Surface.carpet),
    Solid(Box(600, 270, 844, 390), Surface.wood),
    Solid(Box(-100, -400, 0, 390), Surface.wood),
    Solid(Box(844, -400, 944, 390), Surface.wood),
    Solid(Box(0, -100, 844, 0), Surface.wood),
  ],
  platforms: [
    Platform(id: 'counter', from: 18, to: 280, y: 200, surface: Surface.tile),
    Platform(id: 'crawlPlank', from: 244, to: 426, y: 106, surface: Surface.wood, crawl: true),
    Platform(id: 'shelfLow', from: 316, to: 392, y: 212, surface: Surface.wood),
    Platform(id: 'shelfHigh', from: 316, to: 392, y: 160, surface: Surface.wood),
    Platform(id: 'sideTable', from: 594, to: 634, y: 236, surface: Surface.wood),
    Platform(id: 'hallTable', from: 708, to: 752, y: 236, surface: Surface.wood),
  ],
);

Body at(double x, double y) => Body(world(), Vec(x, y), t);

/// Steps [b] for [seconds] at 60fps; returns the landings and the highest
/// point (smallest y) reached.
({List<Landing> landings, double top}) run(
  Body b,
  double seconds, {
  double move = 0,
  int vertical = 0,
  bool sneak = false,
  bool canClimb = true,
}) {
  final landings = <Landing>[];
  var top = b.feet.y;
  for (var i = 0; i < (seconds * 60).round(); i++) {
    final l = b.step(frame, move: move, vertical: vertical, sneak: sneak, canClimb: canClimb);
    if (l != null) landings.add(l);
    if (b.feet.y < top) top = b.feet.y;
  }
  return (landings: landings, top: top);
}

void main() {
  group('walking and gravity', () {
    test('standing still on the floor stays put', () {
      final b = at(236, 270);
      expect(b.grounded, isTrue);
      run(b, 1);
      expect(b.feet, const Vec(236, 270));
      expect(b.grounded, isTrue);
      expect(b.onFloor, isTrue);
      expect(b.standingOn, isNull);
    });

    test('walks at walk speed, sneaks at sneak speed', () {
      final b = at(236, 270);
      run(b, 1, move: 1);
      expect(b.feet.x, closeTo(236 + t.walkSpeed, 2));
      final s = at(236, 270);
      run(s, 1, move: 1, sneak: true);
      expect(s.feet.x, closeTo(236 + t.sneakSpeed, 2));
      expect(s.facing, 1);
      run(s, 0.1, move: -1);
      expect(s.facing, -1);
    });

    test('the world walls stop him', () {
      final b = at(20, 270);
      run(b, 5, move: -1);
      expect(b.feet.x, t.bodyWidth / 2);
      final r = at(800, 270);
      run(r, 5, move: 1);
      expect(r.feet.x, 844 - t.bodyWidth / 2);
    });
  });

  group('jump', () {
    test('a jump tops out about 84 px up and lands back down', () {
      final b = at(500, 270)..pressJump();
      final r = run(b, 1.5);
      expect(r.top, closeTo(270 - 84, 3));
      expect(b.feet.y, 270);
      expect(b.grounded, isTrue);
      expect(r.landings.single.fall, closeTo(84, 3));
      expect(r.landings.single.surface, Surface.carpet);
    });

    test('a jump under the counter passes up through it and lands on top', () {
      final b = at(150, 270)..pressJump();
      final r = run(b, 1.5);
      expect(r.top, lessThan(200));
      expect(b.standingOn?.id, 'counter');
      expect(b.feet.y, 200);
      expect(r.landings.single.surface, Surface.tile);
    });

    test('walking off the counter falls to the floor', () {
      final b = at(270, 200);
      expect(b.standingOn?.id, 'counter');
      while (b.grounded) {
        b.step(frame, move: 1, vertical: 0, sneak: false);
      }
      final r = run(b, 1);
      expect(b.onFloor, isTrue);
      expect(r.landings.single.fall, closeTo(70, 0.01));
      expect(r.landings.single.surface, Surface.tile);
      expect(r.landings.single.at.y, 270);
    });

    test('coyote time: a jump just after the edge still jumps', () {
      final b = at(270, 200);
      while (b.grounded) {
        b.step(frame, move: 1, vertical: 0, sneak: false);
      }
      run(b, 0.08, move: 1);
      final yAtPress = b.feet.y;
      b.pressJump();
      final r = run(b, 0.3, move: 1);
      expect(r.top, lessThan(yAtPress - 40));
    });

    test('coyote time runs out', () {
      final b = at(270, 200);
      while (b.grounded) {
        b.step(frame, move: 1, vertical: 0, sneak: false);
      }
      run(b, 0.15, move: 1);
      final yAtPress = b.feet.y;
      b.pressJump();
      final r = run(b, 0.3, move: 1);
      expect(r.top, yAtPress);
    });

    /// Frames from a jump on the floor until it lands again.
    int framesToLand() {
      final b = at(500, 270)..pressJump();
      for (var i = 1;; i++) {
        if (b.step(frame, move: 0, vertical: 0, sneak: false) != null) return i;
      }
    }

    test('jump buffer: pressed 0.1s before landing, he jumps again on landing', () {
      final land = framesToLand();
      final b = at(500, 270)..pressJump();
      run(b, (land - 6) / 60);
      b.pressJump();
      run(b, 6 / 60);
      final r = run(b, 0.3);
      expect(r.top, lessThan(240));
    });

    test('jump buffer: pressed 0.2s before landing, it is forgotten', () {
      final land = framesToLand();
      final b = at(500, 270)..pressJump();
      run(b, (land - 12) / 60);
      b.pressJump();
      run(b, 12 / 60);
      final r = run(b, 0.3);
      expect(r.top, 270);
      expect(b.grounded, isTrue);
    });

    test('a long frame does not fall through the counter', () {
      final small = at(150, 190);
      for (var i = 0; i < 20; i++) {
        small.step(0.01, move: 0, vertical: 0, sneak: false);
      }
      final frames = at(150, 190);
      run(frames, 0.2);
      final big = at(150, 190);
      big.step(0.1, move: 0, vertical: 0, sneak: false);
      big.step(0.1, move: 0, vertical: 0, sneak: false);
      for (final b in [small, frames, big]) {
        expect(b.feet.y, 200);
        expect(b.standingOn?.id, 'counter');
      }
    });
  });
}
