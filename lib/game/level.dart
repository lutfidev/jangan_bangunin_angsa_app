import 'dart:convert';

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

/// The crawl top's walkable stretch, as the 1-D sim knew it.
// TODO(langkah 7): transitional, removed once NightSim runs on Body.
class Crawlway {
  const Crawlway({required this.from, required this.to});

  final double from;
  final double to;

  bool covers(double x) => from <= x && x <= to;
}

class Loot {
  const Loot({required this.id, required this.at, this.guarded = false, this.squeaks = false, this.high = false});

  final String id;
  final Vec at;

  double get x => at.x;
  double get y => at.y;

  /// The one loot per night she sleeps on.
  final bool guarded;

  /// Squeaks when carried at a walk.
  final bool squeaks;

  /// Sits on a crawl top.
  // TODO(langkah 7): transitional, removed once NightSim runs on Body.
  final bool high;
}

/// One night's house: spots, objects, the chain graph and the loot.
class Level {
  Level._({
    required this.id,
    required this.name,
    required this.floorY,
    required this.geometry,
    required this.playerStart,
    required this.exit,
    required this.bed,
    required this.hideSpots,
    required this.crawlway,
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
    final floorY = _num(json, 'floorY');

    final solids = [
      for (final s in _list(json, 'solids'))
        Solid(_box(s, id), _surface(s)),
      // The world's walls and ceiling.
      Solid(Box.ltwh(-100, -400, 100, 790), Surface.wood),
      Solid(Box.ltwh(_worldWidth, -400, 100, 790), Surface.wood),
      Solid(Box.ltwh(0, -100, _worldWidth, 100), Surface.wood),
    ];
    final platforms = <Platform>[];
    for (final p in _list(json, 'platforms')) {
      final pid = _str(p, 'id');
      final [from, to] = [for (final x in p['x'] as List) (x as num).toDouble()];
      if (from >= to) throw FormatException('platform runs backwards: $pid');
      platforms.add(Platform(
        id: pid,
        from: from,
        to: to,
        y: _num(p, 'y'),
        surface: _surface(p),
        crawl: p['crawl'] as bool? ?? false,
      ));
    }
    final geometry = Geometry(solids: solids, platforms: platforms, floorY: floorY);

    /// The point [raw], which has to rest on the floor or a furniture top.
    Vec placed(Object? raw, String what) {
      final [x, y] = [for (final n in raw! as List) (n as num).toDouble()];
      final p = Vec(x, y);
      if (!geometry.restsOnSurface(p)) throw FormatException('not on a surface: $what');
      return p;
    }

    final spots = <String, Spot>{};
    for (final s in _list(json, 'spots')) {
      final sid = _str(s, 'id');
      final spot = Spot(id: sid, at: placed(s['at'], 'spot $sid'), snap: s['snap'] as bool? ?? false);
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
        portable: o['portable'] as bool? ?? false,
      );
      if (!objectIds.add(object.id)) throw FormatException('duplicate object: ${object.id}');
      checkSpot(object.spot, 'object ${object.id}');
      if (!occupied.add(object.spot)) throw FormatException('two objects on spot: ${object.spot}');
      objects.add(object);
    }

    final links = [
      for (final k in _list(json, 'links'))
        Link(from: _str(k, 'from'), to: _str(k, 'to'), delay: (k['delay'] as num?)?.toDouble() ?? 0.4),
    ];
    for (final link in links) {
      checkSpot(link.from, 'link');
      checkSpot(link.to, 'link');
    }

    final crawlTop = platforms.where((p) => p.crawl).firstOrNull;
    final crawlway = crawlTop == null ? null : Crawlway(from: crawlTop.from + 6, to: crawlTop.to - 6);

    final loot = <Loot>[];
    for (final l in _list(json, 'loot')) {
      final lid = _str(l, 'id');
      final at = placed(l['at'], 'loot $lid');
      final item = Loot(
        id: lid,
        at: at,
        guarded: l['guarded'] as bool? ?? false,
        squeaks: l['squeaks'] as bool? ?? false,
        high: geometry.platformAt(at)?.crawl ?? false,
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
      final count = g['count'] as int? ?? 1;
      if (goals.any((x) => x.style == style)) throw FormatException('duplicate goal style: $styleName');
      if (count < 1) throw FormatException('goal count below 1: $styleName');
      goals.add(HeistGoal(style: style, kind: kind, count: count));
    }

    final remix = json['remix'] as Map<String, Object?>? ?? const {};
    final remixLoot = <String, List<Vec>>{};
    for (final MapEntry(key: lootId, value: points) in (remix['loot'] as Map<String, Object?>? ?? const {}).entries) {
      final item = loot.where((l) => l.id == lootId).firstOrNull ??
          (throw FormatException('remix names unknown loot: $lootId'));
      if (item.guarded) throw FormatException('remix moves the guarded loot: $lootId');
      remixLoot[lootId] = [for (final p in points as List) placed(p, 'remix loot $lootId')];
    }
    final remixSpots = <String, List<String>>{};
    for (final MapEntry(key: objectId, value: ids) in (remix['objects'] as Map<String, Object?>? ?? const {}).entries) {
      final object = objects.where((o) => o.id == objectId).firstOrNull ??
          (throw FormatException('remix names unknown object: $objectId'));
      if (!object.portable) throw FormatException('remix moves a fixed object: $objectId');
      final alternatives = [for (final id in ids as List) id as String];
      for (final spotId in alternatives) {
        checkSpot(spotId, 'remix');
        if (!spots[spotId]!.snap) throw FormatException('remix spot is not a snap spot: $spotId');
      }
      remixSpots[objectId] = alternatives;
    }

    return Level._(
      id: id,
      name: _str(json, 'name'),
      floorY: floorY,
      geometry: geometry,
      playerStart: placed(json['playerStart'], 'playerStart $id'),
      exit: placed(json['exit'], 'exit $id'),
      bed: placed(json['bed'], 'bed $id'),
      hideSpots: [
        for (final (i, p) in (json['hideSpots'] as List? ?? const []).indexed) placed(p, 'hide $i'),
      ],
      crawlway: crawlway,
      spots: spots,
      objects: objects,
      links: links,
      loot: loot,
      goals: goals,
      remixLoot: remixLoot,
      remixSpots: remixSpots,
    );
  }

  static Level parse(String source) => Level.fromJson(jsonDecode(source) as Map<String, Object?>);

  final String id;
  final String name;

  /// The floor line: where the goose walks and her ear zone sits.
  final double floorY;

  /// Floor, walls and furniture tops.
  final Geometry geometry;
  final Vec playerStart;
  final Vec exit;
  final Vec bed;
  final List<Vec> hideSpots;

  double get exitX => exit.x;
  double get bedX => bed.x;

  // TODO(langkah 7): transitional, removed once NightSim runs on Body.
  final Crawlway? crawlway;
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
    floorY: floorY,
    geometry: geometry,
    playerStart: playerStart,
    exit: exit,
    bed: bed,
    hideSpots: hideSpots,
    crawlway: crawlway,
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
            ? Loot(
                id: l.id,
                at: lootAt[l.id]!,
                guarded: l.guarded,
                squeaks: l.squeaks,
                high: geometry.platformAt(lootAt[l.id]!)?.crawl ?? false,
              )
            : l,
    ],
    goals: goals,
    remixLoot: remixLoot,
    remixSpots: remixSpots,
  );

  /// Links out of [spotId] in file order, which is poke priority.
  List<Link> linksFrom(String spotId) => [for (final k in links) if (k.from == spotId) k];
}

List<Map<String, Object?>> _list(Map<String, Object?> json, String key) =>
    [for (final e in json[key] as List? ?? const []) e as Map<String, Object?>];

String _str(Map<String, Object?> json, String key) =>
    json[key] as String? ?? (throw FormatException('missing "$key"'));

const _worldWidth = 844.0;

/// A `box: [left, top, width, height]` with some area.
Box _box(Map<String, Object?> json, String levelId) {
  final [l, t, w, h] = [for (final n in json['box'] as List) (n as num).toDouble()];
  if (w <= 0 || h <= 0) throw FormatException('box has no area: $levelId');
  return Box.ltwh(l, t, w, h);
}

Surface _surface(Map<String, Object?> json) {
  final name = _str(json, 'surface');
  return Surface.values.where((s) => s.name == name).firstOrNull ?? (throw FormatException('unknown surface: $name'));
}

double _num(Map<String, Object?> json, String key) =>
    (json[key] as num? ?? (throw FormatException('missing "$key"'))).toDouble();
