import 'package:flutter/material.dart';

import '../art/art.dart';
import '../game/geom.dart';
import '../game/level.dart';
import '../game/night_sim.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import 'night3_set.dart';
import 'night_art.dart';
import 'night_set.dart';
import 'scene.dart';

/// A house with no art yet, drawn from its level ("New · House camera &
/// doors" board): rooms on every storey, furniture tops, doors, stairs,
/// vents and props by object type.
class GreyboxSet implements NightSet {
  GreyboxSet(this.level)
    : spotAnchors = {
        for (final s in level.spots.values) s.id: _anchor(level, s),
      };

  final Level level;

  @override
  final Map<String, Offset> spotAnchors;

  static const _roomColors = [Palette.lampRoom, Palette.duskWall, Palette.hallWall];

  /// Pieces this far outside the view are still built, so nothing pops in.
  static const _margin = 100.0;

  static Offset _anchor(Level level, Spot s) => switch (level.objects.where((o) => o.spot == s.id).firstOrNull?.type) {
    ObjectType.squeaker => Offset(s.x, s.at.y + 4),
    ObjectType.chimer => Offset(s.x, s.at.y - 47),
    _ => Offset(s.x, s.at.y - 16),
  };

  ObjectType _type(String objectId) => level.objects.firstWhere((o) => o.id == objectId).type;

  @override
  List<Widget> backdrop(NightSim sim, double viewLeft, double viewRight) {
    bool seen(double left, double right) => right >= viewLeft - _margin && left <= viewRight + _margin;
    final platforms = level.geometry.platforms.where((p) => seen(p.from, p.to));
    return [
      for (final (i, room) in level.rooms.indexed)
        if (seen(room.box.left, room.box.right)) ...[
          box(room.box.left, room.box.top, room.box.width, room.box.height, _roomColors[i % _roomColors.length]),
          at(room.box.left + 20, room.box.top + 112, Text(room.name.toUpperCase(), style: hudLabel(size: 10))),
        ],
      // Walls inside the house: over the doors, and between rooms that
      // never touch.
      for (final s in level.geometry.solids)
        if (!level.geometry.floors.contains(s.box.top) &&
            s.box.top >= 0 &&
            s.box.left >= 0 &&
            s.box.right <= level.width &&
            seen(s.box.left, s.box.right))
          box(s.box.left, s.box.top, s.box.width, s.box.height, Palette.wallShadow),
      // Furniture bodies first, so stacked shelves keep their tops.
      for (final p in platforms)
        if (!p.crawl)
          box(p.from, p.y + 10, p.to - p.from, level.floorOf(Vec(p.from, p.y)) - p.y - 10, Palette.floor, border: 3),
      for (final p in platforms) box(p.from, p.y, p.to - p.from, 10, Palette.wood, border: 3, radius: 3),
      for (final h in level.hideSpots)
        if (seen(h.x - 18, h.x + 18)) box(h.x - 18, h.y - 76, 36, 76, Palette.floor, border: 3, radius: 4),
      for (final d in level.doors)
        if (seen(d.x - 8, d.x + 14)) ...[
          if (sim.doors.isOpen(d.id)) ...[
            box(d.x - 8, d.floorY - Door.height, 16, Door.height, Palette.ink, opacity: 0.5),
            box(d.x + 8, d.floorY - Door.height, 6, Door.height, Palette.floorTrim, border: 2),
          ] else ...[
            box(d.x - 8, d.floorY - Door.height, 16, Door.height, Palette.floorTrim, border: 3),
            box(d.x - 4, d.floorY - 70, 8, 8, Palette.lamp, border: 2, oval: true),
          ],
        ],
      // Vent mouths: a grille on the wall just over the floor.
      for (final v in level.vents)
        for (final m in [v.from, v.to])
          if (seen(m.x - 15, m.x + 15)) ...ventGrille(m),
      if (seen(level.exitX - 8, level.exitX + 58)) ...exitDoor(knob: true, left: level.exitX - 8, floorY: level.exit.y),
    ];
  }

  /// A vent mouth's grille at [mouth]: 30×22, ink, three moonlight bars.
  static List<Widget> ventGrille(Vec mouth) => [
    box(mouth.x - 15, mouth.y - 30, 30, 22, Palette.ink, radius: 3),
    for (final dy in const [5.0, 10.0, 15.0]) box(mouth.x - 10, mouth.y - 30 + dy, 20, 3, Palette.moonlight),
  ];

  @override
  List<Widget> foreground(NightSim sim) => [
    // Every storey's floor, drawn like the control band.
    for (final y in level.geometry.floors) ...floorAndControlBand(rules: true, width: level.width, top: y),
    // Loose planks: a lighter board in the floor trim.
    for (final o in level.objects)
      if (o.type == ObjectType.squeaker)
        if (sim.chain.spotOf(o.id) case final spotId?)
          box(level.spots[spotId]!.x - 18, level.spots[spotId]!.at.y + 1, 36, 9, const Color(0xFFA8735A), border: 2),
    // Stairs and ducts run through the floors, so they go over them.
    if (level.stairs.isNotEmpty || level.vents.isNotEmpty)
      Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _ThroughFloors(level)))),
  ];

  @override
  Offset snapAnchor(String spotId) {
    final s = level.spots[spotId]!;
    return level.geometry.platformAt(s.at) == null ? Offset(s.x, s.at.y - 18) : Offset(s.x, s.at.y - 15);
  }

  @override
  PropKind? objectKind(String objectId) => switch (_type(objectId)) {
    ObjectType.tipper => PropKind.glass,
    ObjectType.amplifier => PropKind.pot,
    ObjectType.walker => PropKind.robot,
    ObjectType.chimer => PropKind.clock,
    ObjectType.roller => PropKind.marbles,
    ObjectType.squeaker => null,
  };

  @override
  ArtBox objectBox(String objectId, String spotId) {
    final at = level.spots[spotId]!.at;
    return switch (_type(objectId)) {
      ObjectType.chimer => ArtBox(at.x - 55, at.y - 102, 110),
      final type => () {
        final size = switch (type) {
          ObjectType.amplifier => 50.0,
          ObjectType.walker => 40.0,
          _ => 36.0,
        };
        return ArtBox(at.x - size / 2, at.y - size + 6, size);
      }(),
    };
  }

  @override
  ArtBox lootBox(Loot loot) {
    final size = lootArt[loot.id]?.size ?? 40;
    // The guarded loot sits up in her nest.
    return ArtBox(loot.x - size / 2, loot.guarded ? loot.y - 64 : loot.y - size + 6, size);
  }

  @override
  Offset hideTag(Vec hide) => Offset(hide.x - 19, hide.y - 102);

  @override
  List<Widget> hiding(Vec hide) => [miloPeek(Offset(hide.x - 15, hide.y - 62))];
}

/// Stairs as a wood stringer with a tread every 30 px, and vent ducts as a
/// dim band between their grilles.
class _ThroughFloors extends CustomPainter {
  _ThroughFloors(this.level);

  final Level level;

  @override
  void paint(Canvas canvas, Size size) {
    final duct = Paint()
      ..strokeWidth = 24
      ..color = Palette.ink.withValues(alpha: 0.35);
    for (final v in level.vents) {
      canvas.drawLine(Offset(v.from.x, v.from.y - 19), Offset(v.to.x, v.to.y - 19), duct);
    }
    final edge = Paint()
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = Palette.ink;
    final wood = Paint()
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = Palette.wood;
    final tread = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = Palette.ink;
    for (final s in level.stairs) {
      final a = Offset(s.bottom.x, s.bottom.y);
      final b = Offset(s.top.x, s.top.y);
      canvas
        ..drawLine(a, b, edge)
        ..drawLine(a, b, wood);
      final length = (b - a).distance;
      for (var d = 15.0; d < length; d += 30) {
        final p = Offset.lerp(a, b, d / length)!;
        canvas.drawLine(p, p + const Offset(10, 0), tread);
      }
    }
  }

  @override
  bool shouldRepaint(_ThroughFloors old) => old.level != level;
}

