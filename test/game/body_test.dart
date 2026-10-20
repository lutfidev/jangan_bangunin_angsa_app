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
    });

    test('starting inside a wall, he can walk out but not further in', () {
      final b = at(0, 270);
      run(b, 0.5, move: -1);
      expect(b.feet.x, 0);
      run(b, 0.5, move: 1);
      expect(b.feet.x, closeTo(60, 2));
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

  group('raised solids', () {
    // A 40 px crate on the wood floor, 500..540.
    Body onCrate(double x) => Body(
      Geometry(
        floorY: 270,
        solids: [...world().solids, const Solid(Box(500, 230, 540, 270), Surface.wood)],
        platforms: const [],
      ),
      Vec(x, 230),
      t,
    );

    test('he stands on the edge of a crate while his body is over it', () {
      final b = onCrate(548);
      expect(b.grounded, isTrue);
      final r = run(b, 1);
      expect(r.landings, isEmpty);
      expect(b.feet, const Vec(548, 230));
    });

    test('walking off the edge lands once, on the floor', () {
      final b = onCrate(520);
      final r = run(b, 1, move: 1, sneak: true);
      expect(r.landings, hasLength(1));
      expect(r.landings.single.fall, 40);
      expect(r.landings.single.at.x, greaterThan(554));
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

  group('climbing', () {
    /// Pushes up once (until the mantle ends) and lets go.
    void pushUp(Body b) {
      b.step(frame, move: 0, vertical: -1, sneak: false);
      while (b.mantling) {
        b.step(frame, move: 0, vertical: -1, sneak: false);
      }
      b.step(frame, move: 0, vertical: 0, sneak: false);
    }

    test('mantling onto the counter takes 0.4s and makes no landing', () {
      final b = at(260, 270);
      expect(b.canMantle, isTrue);
      final r = run(b, 0.2, vertical: -1);
      expect(b.mantling, isTrue);
      expect(b.feet.x, 260);
      expect(b.feet.y, inExclusiveRange(200, 270));
      final rest = run(b, 0.25, vertical: -1);
      expect(b.mantling, isFalse);
      expect(b.standingOn?.id, 'counter');
      expect(b.feet, const Vec(260, 200));
      expect([...r.landings, ...rest.landings], isEmpty);
    });

    test('mantle reach: 94 px up from the counter, not 164 from the floor', () {
      expect(at(260, 200).canMantle, isTrue);
      expect(at(410, 270).canMantle, isFalse);
      expect(at(500, 270).canMantle, isFalse);
    });

    test('the shelf ladder, one push per shelf', () {
      final b = at(350, 270);
      pushUp(b);
      expect(b.standingOn?.id, 'shelfLow');
      pushUp(b);
      expect(b.standingOn?.id, 'shelfHigh');
      pushUp(b);
      expect(b.standingOn?.id, 'crawlPlank');
    });

    test('holding up climbs one level only', () {
      final b = at(350, 270);
      run(b, 3, vertical: -1);
      expect(b.standingOn?.id, 'shelfLow');
      expect(b.feet.y, 212);
    });

    test('holding up while walking climbs on arrival, once', () {
      final b = at(300, 270);
      expect(b.canMantle, isFalse);
      run(b, 2, move: -1, vertical: -1);
      expect(b.standingOn?.id, 'counter');
    });

    test('mid-mantle he is neither on the floor nor on the top yet', () {
      final b = at(260, 270);
      run(b, 0.05, vertical: -1);
      expect(b.mantling, isTrue);
      expect(b.grounded, isFalse);
      expect(b.onFloor, isFalse);
      expect(b.standingOn, isNull);
    });

    test('letting go mid-mantle still ends on top', () {
      final b = at(260, 270);
      run(b, 0.2, vertical: -1);
      run(b, 0.5);
      expect(b.standingOn?.id, 'counter');
      expect(b.feet.y, 200);
    });

    test('dropping through the counter lands on the floor', () {
      final b = at(150, 200);
      expect(b.canDrop, isTrue);
      final r = run(b, 1, vertical: 1);
      expect(b.onFloor, isTrue);
      expect(r.landings.single.fall, closeTo(70, 0.01));
      expect(r.landings.single.surface, Surface.tile);
    });

    test('down on the floor does nothing', () {
      final b = at(150, 270);
      expect(b.canDrop, isFalse);
      run(b, 1, vertical: 1);
      expect(b.feet, const Vec(150, 270));
    });

    test('the crawl plank: crawl speed, no jumping, no mantling', () {
      final b = at(300, 106);
      expect(b.crawling, isTrue);
      expect(b.canMantle, isFalse);
      run(b, 1, move: 1, sneak: true);
      expect(b.feet.x, closeTo(300 + t.crawlSpeed, 2));
      b.pressJump();
      final r = run(b, 0.5);
      expect(r.top, 106);
      expect(b.crawling, isTrue);
    });

    test('a held pot blocks jumping and mantling, not falling', () {
      final b = at(260, 270)..pressJump();
      run(b, 0.5, vertical: -1, canClimb: false);
      expect(b.feet, const Vec(260, 270));
      final c = at(270, 200);
      final r = run(c, 1, move: 1, canClimb: false);
      expect(c.onFloor, isTrue);
      expect(r.landings, hasLength(1));
    });
  });

  test('landing loudness by fall, surface and Sneak', () {
    const rows = [
      (30.0, Surface.wood, false, null),
      (84.0, Surface.wood, false, 1),
      (84.0, Surface.wood, true, null),
      (70.0, Surface.tile, false, 2),
      (164.0, Surface.wood, false, 2),
      (164.0, Surface.wood, true, 1),
      (58.0, Surface.carpet, false, 0),
      (58.0, Surface.carpet, true, null),
      (250.0, Surface.tile, false, 3),
    ];
    for (final (fall, surface, sneak, loudness) in rows) {
      final l = Landing(fall: fall, surface: surface, at: const Vec(0, 270));
      expect(landingLoudness(l, sneak: sneak, t: t), loudness, reason: '$fall px on $surface, sneak $sneak');
    }
  });
}
