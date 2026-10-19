import 'dart:convert';

import 'heist.dart';

/// The six object types of the chain kit (Gameplay 2.0 board).
enum ObjectType { tipper, amplifier, walker, roller, chimer, squeaker }

/// A place on the floor line an object can sit. Snap spots glow and take
/// portable objects.
class Spot {
  const Spot({required this.id, required this.x, this.snap = false});

  final String id;
  final double x;
  final bool snap;
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

/// A plank above the floor line, from [from] to [to]. The burglar gets on
/// and off at either end.
class Crawlway {
  const Crawlway({required this.from, required this.to});

  final double from;
  final double to;

  bool covers(double x) => from <= x && x <= to;
}

class Loot {
  const Loot({required this.id, required this.x, this.guarded = false, this.squeaks = false, this.high = false});

  final String id;
  final double x;

  /// The one loot per night she sleeps on.
  final bool guarded;

  /// Squeaks when carried at a walk.
  final bool squeaks;

  /// Sits up on the crawlway: only reachable from there.
  final bool high;
}

/// One night's house: spots, objects, the chain graph and the loot.
class Level {
  Level._({
    required this.id,
    required this.name,
    required this.playerStart,
    required this.exitX,
    required this.bedX,
    required this.hideSpots,
    required this.crawlway,
    required this.spots,
    required this.objects,
    required this.links,
    required this.loot,
    required this.goals,
  });

  factory Level.fromJson(Map<String, Object?> json) {
    final spots = <String, Spot>{};
    for (final s in _list(json, 'spots')) {
      final spot = Spot(id: _str(s, 'id'), x: _num(s, 'x'), snap: s['snap'] as bool? ?? false);
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

    final id = _str(json, 'id');
    final crawl = json['crawlway'] as Map<String, Object?>?;
    final crawlway = crawl == null ? null : Crawlway(from: _num(crawl, 'from'), to: _num(crawl, 'to'));
    if (crawlway != null && crawlway.from >= crawlway.to) throw FormatException('crawlway runs backwards: $id');

    final loot = <Loot>[];
    for (final l in _list(json, 'loot')) {
      final item = Loot(
        id: _str(l, 'id'),
        x: _num(l, 'x'),
        guarded: l['guarded'] as bool? ?? false,
        squeaks: l['squeaks'] as bool? ?? false,
        high: l['high'] as bool? ?? false,
      );
      if (item.high && !(crawlway?.covers(item.x) ?? false)) {
        throw FormatException('high loot off the crawlway: ${item.id}');
      }
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

    return Level._(
      id: id,
      name: _str(json, 'name'),
      playerStart: _num(json, 'playerStart'),
      exitX: _num(json, 'exitX'),
      bedX: _num(json, 'bedX'),
      hideSpots: [for (final x in json['hideSpots'] as List? ?? const []) (x as num).toDouble()],
      crawlway: crawlway,
      spots: spots,
      objects: objects,
      links: links,
      loot: loot,
      goals: goals,
    );
  }

  static Level parse(String source) => Level.fromJson(jsonDecode(source) as Map<String, Object?>);

  final String id;
  final String name;
  final double playerStart;
  final double exitX;
  final double bedX;
  final List<double> hideSpots;
  final Crawlway? crawlway;
  final Map<String, Spot> spots;
  final List<LevelObject> objects;
  final List<Link> links;
  final List<Loot> loot;

  /// The night's heist goals, one per style.
  final List<HeistGoal> goals;

  /// Links out of [spotId] in file order, which is poke priority.
  List<Link> linksFrom(String spotId) => [for (final k in links) if (k.from == spotId) k];
}

List<Map<String, Object?>> _list(Map<String, Object?> json, String key) =>
    [for (final e in json[key] as List? ?? const []) e as Map<String, Object?>];

String _str(Map<String, Object?> json, String key) =>
    json[key] as String? ?? (throw FormatException('missing "$key"'));

double _num(Map<String, Object?> json, String key) =>
    (json[key] as num? ?? (throw FormatException('missing "$key"'))).toDouble();
