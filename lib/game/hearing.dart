import 'doors.dart';
import 'geom.dart';
import 'level.dart';
import 'noise.dart';
import 'tuning.dart';

/// A noise as it reaches her: itself in her room, else muffled at the last
/// door it came through. She walks toward [sourceX], where it really was.
class Heard {
  const Heard(this.noise, {this.through, required this.sourceX});

  final Noise noise;
  final Door? through;
  final double sourceX;

  bool get muffled => through != null;
}

/// How noise carries between rooms: through doors, an open one for free,
/// a closed one taking [Tuning.closedDoorMuffle] off. Footsteps stay in
/// their room.
class Hearing {
  Hearing(this.level, this.doors, this.tuning);

  final Level level;
  final Doors doors;
  final Tuning tuning;

  /// [noise] as a goose at [gooseX] on the floor hears it, or null if it
  /// dies out on the way.
  Heard? reach(Noise noise, double gooseX) {
    final from = level.roomsAt(Vec(noise.x, noise.y ?? level.floorY)).map((r) => r.id).toSet();
    final to = level.roomsAt(Vec(gooseX, level.floorY)).map((r) => r.id).toSet();
    if (from.any(to.contains)) return Heard(noise, sourceX: noise.x);

    // Dijkstra over rooms: the quietest way, then the fewest doors.
    final best = <String, ({int cost, int doors, Door? last})>{
      for (final id in from) id: (cost: 0, doors: 0, last: null),
    };
    final done = <String>{};
    while (true) {
      String? room;
      for (final MapEntry(:key, :value) in best.entries) {
        if (done.contains(key)) continue;
        final b = room == null ? null : best[room]!;
        if (b == null || value.cost < b.cost || (value.cost == b.cost && value.doors < b.doors)) room = key;
      }
      if (room == null) return null;
      final here = best[room]!;
      if (to.contains(room)) {
        final door = here.last!;
        return Heard(Noise(x: door.x, loudness: noise.loudness - here.cost), through: door, sourceX: noise.x);
      }
      done.add(room);
      for (final d in level.doors) {
        final next = d.left == room ? d.right : (d.right == room ? d.left : null);
        if (next == null || done.contains(next)) continue;
        final cost = here.cost + (doors.isOpen(d.id) ? 0 : tuning.closedDoorMuffle);
        if (noise.loudness - cost < 1) continue;
        final known = best[next];
        if (known == null || cost < known.cost || (cost == known.cost && here.doors + 1 < known.doors)) {
          best[next] = (cost: cost, doors: here.doors + 1, last: d);
        }
      }
    }
  }
}
