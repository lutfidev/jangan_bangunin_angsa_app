import 'dart:math' as math;

import 'doors.dart';
import 'geom.dart';
import 'level.dart';
import 'noise.dart';
import 'tuning.dart';

/// What a noise can pass through on its way to another room.
enum PortalKind { door, stairs, vent, floor }

/// A way between rooms [a] and [b]. [id] is the door's, stair's or vent's;
/// a floor between stacked rooms is `'<upper>/<lower>'`. Sound comes out
/// at [xA] into [a] and [xB] into [b]; through a floor, right above or
/// below where it came from.
class Portal {
  const Portal({required this.kind, required this.id, required this.a, required this.b, this.xA, this.xB});

  final PortalKind kind;
  final String id;
  final String a;
  final String b;
  final double? xA;
  final double? xB;
}

/// A noise as it reaches her: itself in her room, else muffled at the last
/// portal it came through, on her room's floor. She walks toward [source],
/// where it really was.
class Heard {
  const Heard(this.noise, {this.through, required this.source});

  final Noise noise;
  final Portal? through;
  final Vec source;

  bool get muffled => through != null;
}

/// How noise carries between rooms: an open door or a vent for free, a
/// closed door [Tuning.closedDoorMuffle], a stair [Tuning.stairMuffle], a
/// floor [Tuning.floorMuffle]. Footsteps stay in their room.
class Hearing {
  Hearing(this.level, this.doors, this.tuning) : portals = _portals(level), _rooms = {for (final r in level.rooms) r.id: r};

  final Level level;
  final Doors doors;
  final Tuning tuning;
  final List<Portal> portals;
  final Map<String, Room> _rooms;

  /// Stacked rooms are at most this far apart: one floor slab.
  static const _slab = 150.0;

  static List<Portal> _portals(Level level) {
    String roomOf(Vec p) => level.roomsAt(p).first.id;
    return [
      for (final d in level.doors) Portal(kind: PortalKind.door, id: d.id, a: d.left, b: d.right, xA: d.x, xB: d.x),
      for (final s in level.stairs)
        Portal(kind: PortalKind.stairs, id: s.id, a: roomOf(s.bottom), b: roomOf(s.top), xA: s.bottom.x, xB: s.top.x),
      for (final v in level.vents)
        Portal(kind: PortalKind.vent, id: v.id, a: roomOf(v.from), b: roomOf(v.to), xA: v.from.x, xB: v.to.x),
      for (final up in level.rooms)
        for (final down in level.rooms)
          if (up.box.left < down.box.right &&
              down.box.left < up.box.right &&
              down.box.top >= up.box.bottom &&
              down.box.top - up.box.bottom <= _slab)
            Portal(kind: PortalKind.floor, id: '${up.id}/${down.id}', a: up.id, b: down.id),
    ];
  }

  int _cost(Portal p) => switch (p.kind) {
    PortalKind.door => doors.isOpen(p.id) ? 0 : tuning.closedDoorMuffle,
    PortalKind.stairs => tuning.stairMuffle,
    PortalKind.vent => 0,
    PortalKind.floor => tuning.floorMuffle,
  };

  /// [noise] as a goose at [goose] hears it, or null if it dies out on the
  /// way.
  Heard? reach(Noise noise, Vec goose) {
    final source = Vec(noise.x, noise.y ?? level.floorY);
    final from = level.roomsAround(source).map((r) => r.id).toSet();
    final to = level.roomsAround(goose).map((r) => r.id).toSet();
    if (from.any(to.contains)) return Heard(noise, source: source);

    // Dijkstra over rooms: the quietest way, then the fewest portals. Each
    // room keeps the x the sound came in at.
    final best = <String, ({int cost, int portals, Portal? last, double x})>{
      for (final id in from) id: (cost: 0, portals: 0, last: null, x: noise.x),
    };
    final done = <String>{};
    while (true) {
      String? room;
      for (final MapEntry(:key, :value) in best.entries) {
        if (done.contains(key)) continue;
        final b = room == null ? null : best[room]!;
        if (b == null || value.cost < b.cost || (value.cost == b.cost && value.portals < b.portals)) room = key;
      }
      if (room == null) return null;
      final here = best[room]!;
      if (to.contains(room)) {
        return Heard(
          Noise(x: here.x, y: _rooms[room]!.floorY, loudness: noise.loudness - here.cost),
          through: here.last,
          source: source,
        );
      }
      done.add(room);
      for (final p in portals) {
        final forward = p.a == room;
        final next = forward ? p.b : (p.b == room ? p.a : null);
        if (next == null || done.contains(next)) continue;
        final cost = here.cost + _cost(p);
        if (noise.loudness - cost < 1) continue;
        final known = best[next];
        if (known == null || cost < known.cost || (cost == known.cost && here.portals + 1 < known.portals)) {
          best[next] = (cost: cost, portals: here.portals + 1, last: p, x: (forward ? p.xB : p.xA) ?? _above(here.x, room, next));
        }
      }
    }
  }

  /// Through a floor: [x] where it came from, kept inside both rooms.
  double _above(double x, String from, String to) {
    final a = _rooms[from]!.box;
    final b = _rooms[to]!.box;
    return x.clamp(math.max(a.left, b.left), math.min(a.right, b.right)).toDouble();
  }
}
