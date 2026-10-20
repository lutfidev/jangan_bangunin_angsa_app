/// The night's 2-D world: points, boxes and the surfaces Milo stands on.
///
/// Artboard px, y grows downward like the screen.
library;

class Vec {
  const Vec(this.x, this.y);

  final double x;
  final double y;

  @override
  bool operator ==(Object other) => other is Vec && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Vec($x, $y)';
}

/// An axis-aligned box.
class Box {
  const Box(this.left, this.top, this.right, this.bottom);

  Box.ltwh(double left, double top, double width, double height) : this(left, top, left + width, top + height);

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;

  /// Boxes that only share an edge do not overlap.
  bool overlaps(Box o) => left < o.right && o.left < right && top < o.bottom && o.top < bottom;

  bool contains(Vec p) => left <= p.x && p.x <= right && top <= p.y && p.y <= bottom;

  @override
  bool operator ==(Object other) =>
      other is Box && other.left == left && other.top == top && other.right == right && other.bottom == bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);

  @override
  String toString() => 'Box($left, $top, $right, $bottom)';
}

/// What a landing sounds on.
enum Surface { wood, tile, carpet }

/// A box that blocks from every side: the floor, walls, the ceiling.
class Solid {
  const Solid(this.box, this.surface);

  final Box box;
  final Surface surface;
}

/// A furniture top: stood on from above, passed through from below and the
/// sides, since the furniture is behind him. A [crawl] top is too low to
/// stand under the ceiling there: he crawls, silently, and can't jump.
class Platform {
  const Platform({
    required this.id,
    required this.from,
    required this.to,
    required this.y,
    required this.surface,
    this.crawl = false,
  });

  final String id;
  final double from;
  final double to;
  final double y;
  final Surface surface;
  final bool crawl;

  bool spans(double x) => from <= x && x <= to;
}

/// Everything solid in a level, plus where its floor line is.
class Geometry {
  const Geometry({required this.solids, required this.platforms, required this.floorY});

  final List<Solid> solids;
  final List<Platform> platforms;
  final double floorY;

  /// The platform whose top [p] stands on, within [tolerance] px.
  Platform? platformAt(Vec p, {double tolerance = 2}) {
    for (final pl in platforms) {
      if (pl.spans(p.x) && (p.y - pl.y).abs() <= tolerance) return pl;
    }
    return null;
  }

  /// Whether [p] stands on the floor line, over floor.
  bool onFloor(Vec p, {double tolerance = 2}) =>
      (p.y - floorY).abs() <= tolerance && floorSurfaceAt(p.x) != null;

  bool restsOnSurface(Vec p) => onFloor(p) || platformAt(p) != null;

  /// The surface of the floor solid under [x], if any.
  Surface? floorSurfaceAt(double x) {
    for (final s in solids) {
      if (s.box.top == floorY && s.box.left <= x && x <= s.box.right) return s.surface;
    }
    return null;
  }
}

/// Whether [p] lies inside (or on) the ellipse at [centre] with semi-axes
/// [rx] and [ry].
bool insideEllipse(Vec p, Vec centre, double rx, double ry) {
  final dx = (p.x - centre.x) / rx;
  final dy = (p.y - centre.y) / ry;
  return dx * dx + dy * dy <= 1;
}
