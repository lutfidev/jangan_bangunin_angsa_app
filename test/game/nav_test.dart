import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/doors.dart';
import 'package:jangan_bangunin_angsa_app/game/geom.dart';
import 'package:jangan_bangunin_angsa_app/game/level.dart';
import 'package:jangan_bangunin_angsa_app/game/nav.dart';

import 'fixtures.dart';

/// [twoStoreys] with the ground split at 400 by door `d` (closed), and a
/// second stair `s2` from (700, 660) up to (500, 270).
Level splitGround() => Level.parse(twoStoreys(extra: {
  'rooms': [
    {'id': 'up', 'name': 'Up', 'box': [0, 0, 844, 270]},
    {'id': 'a', 'name': 'A', 'box': [0, 390, 400, 270]},
    {'id': 'b', 'name': 'B', 'box': [400, 390, 444, 270]},
  ],
  'doors': [{'id': 'd', 'x': 400, 'y': 660}],
  'stairs': [
    {'id': 's', 'bottom': [100, 660], 'top': [300, 270]},
    {'id': 's2', 'bottom': [700, 660], 'top': [500, 270]},
  ],
}));

void main() {
  late Nav n3;
  setUp(() => n3 = Nav(night3()));

  Route from(Nav nav, Vec at, Vec target, {double speed = 110, Doors? doors}) =>
      nav.route(nav.segAt(at), at.x, target, speed: speed, doors: doors);

  test('she stands on low tops with room over them, nowhere higher', () {
    expect([for (final s in n3.segs) if (s.kind == SegKind.platform) s.id], ['counter', 'sideTable', 'hallTable']);
    final l = night3();
    expect(l.geometry.platforms.where(n3.standable).map((p) => p.id), ['counter', 'sideTable', 'hallTable']);
  });

  test('she catches what is close and within her neck', () {
    expect(n3.catches(const Vec(100, 270), const Vec(115, 200)), isTrue);
    expect(n3.catches(const Vec(100, 270), const Vec(121, 270)), isFalse);
    expect(n3.catches(const Vec(100, 270), const Vec(100, 189)), isFalse);
    expect(n3.catches(const Vec(100, 270), const Vec(100, 281)), isFalse);
  });

  test('a noise on the counter is walked to on the floor', () {
    final r = from(n3, const Vec(502, 270), const Vec(62, 200));
    expect(r.goal, const Vec(62, 270));
    expect(r.catches, isTrue);
    expect(r.moves.whereType<Flap>(), isEmpty);
    expect(r.cost, 440);
  });

  test('Milo on the counter is caught from the floor', () {
    final r = from(n3, const Vec(502, 270), const Vec(200, 200));
    expect(r.goal, const Vec(200, 270));
    expect(r.catches, isTrue);
    expect(r.moves.whereType<Flap>(), isEmpty);
  });

  test('Milo on the crawl plank gets her up on the counter, short of him', () {
    final r = from(n3, const Vec(502, 270), const Vec(353, 106));
    expect(r.goal, const Vec(280, 200));
    expect(r.catches, isFalse);
    final flap = r.moves.whereType<Flap>().single;
    expect(flap.to.id, 'counter');
    expect(flap.land, const Vec(270, 200));
    expect(r.points.first, const Vec(502, 270));
    expect(r.points.last, const Vec(280, 200));
  });

  test('upstairs is up the stair', () {
    final nav = Nav(Level.parse(twoStoreys()));
    final r = from(nav, const Vec(600, 660), const Vec(300, 270));
    expect(r.goal, const Vec(300, 270));
    expect(r.catches, isTrue);
    expect(r.moves.whereType<Cross>().map((c) => c.to.id), ['s', 'up']);
    expect(r.cost, 500 + 200);
    expect(nav.segAt(const Vec(200, 465)).id, 's');
  });

  test('a closed door costs her the push', () {
    final level = splitGround();
    final nav = Nav(level);
    final doors = Doors(level);
    expect(from(nav, const Vec(600, 660), const Vec(200, 660), doors: doors).cost, 400 + 2 * 110);
    doors.open('d');
    final open = from(nav, const Vec(600, 660), const Vec(200, 660), doors: doors);
    expect(open.cost, 400);
    expect(open.moves.whereType<Cross>().map((c) => c.to.id), ['a']);
  });

  test('round by the stairs when that is quieter than pushing', () {
    final level = splitGround();
    final nav = Nav(level);
    // Pushing at sleepwalk speed is cheap; at a crawl it would not be.
    final r = from(nav, const Vec(690, 660), const Vec(310, 270), speed: 1000, doors: Doors(level));
    expect(r.moves.whereType<Cross>().map((c) => c.to.id), ['s2', 'up']);
  });

  group('the house', () {
    late Level l;
    late Nav nav;
    setUp(() {
      l = house();
      nav = Nav(l);
    });

    test('from her bed she can walk to every room', () {
      for (final r in l.rooms) {
        final target = Vec((r.box.left + r.box.right) / 2, r.floorY);
        final route = from(nav, l.bed, target, doors: Doors(l));
        expect(route.goalSeg.id, r.id, reason: r.id);
        expect(route.catches, isTrue, reason: r.id);
      }
    });

    test('upstairs by the living-room stair, the cellar by the kitchen', () {
      final up = from(nav, l.bed, const Vec(1300, 270));
      expect(up.moves.whereType<Cross>().map((c) => c.to.id), ['livingStairs', 'landing']);
      final down = from(nav, l.bed, const Vec(500, 1050), doors: Doors(l)..open('kitchenDoor'));
      expect(down.moves.whereType<Cross>().map((c) => c.to.id), ['kitchen', 'kitchenStairs', 'cellar']);
    });

    test("the chicken's shelf and the wardrobe are out of her reach", () {
      final tops = [for (final s in nav.segs) if (s.kind == SegKind.platform) s.id];
      expect(tops, containsAll(['bedFrame', 'landingChest', 'counter', 'workbench']));
      for (final safe in ['pipeShelf', 'wardrobe', 'landingShelf', 'boilerTank', 'nightstand', 'crawlPlank', 'shelfHigh']) {
        expect(tops, isNot(contains(safe)), reason: safe);
      }
      expect(from(nav, l.bed, const Vec(1550, 900)).catches, isFalse);
    });
  });
}
