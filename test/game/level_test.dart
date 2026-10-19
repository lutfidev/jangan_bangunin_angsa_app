import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/geom.dart';
import 'package:jangan_bangunin_angsa_app/game/heist.dart';
import 'package:jangan_bangunin_angsa_app/game/level.dart';

import 'fixtures.dart';

/// The whole message, so a short id like 'a' can't match by accident.
Matcher _formatError(String message) =>
    throwsA(isA<FormatException>().having((e) => e.message, 'message', message));

void main() {
  test('night 3 parses', () {
    final l = night3();
    expect(l.name, 'The Midnight Kitchen');
    expect(l.spots, hasLength(8));
    expect(l.spots['counterPot']!.snap, isTrue);
    expect(l.objects.firstWhere((o) => o.id == 'pot').portable, isTrue);
    expect(l.objects.firstWhere((o) => o.id == 'clock').type, ObjectType.chimer);
    expect(l.linksFrom('sideTable').map((k) => k.to), ['underSideTable', 'clockStand']);
    expect(l.links.first.delay, 0.4);
    expect(l.loot.singleWhere((x) => x.guarded).id, 'egg');
    expect(l.loot.firstWhere((x) => x.id == 'chicken').squeaks, isTrue);
    expect(l.hideSpots, [const Vec(148, 270), const Vec(703, 270)]);
  });

  test('night 3 is laid out in 2-D', () {
    final l = night3();
    expect(l.floorY, 270);
    expect(l.geometry.platforms.map((p) => p.id), ['counter', 'crawlPlank', 'shelfLow', 'shelfHigh', 'sideTable', 'hallTable']);
    expect(l.geometry.platforms[1].crawl, isTrue);
    expect(l.loot.firstWhere((x) => x.id == 'chicken').at, const Vec(353, 106));
    expect(l.loot.firstWhere((x) => x.id == 'toaster').at, const Vec(218, 200));
    expect(l.spots['shelfBooks']!.at, const Vec(340, 160));
    expect(l.playerStart, const Vec(236, 270));
    expect(l.exitX, 770);
    expect(l.bedX, 502);
    expect(l.geometry.floorSurfaceAt(100), Surface.tile);
    expect(l.geometry.floorSurfaceAt(500), Surface.carpet);
  });

  test('the parser walls the world in', () {
    final g = Level.parse(minimalLevel()).geometry;
    expect(g.solids.map((s) => s.box), containsAll([
      Box.ltwh(-100, -400, 100, 790),
      Box.ltwh(844, -400, 100, 790),
      Box.ltwh(0, -100, 844, 100),
    ]));
  });

  test('rejects a level that is not v2', () {
    expect(() => Level.parse(minimalLevel(extra: {'version': 1})), _formatError('version must be 2: test'));
  });

  test('rejects broken geometry', () {
    expect(
      () => Level.parse(minimalLevel(extra: {'solids': [{'box': [0, 270, 0, 120], 'surface': 'wood'}]})),
      _formatError('box has no area: test'),
    );
    expect(
      () => Level.parse(minimalLevel(extra: {'solids': [{'box': [0, 270, 844, 120], 'surface': 'lava'}]})),
      _formatError('unknown surface: lava'),
    );
    expect(
      () => Level.parse(minimalLevel(platforms: [{'id': 'shelf', 'x': [90, 10], 'y': 200, 'surface': 'wood'}])),
      _formatError('platform runs backwards: shelf'),
    );
  });

  test('rejects things floating in the air', () {
    Level parse(Map<String, Object?> extra) => Level.parse(minimalLevel(extra: extra));
    expect(() => parse({'playerStart': [0, 200]}), _formatError('not on a surface: playerStart test'));
    expect(() => parse({'exit': [800, 200]}), _formatError('not on a surface: exit test'));
    expect(() => parse({'bed': [400, 200]}), _formatError('not on a surface: bed test'));
    expect(() => parse({'hideSpots': [[10, 270], [20, 200]]}), _formatError('not on a surface: hide 1'));
    expect(
      () => Level.parse(minimalLevel(spots: [{'id': 'a', 'at': [10, 200]}])),
      _formatError('not on a surface: spot a'),
    );
    expect(
      () => Level.parse(minimalLevel(loot: [{'id': 'cup', 'at': [10, 200]}])),
      _formatError('not on a surface: loot cup'),
    );
    expect(
      () => Level.parse(minimalLevel(loot: [{'id': 'cup', 'x': 10}], remix: {'loot': {'cup': [[50, 200]]}})),
      _formatError('not on a surface: remix loot cup'),
    );
    final shelf = {'id': 'shelf', 'x': [0, 100], 'y': 200, 'surface': 'wood'};
    expect(
      Level.parse(minimalLevel(platforms: [shelf], loot: [{'id': 'cup', 'at': [10, 200]}])).loot.single.at,
      const Vec(10, 200),
    );
  });

  test('rejects a link to an unknown spot', () {
    expect(() => Level.parse(minimalLevel(links: [{'from': 'a', 'to': 'nope'}])), _formatError('link names an unknown spot: nope'));
  });

  test('rejects an object on an unknown spot', () {
    expect(
      () => Level.parse(minimalLevel(objects: [{'id': 'o', 'type': 'tipper', 'spot': 'ghost'}])),
      _formatError('object o names an unknown spot: ghost'),
    );
  });

  test('rejects two objects on one spot', () {
    expect(
      () => Level.parse(minimalLevel(objects: [
        {'id': 'o1', 'type': 'tipper', 'spot': 'a'},
        {'id': 'o2', 'type': 'chimer', 'spot': 'a'},
      ])),
      _formatError('two objects on spot: a'),
    );
  });

  test('rejects more than one guarded loot', () {
    expect(
      () => Level.parse(minimalLevel(loot: [
        {'id': 'egg', 'x': 1, 'guarded': true},
        {'id': 'crown', 'x': 2, 'guarded': true},
      ])),
      _formatError('more than one guarded loot: crown'),
    );
  });

  test('rejects a duplicate id', () {
    expect(
      () => Level.parse(minimalLevel(spots: [{'id': 'a', 'x': 1}, {'id': 'a', 'x': 2}])),
      _formatError('duplicate spot: a'),
    );
  });

  test('rejects an unknown object type', () {
    expect(
      () => Level.parse(minimalLevel(objects: [{'id': 'o', 'type': 'trebuchet', 'spot': 'a'}])),
      _formatError('unknown object type: trebuchet'),
    );
  });

  test('night 3 has a goal per style', () {
    final goals = night3().goals;
    expect(goals.map((g) => g.style), [PlayStyle.ghost, PlayStyle.trickster, PlayStyle.chaos]);
    expect(goals.map((g) => g.kind), [GoalKind.neverSuspicious, GoalKind.lure, GoalKind.chain]);
    expect(goals.map((g) => g.count), [1, 2, 5]);
  });

  test('goals are optional', () {
    expect(Level.parse(minimalLevel()).goals, isEmpty);
  });

  test('rejects bad goals', () {
    Level parse(List<Object?> goals) => Level.parse(minimalLevel(goals: goals));
    expect(() => parse([{'style': 'sneaky', 'kind': 'lure'}]), _formatError('unknown goal style: sneaky'));
    expect(() => parse([{'style': 'ghost', 'kind': 'nap'}]), _formatError('unknown goal kind: nap'));
    expect(
      () => parse([{'style': 'ghost', 'kind': 'neverSuspicious'}, {'style': 'ghost', 'kind': 'lure'}]),
      _formatError('duplicate goal style: ghost'),
    );
    expect(() => parse([{'style': 'chaos', 'kind': 'chain', 'count': 0}]), _formatError('goal count below 1: chaos'));
  });

  test('parses remix alternatives', () {
    final level = night3();
    expect(level.remixLoot, {
      'toaster': [const Vec(60, 270)],
      'chicken': [const Vec(300, 106)],
    });
    expect(level.remixSpots, {'pot': ['underShelf', 'underSideTable']});
  });

  test('remix entries are optional', () {
    final level = Level.parse(minimalLevel());
    expect(level.remixLoot, isEmpty);
    expect(level.remixSpots, isEmpty);
  });

  test('rejects bad remix entries', () {
    final spots = [
      {'id': 'a', 'x': 10},
      {'id': 'b', 'x': 50, 'snap': true},
      {'id': 'c', 'x': 90},
    ];
    final objects = [
      {'id': 'o', 'type': 'tipper', 'spot': 'a'},
      {'id': 'pot', 'type': 'amplifier', 'spot': 'c', 'portable': true},
    ];
    final loot = [
      {'id': 'cup', 'x': 200},
      {'id': 'egg', 'x': 400, 'guarded': true},
    ];
    Level parse(Map<String, Object?> remix) => Level.parse(minimalLevel(
      spots: spots,
      objects: objects,
      loot: loot,
      remix: remix,
    ));
    expect(() => parse({'loot': {'mug': [5]}}), _formatError('remix names unknown loot: mug'));
    expect(() => parse({'loot': {'egg': [300]}}), _formatError('remix moves the guarded loot: egg'));
    expect(() => parse({'objects': {'o': ['b']}}), _formatError('remix moves a fixed object: o'));
    expect(() => parse({'objects': {'ghost': ['b']}}), _formatError('remix names unknown object: ghost'));
    expect(() => parse({'objects': {'pot': ['a']}}), _formatError('remix spot is not a snap spot: a'));
    expect(() => parse({'objects': {'pot': ['zzz']}}), _formatError('remix names an unknown spot: zzz'));
    expect(parse({'loot': {'cup': [300]}, 'objects': {'pot': ['b']}}).remixLoot['cup'], [const Vec(300, 270)]);
  });

  test('rearranged moves loot and objects', () {
    final level = night3();
    final moved = level.rearranged(lootAt: {'toaster': const Vec(424, 270)}, objectSpots: {'pot': 'underShelf'});
    expect(moved.loot.firstWhere((l) => l.id == 'toaster').at, const Vec(424, 270));
    expect(moved.objects.firstWhere((o) => o.id == 'pot').spot, 'underShelf');
    expect(moved.loot.firstWhere((l) => l.id == 'chicken').x, 353);
    expect(moved.objects.firstWhere((o) => o.id == 'glass').spot, 'counterLeft');
    expect(moved.id, level.id);
    expect(moved.goals, level.goals);
    expect(level.loot.firstWhere((l) => l.id == 'toaster').x, 218);
    expect(level.objects.firstWhere((o) => o.id == 'pot').spot, 'counterPot');
  });
}
