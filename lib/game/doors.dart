import 'geom.dart';
import 'level.dart';

/// A door opening or closing, for the scene to draw.
class DoorMove {
  const DoorMove(this.doorId, {required this.open, this.byGoose = false});

  final String doorId;
  final bool open;

  /// She pushed it open; Milo didn't.
  final bool byGoose;
}

/// Which of the level's doors stand open tonight.
class Doors {
  Doors(this.level) : _open = {for (final d in level.doors) d.id: d.startsOpen} {
    _leaves = _closed();
  }

  final Level level;
  final Map<String, bool> _open;
  late List<Solid> _leaves;
  final List<DoorMove> _moves = [];

  List<Door> get all => level.doors;

  bool isOpen(String id) => _open[id]!;

  /// The leaves of the closed doors, as walls.
  Iterable<Solid> get closedLeaves => _leaves;

  List<Solid> _closed() => [
    for (final d in level.doors)
      if (!_open[d.id]!) Solid(d.leaf, Surface.wood),
  ];

  /// The first closed door on the floor line [floorY] ahead of a walk from
  /// [from] to [to] that it would run into, stopping [standOff] short of it.
  Door? closedAhead(double from, double to, double standOff, {required double floorY}) {
    Door? first;
    for (final d in level.doors) {
      if (_open[d.id]! || d.floorY != floorY) continue;
      final blocks = to > from ? from < d.x && to > d.x - standOff : from > d.x && to < d.x + standOff;
      if (blocks && (first == null || (d.x - from).abs() < (first.x - from).abs())) first = d;
    }
    return first;
  }

  /// The stretch of the floor line [floorY] around [x]: its room, and the
  /// rooms beyond each open door, up to a closed door's leaf or a wall.
  ({double min, double max}) freeSpan(double x, {required double floorY}) {
    final rooms = [for (final r in level.rooms) if (r.floorY == floorY) r];
    final start = rooms.where((r) => r.box.left <= x && x <= r.box.right).firstOrNull;
    if (start == null) return (min: 0, max: level.width);
    double edge(bool right) {
      var room = start;
      while (true) {
        final side = right ? room.box.right : room.box.left;
        final door = level.doors.where((d) => d.x == side && d.floorY == floorY).firstOrNull;
        if (door == null) return side;
        if (!_open[door.id]!) return right ? door.leaf.left : door.leaf.right;
        room = rooms.firstWhere((r) => r.id == (right ? door.right : door.left));
      }
    }

    return (min: edge(false), max: edge(true));
  }

  void open(String id, {bool byGoose = false}) => _set(id, true, byGoose: byGoose);

  void close(String id) => _set(id, false);

  void _set(String id, bool open, {bool byGoose = false}) {
    if (_open[id] == open) return;
    _open[id] = open;
    _leaves = _closed();
    _moves.add(DoorMove(id, open: open, byGoose: byGoose));
  }

  List<DoorMove> takeMoves() {
    final moves = List.of(_moves);
    _moves.clear();
    return moves;
  }
}
