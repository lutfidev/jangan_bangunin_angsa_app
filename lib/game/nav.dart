import 'dart:math' as math;

import 'doors.dart';
import 'geom.dart';
import 'level.dart';
import 'tuning.dart';

/// What a stretch she can walk is: a room's floor, a furniture top she
/// flaps onto, or a stair.
enum SegKind { floor, platform, stair }

/// A stretch Gertrude walks, from [left] to [right]; level unless it is a
/// stair. [rooms] are the room ids it lies in (a stair, both it joins).
class Seg {
  const Seg({
    required this.index,
    required this.kind,
    required this.id,
    required this.left,
    required this.right,
    required this.yLeft,
    required this.yRight,
    required this.rooms,
  });

  final int index;
  final SegKind kind;

  /// The room's, the platform's or the stair's id.
  final String id;
  final double left;
  final double right;
  final double yLeft;
  final double yRight;
  final List<String> rooms;

  double clampX(double x) => x.clamp(left, right).toDouble();

  double yAt(double x) => right == left ? yLeft : yLeft + (yRight - yLeft) * (clampX(x) - left) / (right - left);

  Vec at(double x) => Vec(clampX(x), yAt(x));

  bool contains(Vec p) => left <= p.x && p.x <= right && (yAt(p.x) - p.y).abs() <= 2;
}

/// How two stretches join: walking across a doorway or onto a stair, or a
/// flap up onto (or down off) a top. [door] is set for a doorway.
enum LinkKind { door, stair, flap }

class NavLink {
  const NavLink({required this.kind, required this.a, required this.xa, required this.b, required this.xb, this.door});

  final LinkKind kind;
  final Seg a;
  final double xa;
  final Seg b;
  final double xb;
  final String? door;
}

/// One leg of a route.
sealed class Move {
  const Move();
}

/// Walk along [seg] to [x].
class WalkTo extends Move {
  const WalkTo(this.seg, this.x);

  final Seg seg;
  final double x;
}

/// Step from where she is onto [to]: a doorway or a stair's end, no
/// distance at all.
class Cross extends Move {
  const Cross(this.to);

  final Seg to;
}

/// Fly from [from] up (or down) to [land] on [to].
class Flap extends Move {
  const Flap(this.to, this.from, this.land);

  final Seg to;
  final Vec from;
  final Vec land;
}

/// The way to a target: the moves, where they end, what they cost (px of
/// walking), and whether she can catch the target from there.
class Route {
  const Route({required this.moves, required this.goal, required this.goalSeg, required this.cost, required this.catches, required this.points});

  final List<Move> moves;
  final Vec goal;
  final Seg goalSeg;
  final double cost;
  final bool catches;

  /// Her position, each turn of the route, and the goal: for the debug
  /// overlay.
  final List<Vec> points;
}

/// Where Gertrude can go: every room's floor, the low tops she can flap
/// onto, and the stairs, joined at doorways, stair ends and flap points.
/// Routes are planned fresh on each call; there are only a few dozen
/// points.
class Nav {
  Nav(this.level, [this.tuning = const Tuning()]) {
    _build();
  }

  final Level level;
  final Tuning tuning;
  final List<Seg> segs = [];
  final List<NavLink> links = [];

  /// Per segment, the link ends lying on it: (link index, which end).
  final Map<int, List<(int, bool)>> _ends = {};

  /// Whether she can stand on [p]: not a crawl top, no higher than
  /// [Tuning.flapHeight] over its room's floor, and with
  /// [Tuning.flapHeadroom] free above it.
  bool standable(Platform p) {
    if (p.crawl) return false;
    final rise = level.floorOf(Vec((p.from + p.to) / 2, p.y)) - p.y;
    if (rise <= 0 || rise > tuning.flapHeight) return false;
    return !level.geometry.platforms.any(
      (q) => q != p && q.from < p.to && p.from < q.to && q.y < p.y && q.y > p.y - tuning.flapHeadroom,
    );
  }

  /// She at [goose] catches [target]: close along the floor, and from a
  /// little below her feet up to her neck's reach above them.
  bool catches(Vec goose, Vec target) =>
      (target.x - goose.x).abs() <= tuning.caughtDistance &&
      target.y >= goose.y - tuning.gooseReach &&
      target.y <= goose.y + 10;

  /// The segment [p] lies on: a top before a floor, a floor before a stair.
  Seg segAt(Vec p) {
    for (final kind in const [SegKind.platform, SegKind.floor, SegKind.stair]) {
      for (final s in segs) {
        if (s.kind == kind && s.contains(p)) return s;
      }
    }
    throw StateError('nowhere for her to stand at $p');
  }

  Seg _add(SegKind kind, String id, double left, double right, double yLeft, double yRight, List<String> rooms) {
    final s = Seg(index: segs.length, kind: kind, id: id, left: left, right: right, yLeft: yLeft, yRight: yRight, rooms: rooms);
    segs.add(s);
    return s;
  }

  void _link(LinkKind kind, Seg a, double xa, Seg b, double xb, {String? door}) {
    links.add(NavLink(kind: kind, a: a, xa: xa, b: b, xb: xb, door: door));
    (_ends[a.index] ??= []).add((links.length - 1, true));
    (_ends[b.index] ??= []).add((links.length - 1, false));
  }

  void _build() {
    final floorOf = <String, Seg>{
      for (final r in level.rooms) r.id: _add(SegKind.floor, r.id, r.box.left, r.box.right, r.floorY, r.floorY, [r.id]),
    };
    Seg floorUnder(Vec p) => floorOf[level.rooms.firstWhere((r) => r.contains(p) && r.floorY == p.y).id]!;

    for (final d in level.doors) {
      _link(LinkKind.door, floorOf[d.left]!, d.x, floorOf[d.right]!, d.x, door: d.id);
    }
    for (final st in level.stairs) {
      final bottom = floorUnder(st.bottom);
      final top = floorUnder(st.top);
      final s = _add(SegKind.stair, st.id, st.left, st.right, st.yAt(st.left), st.yAt(st.right), [bottom.id, top.id]);
      _link(LinkKind.stair, bottom, st.bottom.x, s, st.bottom.x);
      _link(LinkKind.stair, s, st.top.x, top, st.top.x);
    }

    final tops = <Seg>[];
    for (final p in level.geometry.platforms) {
      if (!standable(p)) continue;
      final room = level.rooms.firstWhere((r) => r.contains(Vec((p.from + p.to) / 2, p.y)));
      final s = _add(SegKind.platform, p.id, p.from, p.to, p.y, p.y, [room.id]);
      tops.add(s);
      final floor = floorOf[room.id]!;
      final ends = p.to - p.from > 20 ? [p.from + 10, p.to - 10] : [(p.from + p.to) / 2];
      for (final x in ends) {
        _link(LinkKind.flap, floor, x, s, x);
      }
    }
    for (final (i, a) in tops.indexed) {
      for (final b in tops.skip(i + 1)) {
        if (a.rooms.first != b.rooms.first) continue;
        final from = math.max(a.left, b.left);
        final to = math.min(a.right, b.right);
        if (from <= to) {
          _link(LinkKind.flap, a, (from + to) / 2, b, (from + to) / 2);
        } else if (from - to <= tuning.flapGap) {
          final (near, far) = a.right < b.left ? (a, b) : (b, a);
          _link(LinkKind.flap, near, near.right, far, far.left);
        }
      }
    }
  }

  double _linkCost(NavLink l, double speed, Doors? doors) => switch (l.kind) {
    LinkKind.door => doors != null && !doors.isOpen(l.door!) ? tuning.doorPushTime * speed : 0,
    LinkKind.stair => 0,
    LinkKind.flap => tuning.flapCost,
  };

  /// The cheapest way from [fromX] on [from] to where she best gets at
  /// [target]: the cheapest point that catches it, else the nearest point
  /// to it. Walking costs its px along x, a closed door
  /// [Tuning.doorPushTime] of walking at [speed], a flap [Tuning.flapCost].
  Route route(Seg from, double fromX, Vec target, {required double speed, Doors? doors}) {
    // Nodes: the start, then both ends of every link.
    final nodeSeg = <Seg>[from];
    final nodeX = <double>[from.clampX(fromX)];
    final linkNode = <int, (int, int)>{};
    for (final (i, l) in links.indexed) {
      nodeSeg
        ..add(l.a)
        ..add(l.b);
      nodeX
        ..add(l.xa)
        ..add(l.xb);
      linkNode[i] = (nodeSeg.length - 2, nodeSeg.length - 1);
    }
    final onSeg = <int, List<int>>{};
    for (var n = 0; n < nodeSeg.length; n++) {
      (onSeg[nodeSeg[n].index] ??= []).add(n);
    }
    final partner = <int, (int, NavLink)>{};
    for (final MapEntry(key: i, value: (a, b)) in linkNode.entries) {
      partner[a] = (b, links[i]);
      partner[b] = (a, links[i]);
    }

    final dist = List.filled(nodeSeg.length, double.infinity);
    final prev = List<int?>.filled(nodeSeg.length, null);
    final done = List.filled(nodeSeg.length, false);
    dist[0] = 0;
    while (true) {
      var n = -1;
      for (var i = 0; i < dist.length; i++) {
        if (!done[i] && dist[i].isFinite && (n < 0 || dist[i] < dist[n])) n = i;
      }
      if (n < 0) break;
      done[n] = true;
      void relax(int m, double cost) {
        if (dist[n] + cost < dist[m]) {
          dist[m] = dist[n] + cost;
          prev[m] = n;
        }
      }

      for (final m in onSeg[nodeSeg[n].index]!) {
        if (m != n) relax(m, (nodeX[m] - nodeX[n]).abs());
      }
      if (partner[n] case (final m, final l)) relax(m, _linkCost(l, speed, doors));
    }

    // The goal: on each reached segment, the point under or over the target.
    Seg? bestSeg;
    int? bestNode;
    var bestCost = double.infinity;
    var bestCatches = false;
    var bestDistance = double.infinity;
    for (final s in segs) {
      final reached = onSeg[s.index]?.where((m) => dist[m].isFinite).toList() ?? const [];
      if (reached.isEmpty) continue;
      final goal = s.at(target.x);
      final node = reached.reduce((a, b) => dist[a] + (nodeX[a] - goal.x).abs() <= dist[b] + (nodeX[b] - goal.x).abs() ? a : b);
      final cost = dist[node] + (nodeX[node] - goal.x).abs();
      final caught = catches(goal, target);
      final distance = math.sqrt(math.pow(goal.x - target.x, 2) + math.pow(goal.y - target.y, 2));
      final tie = (cost - bestCost).abs() < 1e-9 && bestSeg?.kind == SegKind.stair && s.kind != SegKind.stair;
      final better = caught
          ? !bestCatches || cost < bestCost - 1e-9 || tie
          : !bestCatches && (distance < bestDistance - 1e-9 || ((distance - bestDistance).abs() < 1e-9 && cost < bestCost));
      if (bestSeg == null || better) {
        bestSeg = s;
        bestNode = node;
        bestCost = cost;
        bestCatches = caught;
        bestDistance = distance;
      }
    }
    final goalSeg = bestSeg!;
    final goal = goalSeg.at(target.x);

    // Back from the goal's node to the start.
    final chain = <int>[];
    for (int? n = bestNode; n != null; n = prev[n]) {
      chain.add(n);
    }
    final path = chain.reversed.toList();
    final moves = <Move>[];
    final points = <Vec>[nodeSeg[0].at(nodeX[0])];
    for (var i = 1; i < path.length; i++) {
      final a = path[i - 1];
      final b = path[i];
      if (nodeSeg[a] == nodeSeg[b] && partner[a]?.$1 != b) {
        moves.add(WalkTo(nodeSeg[b], nodeX[b]));
      } else {
        final l = partner[a]!.$2;
        if (l.kind == LinkKind.flap) {
          moves.add(Flap(nodeSeg[b], nodeSeg[a].at(nodeX[a]), nodeSeg[b].at(nodeX[b])));
        } else {
          moves.add(Cross(nodeSeg[b]));
        }
      }
      points.add(nodeSeg[b].at(nodeX[b]));
    }
    moves.add(WalkTo(goalSeg, goal.x));
    points.add(goal);
    return Route(moves: moves, goal: goal, goalSeg: goalSeg, cost: bestCost, catches: bestCatches, points: points);
  }
}
