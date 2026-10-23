import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/geom.dart';
import 'package:jangan_bangunin_angsa_app/game/heist.dart';
import 'package:jangan_bangunin_angsa_app/game/level.dart';
import 'package:jangan_bangunin_angsa_app/game/modifiers.dart';

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

  test('the parser walls the world in at its width', () {
    final l = Level.parse(minimalLevel(extra: {'width': 1000}));
    expect(l.width, 1000);
    expect(l.geometry.solids.map((s) => s.box), containsAll([
      Box.ltwh(-100, -400, 100, 790),
      Box.ltwh(1000, -400, 100, 790),
      Box.ltwh(0, -100, 1000, 100),
    ]));
    expect(night3().width, 844);
    expect(() => Level.parse(minimalLevel(extra: {'width': 0})), _formatError('width must be above 0: test'));
  });

  test('a badly shaped level is a FormatException too', () {
    Level parse(Map<String, Object?> extra) => Level.parse(minimalLevel(extra: extra));
    Level withPlatform(Map<String, Object?> p) =>
        Level.parse(minimalLevel(platforms: [{'id': 'shelf', 'x': [0, 90], 'y': 200, 'surface': 'wood', ...p}]));
    expect(() => Level.parse('[]'), _formatError('not a level object'));
    expect(() => parse({'width': null}), _formatError('missing "width"'));
    expect(() => parse({'floorY': 'low'}), _formatError('not a number: "floorY"'));
    expect(() => parse({'name': 3}), _formatError('not text: "name"'));
    expect(() => parse({'solids': {'box': 1}}), _formatError('not a list: "solids"'));
    expect(() => parse({'solids': [7]}), _formatError('not an object in "solids"'));
    expect(
      () => parse({'solids': [{'box': [0, 270, 844], 'surface': 'wood'}]}),
      _formatError('needs 4 numbers: box test'),
    );
    expect(() => parse({'playerStart': 0}), _formatError('needs 2 numbers: playerStart test'));
    expect(() => parse({'playerStart': [0, '270']}), _formatError('needs 2 numbers: playerStart test'));
    expect(() => withPlatform({'x': null}), _formatError('needs 2 numbers: platform shelf'));
    expect(() => withPlatform({'crawl': 'yes'}), _formatError('not true or false: "crawl"'));
    expect(() => parse({'links': [{'from': 'a', 'to': 'a', 'delay': 'soon'}]}), _formatError('not a number: "delay"'));
    expect(
      () => parse({'goals': [{'style': 'chaos', 'kind': 'chain', 'count': 1.5}]}),
      _formatError('not a whole number: "count"'),
    );
    expect(() => parse({'remix': <Object?>[]}), _formatError('not an object: "remix"'));
    expect(
      () => parse({'loot': [{'id': 'cup', 'at': [10, 270]}], 'remix': {'loot': {'cup': 50}}}),
      _formatError('not a list: remix loot cup'),
    );
    final portable = [{'id': 'o', 'type': 'tipper', 'spot': 'a', 'portable': true}];
    expect(
      () => parse({'objects': portable, 'remix': {'objects': {'o': 'a'}}}),
      _formatError('not a list: remix object o'),
    );
    expect(
      () => parse({'objects': portable, 'remix': {'objects': {'o': [3]}}}),
      _formatError('not text in remix object o'),
    );
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

  group('rooms and doors', () {
    test('a level without rooms is one room, with no doors', () {
      expect(night3().rooms.single.box, const Box(0, 0, 844, 270));
      expect(night3().rooms.single.name, 'The Midnight Kitchen');
      expect(night3().doors, isEmpty);
    });

    test('a door joins the rooms either side of it', () {
      final l = Level.parse(twoRooms());
      expect(l.rooms.map((r) => r.id), ['a', 'b']);
      final door = l.doors.single;
      expect(door.id, 'd');
      expect(door.left, 'a');
      expect(door.right, 'b');
      expect(door.startsOpen, isFalse);
      expect(door.leaf, const Box(394, 140, 406, 270));
      expect(door.handle, const Vec(400, 270));
      expect(Level.parse(twoRooms(open: true)).doors.single.startsOpen, isTrue);
      expect(l.roomsAt(const Vec(400, 270)).map((r) => r.id), ['a', 'b']);
      expect(l.roomsAt(const Vec(399, 270)).map((r) => r.id), ['a']);
    });

    test('the parser builds the wall above a door', () {
      final l = Level.parse(twoRooms());
      expect(
        l.geometry.solids.where((s) => s.box == const Box(394, 0, 406, 140)).single.surface,
        Surface.wood,
      );
    });

    test('rearranged keeps rooms and doors', () {
      final l = Level.parse(twoRooms()).rearranged();
      expect(l.rooms, hasLength(2));
      expect(l.doors.single.id, 'd');
    });

    test('rejects bad rooms and doors', () {
      Level parse(Map<String, Object?> extra) => Level.parse(twoRooms(extra: extra));
      Map<String, Object?> rooms(List<List<num>> boxes, {List<String>? ids}) => {
        'rooms': [
          for (final (i, b) in boxes.indexed) {'id': ids?[i] ?? ['a', 'b'][i], 'name': 'R', 'box': b},
        ],
      };
      expect(() => parse(rooms([[0, 0, 400, 270], [400, 0, 444, 270]], ids: ['a', 'a'])), _formatError('duplicate room: a'));
      expect(() => parse(rooms([[0, 0, 400, 270], [300, 0, 544, 270]])), _formatError('rooms overlap: b'));
      expect(() => parse(rooms([[0, 0, 400, 270], [400, 0, 500, 270]])), _formatError('room outside the world: b'));
      expect(() => parse(rooms([[20, 0, 380, 270], [400, 0, 444, 270]])), _formatError('not in a room: spot a'));
      expect(() => parse({'doors': <Object?>[]}), _formatError('rooms meet without a door: b'));
      expect(
        () => parse({'doors': [{'id': 'd', 'x': 400}, {'id': 'e', 'x': 400}]}),
        _formatError('two doors in one doorway: e'),
      );
      expect(() => parse({'doors': [{'id': 'd', 'x': 300}]}), _formatError('door not between two rooms: d'));
      expect(
        () => parse({
          'solids': [
            {'box': [0, 270, 390, 120], 'surface': 'wood'},
            {'box': [410, 270, 434, 120], 'surface': 'wood'},
          ],
          'bed': [500, 270],
        }),
        _formatError('door not on the floor: d'),
      );
      expect(
        () => parse({'doors': [{'id': 'd', 'x': 400}, {'id': 'd', 'x': 400}]}),
        _formatError('duplicate door: d'),
      );
      expect(() => parse({'doors': [{'id': 'd', 'x': 400, 'open': 'yes'}]}), _formatError('not true or false: "open"'));
    });
  });

  test('the greybox house parses', () {
    final l = house();
    expect(l.width, 2000);
    expect(l.rooms.map((r) => r.id), ['kitchen', 'living', 'hall']);
    expect(l.doors.map((d) => (d.id, d.startsOpen)), [('kitchenDoor', false), ('hallDoor', true)]);
    for (final loot in l.loot) {
      expect(l.geometry.restsOnSurface(loot.at), isTrue, reason: loot.id);
      expect(l.roomsAt(loot.at), isNotEmpty, reason: loot.id);
    }
    expect(l.roomsAt(l.bed).single.id, 'living');
    expect(l.roomsAt(l.exit).single.id, 'hall');
    expect(l.objects.map((o) => o.id), night3().objects.map((o) => o.id));
  });

  test('a night setup names its night', () {
    expect(const NightSetup().night, 'night3');
    expect(const NightSetup().withNight('house').night, 'house');
    expect(const NightSetup().withNight('house'), isNot(const NightSetup()));
    expect(const NightSetup(mirror: true).withNight('house').mirror, isTrue);
  });
}
