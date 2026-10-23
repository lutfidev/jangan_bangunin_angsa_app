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
  Doors(this.level) : _open = {for (final d in level.doors) d.id: d.startsOpen};

  final Level level;
  final Map<String, bool> _open;
  final List<DoorMove> _moves = [];

  List<Door> get all => level.doors;

  bool isOpen(String id) => _open[id]!;

  /// The leaves of the closed doors, as walls.
  Iterable<Solid> get closedLeaves => [
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

  /// The stretch of the floor line [floorY] around [x] between the nearest
  /// closed doors, or the world's edges.
  ({double min, double max}) freeSpan(double x, {required double floorY}) {
    var min = 0.0;
    var max = level.width;
    for (final d in level.doors) {
      if (_open[d.id]! || d.floorY != floorY) continue;
      if (d.x < x && d.leaf.right > min) min = d.leaf.right;
      if (d.x > x && d.leaf.left < max) max = d.leaf.left;
    }
    return (min: min, max: max);
  }

  void open(String id, {bool byGoose = false}) => _set(id, true, byGoose: byGoose);

  void close(String id) => _set(id, false);

  void _set(String id, bool open, {bool byGoose = false}) {
    if (_open[id] == open) return;
    _open[id] = open;
    _moves.add(DoorMove(id, open: open, byGoose: byGoose));
  }

  List<DoorMove> takeMoves() {
    final moves = List.of(_moves);
    _moves.clear();
    return moves;
  }
}
