import 'dart:convert';
import 'dart:math' as math;

import 'geom.dart';
import 'heist.dart';

/// The six object types of the chain kit (Gameplay 2.0 board).
enum ObjectType { tipper, amplifier, walker, roller, chimer, squeaker }

/// A place an object can sit. Snap spots glow and take portable objects.
class Spot {
  const Spot({required this.id, required this.at, this.snap = false});

  final String id;
  final Vec at;
  final bool snap;

  double get x => at.x;
}

class LevelObject {
  const LevelObject({required this.id, required this.type, required this.spot, this.portable = false});

  final String id;
  final ObjectType type;

  /// Where it starts; the chain runner tracks where it is now.
  final String spot;
  final bool portable;
}

/// Spot [from] pokes spot [to] [delay] seconds after making its noise.
class Link {
  const Link({required this.from, required this.to, this.delay = 0.4});

  final String from;
  final String to;
  final double delay;
}

class Loot {
  const Loot({required this.id, required this.at, this.guarded = false, this.squeaks = false});

  final String id;
  final Vec at;

  double get x => at.x;
  double get y => at.y;

  /// The one loot per night she sleeps on.
  final bool guarded;

  /// Squeaks when carried at a walk.
  final bool squeaks;
}

/// A room of the house: a box on the floor line. Rooms touch edge to edge,
/// and a point on a shared edge (a doorway) is in both.
class Room {
  const Room({required this.id, required this.name, required this.box});

  final String id;
  final String name;
  final Box box;

  /// Its floor line: the box's bottom.
  double get floorY => box.bottom;

  bool contains(Vec p) => box.contains(p);
}

/// A duct or a hole in a wall that only Milo fits through, from one mouth
/// to the other in a straight line.
class Vent {
  const Vent({required this.id, required this.from, required this.to});

  final String id;
  final Vec from;
  final Vec to;

  double get length => math.sqrt(math.pow(to.x - from.x, 2) + math.pow(to.y - from.y, 2));

  /// The point [t] of the way from [from] to [to].
  Vec at(double t) => Vec(from.x + (to.x - from.x) * t, from.y + (to.y - from.y) * t);
}

/// The door between rooms [left] and [right], standing on the floor at
/// [x]. Its size is part of the level format, like the world's walls.
class Door {
  const Door({
    required this.id,
    required this.x,
    required this.floorY,
    required this.left,
    required this.right,
    this.startsOpen = false,
  });

  static const thickness = 12.0;
  static const height = 130.0;

  final String id;
  final double x;
  final double floorY;
  final String left;
  final String right;
  final bool startsOpen;

  /// The closed door: a wall for Milo, a barrier for her.
  Box get leaf => Box(x - thickness / 2, floorY - height, x + thickness / 2, floorY);

  /// Where Milo reaches for it.
  Vec get handle => Vec(x, floorY);
}

/// One night's house: spots, objects, the chain graph and the loot.
class Level {
  Level._({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    required this.floorY,
    required this.geometry,
    required this.rooms,
    required this.doors,
    required this.stairs,
    required this.vents,
    required this.playerStart,
    required this.exit,
    required this.bed,
    required this.hideSpots,
    required this.spots,
    required this.objects,
    required this.links,
    required this.loot,
    required this.goals,
    required this.remixLoot,
    required this.remixSpots,
  });

  factory Level.fromJson(Map<String, Object?> json) {
    final id = _str(json, 'id');
    if (json['version'] != 2) throw FormatException('version must be 2: $id');
    final width = _num(json, 'width');
    if (width <= 0) throw FormatException('width must be above 0: $id');
    final floorY = _num(json, 'floorY');
    final height = _optionalNum(json, 'height') ?? 390;
    if (height <= floorY) throw FormatException('height too small: $id');

    final solids = [
      for (final s in _list(json, 'solids'))
        Solid(_box(s, id), _surface(s)),
      // The world's walls and ceiling.
      Solid(Box.ltwh(-100, -400, 100, height + 400), Surface.wood),
      Solid(Box.ltwh(width, -400, 100, height + 400), Surface.wood),
      Solid(Box.ltwh(0, -100, width, 100), Surface.wood),
    ];
    final rooms = <Room>[];
    for (final r in _list(json, 'rooms')) {
      final room = Room(id: _str(r, 'id'), name: _str(r, 'name'), box: _box(r, id));
      if (rooms.any((x) => x.id == room.id)) throw FormatException('duplicate room: ${room.id}');
      if (rooms.any((x) => x.box.overlaps(room.box))) throw FormatException('rooms overlap: ${room.id}');
      if (room.box.left < 0 || room.box.right > width) throw FormatException('room outside the world: ${room.id}');
      rooms.add(room);
    }
    if (rooms.isEmpty) rooms.add(Room(id: 'room', name: _str(json, 'name'), box: Box(0, 0, width, floorY)));

    final floors = {for (final r in rooms) r.floorY}.toList()..sort();
    final floor = Geometry(solids: solids, platforms: const [], floors: floors);
    final doors = <Door>[];
    for (final d in _list(json, 'doors')) {
      final did = _str(d, 'id');
      final x = _num(d, 'x');
      final y = _optionalNum(d, 'y') ?? floorY;
      final left = rooms.where((r) => r.box.right == x && r.floorY == y).firstOrNull;
      final right = rooms.where((r) => r.box.left == x && r.floorY == y).firstOrNull;
      if (left == null || right == null) throw FormatException('door not between two rooms: $did');
      if (floor.floorSurfaceAt(x, y) == null) throw FormatException('door not on the floor: $did');
      if (doors.any((x) => x.id == did)) throw FormatException('duplicate door: $did');
      if (doors.any((other) => other.x == x && other.floorY == y)) throw FormatException('two doors in one doorway: $did');
      final door = Door(id: did, x: x, floorY: y, left: left.id, right: right.id, startsOpen: _flag(d, 'open'));
      doors.add(door);
      // The wall above the doorway, from the rooms' top down to the lintel.
      solids.add(Solid(
        Box(door.leaf.left, math.min(left.box.top, right.box.top), door.leaf.right, door.leaf.top),
        Surface.wood,
      ));
    }

    for (final a in rooms) {
      for (final b in rooms) {
        final meet = a.box.right == b.box.left && a.box.top < b.box.bottom && b.box.top < a.box.bottom;
        if (meet && !doors.any((d) => d.left == a.id && d.right == b.id)) {
          throw FormatException('rooms meet without a door: ${b.id}');
        }
      }
    }

    final platforms = <Platform>[];
    for (final p in _list(json, 'platforms')) {
      final pid = _str(p, 'id');
      final [from, to] = _numbers(p['x'], 2, 'platform $pid');
      if (from >= to) throw FormatException('platform runs backwards: $pid');
      platforms.add(Platform(
        id: pid,
        from: from,
        to: to,
        y: _num(p, 'y'),
        surface: _surface(p),
        crawl: _flag(p, 'crawl'),
      ));
    }
    final geometry = Geometry(solids: solids, platforms: platforms, floors: floors);

    /// The point [raw], which has to rest on the floor or a furniture top.
    Vec placed(Object? raw, String what) {
      final [x, y] = _numbers(raw, 2, what);
      final p = Vec(x, y);
      if (!geometry.restsOnSurface(p)) throw FormatException('not on a surface: $what');
      if (!rooms.any((r) => r.contains(p))) throw FormatException('not in a room: $what');
      return p;
    }

    Set<Room> roomsOf(Vec p) => {for (final r in rooms) if (r.contains(p)) r};

    final stairs = <Stair>[];
    for (final s in _list(json, 'stairs')) {
      final sid = _str(s, 'id');
      final [bx, by] = _numbers(s['bottom'], 2, 'stair $sid');
      final [tx, ty] = _numbers(s['top'], 2, 'stair $sid');
      final stair = Stair(id: sid, bottom: Vec(bx, by), top: Vec(tx, ty));
      if (stairs.any((x) => x.id == sid)) throw FormatException('duplicate stair: $sid');
      if (by <= ty) throw FormatException('stair runs backwards: $sid');
      if ((tx - bx).abs() < Stair.minRun) throw FormatException('stair too steep: $sid');
      if (!geometry.onFloor(stair.bottom) || !geometry.onFloor(stair.top)) {
        throw FormatException('stair not on a floor: $sid');
      }
      if (roomsOf(stair.bottom).isEmpty || roomsOf(stair.top).isEmpty) throw FormatException('not in a room: stair $sid');
      stairs.add(stair);
    }

    final vents = <Vent>[];
    for (final v in _list(json, 'vents')) {
      final vid = _str(v, 'id');
      final vent = Vent(id: vid, from: placed(v['from'], 'vent $vid'), to: placed(v['to'], 'vent $vid'));
      if (vents.any((x) => x.id == vid)) throw FormatException('duplicate vent: $vid');
      if (roomsOf(vent.from).intersection(roomsOf(vent.to)).isNotEmpty) throw FormatException('vent ends in one room: $vid');
      vents.add(vent);
    }

    final spots = <String, Spot>{};
    for (final s in _list(json, 'spots')) {
      final sid = _str(s, 'id');
      final spot = Spot(id: sid, at: placed(s['at'], 'spot $sid'), snap: _flag(s, 'snap'));
      if (spots.containsKey(spot.id)) throw FormatException('duplicate spot: ${spot.id}');
      spots[spot.id] = spot;
    }
    void checkSpot(String id, String what) {
      if (!spots.containsKey(id)) throw FormatException('$what names an unknown spot: $id');
    }

    final objects = <LevelObject>[];
    final occupied = <String>{};
    final objectIds = <String>{};
    for (final o in _list(json, 'objects')) {
      final typeName = _str(o, 'type');
      final type = ObjectType.values.where((t) => t.name == typeName).firstOrNull ??
          (throw FormatException('unknown object type: $typeName'));
      final object = LevelObject(
        id: _str(o, 'id'),
        type: type,
        spot: _str(o, 'spot'),
        portable: _flag(o, 'portable'),
      );
      if (!objectIds.add(object.id)) throw FormatException('duplicate object: ${object.id}');
      checkSpot(object.spot, 'object ${object.id}');
      if (!occupied.add(object.spot)) throw FormatException('two objects on spot: ${object.spot}');
      objects.add(object);
    }

    final links = [
      for (final k in _list(json, 'links'))
        Link(from: _str(k, 'from'), to: _str(k, 'to'), delay: _optionalNum(k, 'delay') ?? 0.4),
    ];
    for (final link in links) {
      checkSpot(link.from, 'link');
      checkSpot(link.to, 'link');
    }

    final loot = <Loot>[];
    for (final l in _list(json, 'loot')) {
      final lid = _str(l, 'id');
      final at = placed(l['at'], 'loot $lid');
      final item = Loot(
        id: lid,
        at: at,
        guarded: _flag(l, 'guarded'),
        squeaks: _flag(l, 'squeaks'),
      );
      if (loot.any((x) => x.id == item.id)) throw FormatException('duplicate loot: ${item.id}');
      if (item.guarded && loot.any((x) => x.guarded)) {
        throw FormatException('more than one guarded loot: ${item.id}');
      }
      loot.add(item);
    }

    final goals = <HeistGoal>[];
    for (final g in _list(json, 'goals')) {
      final styleName = _str(g, 'style');
      final style = PlayStyle.values.where((s) => s.name == styleName).firstOrNull ??
          (throw FormatException('unknown goal style: $styleName'));
      final kindName = _str(g, 'kind');
      final kind = GoalKind.values.where((k) => k.name == kindName).firstOrNull ??
          (throw FormatException('unknown goal kind: $kindName'));
      final count = _optionalInt(g, 'count') ?? 1;
      if (goals.any((x) => x.style == style)) throw FormatException('duplicate goal style: $styleName');
      if (count < 1) throw FormatException('goal count below 1: $styleName');
      goals.add(HeistGoal(style: style, kind: kind, count: count));
    }

    final remix = _optionalObject(json, 'remix');
    final remixLoot = <String, List<Vec>>{};
    for (final MapEntry(key: lootId, value: points) in _optionalObject(remix, 'loot').entries) {
      final item = loot.where((l) => l.id == lootId).firstOrNull ??
          (throw FormatException('remix names unknown loot: $lootId'));
      if (item.guarded) throw FormatException('remix moves the guarded loot: $lootId');
      remixLoot[lootId] = [
        for (final p in _listOf(points, 'not a list: remix loot $lootId')) placed(p, 'remix loot $lootId'),
      ];
    }
    final remixSpots = <String, List<String>>{};
    for (final MapEntry(key: objectId, value: ids) in _optionalObject(remix, 'objects').entries) {
      final object = objects.where((o) => o.id == objectId).firstOrNull ??
          (throw FormatException('remix names unknown object: $objectId'));
      if (!object.portable) throw FormatException('remix moves a fixed object: $objectId');
      final alternatives = [
        for (final id in _listOf(ids, 'not a list: remix object $objectId'))
          id is String ? id : throw FormatException('not text in remix object $objectId'),
      ];
      for (final spotId in alternatives) {
        checkSpot(spotId, 'remix');
        if (!spots[spotId]!.snap) throw FormatException('remix spot is not a snap spot: $spotId');
      }
      remixSpots[objectId] = alternatives;
    }

    return Level._(
      id: id,
      name: _str(json, 'name'),
      width: width,
      height: height,
      floorY: floorY,
      geometry: geometry,
      rooms: rooms,
      doors: doors,
      stairs: stairs,
      vents: vents,
      playerStart: placed(json['playerStart'], 'playerStart $id'),
      exit: placed(json['exit'], 'exit $id'),
      bed: placed(json['bed'], 'bed $id'),
      hideSpots: [
        for (final (i, p) in _listOf(json['hideSpots'] ?? const [], 'not a list: "hideSpots"').indexed)
          placed(p, 'hide $i'),
      ],
      spots: spots,
      objects: objects,
      links: links,
      loot: loot,
      goals: goals,
      remixLoot: remixLoot,
      remixSpots: remixSpots,
    );
  }

  static Level parse(String source) =>
      Level.fromJson(_object(jsonDecode(source), 'not a level object'));

  final String id;
  final String name;

  /// How wide the world is; the parser walls it in at 0 and here.
  final double width;

  /// How tall the world is: one 390-px screen per storey.
  final double height;

  /// The ground floor's line: the floor of a level without rooms, and of a
  /// door that names no `y`.
  final double floorY;

  /// Floor, walls and furniture tops.
  final Geometry geometry;

  /// Never empty: a level without rooms is one room the size of the world.
  final List<Room> rooms;
  final List<Door> doors;
  final List<Stair> stairs;
  final List<Vent> vents;

  /// The rooms [p] is in: two in a doorway, none outside the house.
  List<Room> roomsAt(Vec p) => [for (final r in rooms) if (r.contains(p)) r];

  /// [roomsAt], and on a stair both rooms it joins, even inside the floor
  /// it climbs through. Its two ends are on their floors only.
  List<Room> roomsAround(Vec p) {
    final found = roomsAt(p).toSet();
    for (final s in stairs) {
      if (p.x <= s.left || p.x >= s.right || (s.yAt(p.x) - p.y).abs() > 2) continue;
      found.addAll(roomsAt(s.bottom).followedBy(roomsAt(s.top)));
    }
    return [for (final r in rooms) if (found.contains(r)) r];
  }

  /// The floor line at or below [p]: the floor of the room it is in, or of
  /// the first room under it.
  double floorOf(Vec p) {
    double? best;
    for (final r in rooms) {
      if (r.box.left > p.x || p.x > r.box.right || r.floorY < p.y - 2) continue;
      if (best == null || r.floorY < best) best = r.floorY;
    }
    return best ?? floorY;
  }
  final Vec playerStart;
  final Vec exit;
  final Vec bed;
  final List<Vec> hideSpots;

  double get exitX => exit.x;
  double get bedX => bed.x;
  final Map<String, Spot> spots;
  final List<LevelObject> objects;
  final List<Link> links;
  final List<Loot> loot;

  /// The night's heist goals, one per style.
  final List<HeistGoal> goals;

  /// Nightly Remix: the other places each loot may start at, in file order.
  final Map<String, List<Vec>> remixLoot;

  /// Nightly Remix: the other snap spots each portable object may start on.
  final Map<String, List<String>> remixSpots;

  /// This house with loot moved to [lootAt] and objects started on
  /// [objectSpots], keyed by id. The caller keeps them on valid spots.
  Level rearranged({Map<String, Vec> lootAt = const {}, Map<String, String> objectSpots = const {}}) => Level._(
    id: id,
    name: name,
    width: width,
    height: height,
    floorY: floorY,
    geometry: geometry,
    rooms: rooms,
    doors: doors,
    stairs: stairs,
    vents: vents,
    playerStart: playerStart,
    exit: exit,
    bed: bed,
    hideSpots: hideSpots,
    spots: spots,
    objects: [
      for (final o in objects)
        objectSpots.containsKey(o.id)
            ? LevelObject(id: o.id, type: o.type, spot: objectSpots[o.id]!, portable: o.portable)
            : o,
    ],
    links: links,
    loot: [
      for (final l in loot)
        lootAt.containsKey(l.id)
            ? Loot(id: l.id, at: lootAt[l.id]!, guarded: l.guarded, squeaks: l.squeaks)
            : l,
    ],
    goals: goals,
    remixLoot: remixLoot,
    remixSpots: remixSpots,
  );

  /// Links out of [spotId] in file order, which is poke priority.
  List<Link> linksFrom(String spotId) => [for (final k in links) if (k.from == spotId) k];
}

// Readers for the JSON's shapes. Anything the wrong shape is a
// FormatException, like any other mistake in the file.

Map<String, Object?> _object(Object? raw, String message) =>
    raw is Map<String, Object?> ? raw : throw FormatException(message);

List<Object?> _listOf(Object? raw, String message) => raw is List ? raw : throw FormatException(message);

/// The optional list of objects at [key].
List<Map<String, Object?>> _list(Map<String, Object?> json, String key) => [
  for (final e in _listOf(json[key] ?? const [], 'not a list: "$key"')) _object(e, 'not an object in "$key"'),
];

Map<String, Object?> _optionalObject(Map<String, Object?> json, String key) =>
    json[key] == null ? const {} : _object(json[key], 'not an object: "$key"');

String _str(Map<String, Object?> json, String key) => switch (json[key]) {
  final String s => s,
  null => throw FormatException('missing "$key"'),
  _ => throw FormatException('not text: "$key"'),
};

double _num(Map<String, Object?> json, String key) =>
    _optionalNum(json, key) ?? (throw FormatException('missing "$key"'));

double? _optionalNum(Map<String, Object?> json, String key) => switch (json[key]) {
  final num n => n.toDouble(),
  null => null,
  _ => throw FormatException('not a number: "$key"'),
};

int? _optionalInt(Map<String, Object?> json, String key) => switch (json[key]) {
  final int n => n,
  null => null,
  _ => throw FormatException('not a whole number: "$key"'),
};

/// An optional true/false, false when left out.
bool _flag(Map<String, Object?> json, String key) => switch (json[key]) {
  final bool b => b,
  null => false,
  _ => throw FormatException('not true or false: "$key"'),
};

/// Exactly [count] numbers, for [what].
List<double> _numbers(Object? raw, int count, String what) {
  if (raw is! List || raw.length != count || raw.any((n) => n is! num)) {
    throw FormatException('needs $count numbers: $what');
  }
  return [for (final n in raw) (n as num).toDouble()];
}

/// A `box: [left, top, width, height]` with some area.
Box _box(Map<String, Object?> json, String levelId) {
  final [l, t, w, h] = _numbers(json['box'], 4, 'box $levelId');
  if (w <= 0 || h <= 0) throw FormatException('box has no area: $levelId');
  return Box.ltwh(l, t, w, h);
}

Surface _surface(Map<String, Object?> json) {
  final name = _str(json, 'surface');
  return Surface.values.where((s) => s.name == name).firstOrNull ?? (throw FormatException('unknown surface: $name'));
}

