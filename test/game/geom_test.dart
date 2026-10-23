import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/geom.dart';

/// Night 3's floor and furniture tops, as the v2 level lays them out.
Geometry kitchen() => const Geometry(
  floors: [270],
  solids: [
    Solid(Box(0, 270, 300, 390), Surface.tile),
    Solid(Box(300, 270, 410, 390), Surface.wood),
    Solid(Box(410, 270, 600, 390), Surface.carpet),
    Solid(Box(600, 270, 844, 390), Surface.wood),
  ],
  platforms: [
    Platform(id: 'counter', from: 18, to: 280, y: 200, surface: Surface.tile),
    Platform(id: 'crawlPlank', from: 244, to: 426, y: 106, surface: Surface.wood, crawl: true),
  ],
);

void main() {
  test('boxes that only share an edge do not overlap', () {
    const a = Box(0, 0, 10, 10);
    expect(a.overlaps(const Box(10, 0, 20, 10)), isFalse);
    expect(a.overlaps(const Box(0, 10, 10, 20)), isFalse);
    expect(a.overlaps(const Box(9, 9, 20, 20)), isTrue);
  });

  test('Box.ltwh and its size', () {
    final b = Box.ltwh(300, 270, 110, 120);
    expect(b, const Box(300, 270, 410, 390));
    expect(b.width, 110);
    expect(b.height, 120);
    expect(b.contains(const Vec(300, 270)), isTrue);
    expect(b.contains(const Vec(411, 270)), isFalse);
  });

  test('a platform spans both of its ends', () {
    const counter = Platform(id: 'counter', from: 18, to: 280, y: 200, surface: Surface.tile);
    expect(counter.spans(18), isTrue);
    expect(counter.spans(280), isTrue);
    expect(counter.spans(281), isFalse);
    expect(counter.spans(17), isFalse);
  });

  test('inside an ellipse, edges included', () {
    const c = Vec(0, 0);
    expect(insideEllipse(const Vec(172, 0), c, 172, 38), isTrue);
    expect(insideEllipse(const Vec(173, 0), c, 172, 38), isFalse);
    expect(insideEllipse(const Vec(0, 38), c, 172, 38), isTrue);
    expect(insideEllipse(const Vec(0, 39), c, 172, 38), isFalse);
  });

  test('points rest on the floor or on a platform top', () {
    final g = kitchen();
    expect(g.restsOnSurface(const Vec(353, 106)), isTrue);
    expect(g.restsOnSurface(const Vec(353, 150)), isFalse);
    expect(g.restsOnSurface(const Vec(500, 270)), isTrue);
    expect(g.restsOnSurface(const Vec(113, 200)), isTrue);
    expect(g.platformAt(const Vec(353, 107))?.id, 'crawlPlank');
    expect(g.platformAt(const Vec(500, 106)), isNull);
    expect(g.onFloor(const Vec(10, 271)), isTrue);
    expect(g.onFloor(const Vec(10, 200)), isFalse);
  });

  test('the floor surface under an x', () {
    final g = kitchen();
    expect(g.floorSurfaceAt(100, 270), Surface.tile);
    expect(g.floorSurfaceAt(500, 270), Surface.carpet);
    expect(g.floorSurfaceAt(700, 270), Surface.wood);
    expect(g.floorSurfaceAt(900, 270), isNull);
    expect(g.floorSurfaceAt(100, 200), isNull);
  });

  test('every floor line is a floor', () {
    const g = Geometry(
      floors: [270, 660],
      solids: [Solid(Box(0, 270, 844, 390), Surface.wood), Solid(Box(0, 660, 844, 780), Surface.tile)],
      platforms: [],
    );
    expect(g.onFloor(const Vec(50, 660)), isTrue);
    expect(g.onFloor(const Vec(50, 270)), isTrue);
    expect(g.onFloor(const Vec(50, 390)), isFalse);
    expect(g.floorSurfaceAt(50, 660), Surface.tile);
  });

  test('a stair runs from its bottom end up to its top end', () {
    const s = Stair(id: 's', bottom: Vec(100, 660), top: Vec(300, 270));
    expect(s.left, 100);
    expect(s.right, 300);
    expect(s.yAt(100), 660);
    expect(s.yAt(300), 270);
    expect(s.yAt(200), 465);
    expect(s.spans(301), isFalse);
    const back = Stair(id: 'b', bottom: Vec(300, 660), top: Vec(100, 270));
    expect(back.left, 100);
    expect(back.yAt(100), 270);
  });
}
