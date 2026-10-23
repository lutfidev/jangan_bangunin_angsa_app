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
/// doors" board): rooms, furniture tops, doors and props by object type.
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

  double get _floor => level.floorY;

  static Offset _anchor(Level level, Spot s) => switch (level.objects.where((o) => o.spot == s.id).firstOrNull?.type) {
    ObjectType.squeaker => Offset(s.x, level.floorY + 4),
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
          box(room.box.left, room.box.top, room.box.width, _floor - room.box.top, _roomColors[i % _roomColors.length]),
          at(room.box.left + 20, 112, Text(room.name.toUpperCase(), style: hudLabel(size: 10))),
        ],
      // Walls inside the house: the ones over the doors.
      for (final s in level.geometry.solids)
        if (s.box.top != _floor && s.box.left >= 0 && s.box.right <= level.width && seen(s.box.left, s.box.right))
          box(s.box.left, s.box.top, s.box.width, s.box.height, Palette.wallShadow),
      // Furniture bodies first, so stacked shelves keep their tops.
      for (final p in platforms)
        if (!p.crawl) box(p.from, p.y + 10, p.to - p.from, _floor - p.y - 10, Palette.floor, border: 3),
      for (final p in platforms) box(p.from, p.y, p.to - p.from, 10, Palette.wood, border: 3, radius: 3),
      for (final h in level.hideSpots)
        if (seen(h.x - 18, h.x + 18)) box(h.x - 18, _floor - 76, 36, 76, Palette.floor, border: 3, radius: 4),
      for (final d in level.doors)
        if (seen(d.x - 8, d.x + 14)) ...[
          if (sim.doors.isOpen(d.id)) ...[
            box(d.x - 8, _floor - Door.height, 16, Door.height, Palette.ink, opacity: 0.5),
            box(d.x + 8, _floor - Door.height, 6, Door.height, Palette.floorTrim, border: 2),
          ] else ...[
            box(d.x - 8, _floor - Door.height, 16, Door.height, Palette.floorTrim, border: 3),
            box(d.x - 4, _floor - 70, 8, 8, Palette.lamp, border: 2, oval: true),
          ],
        ],
      if (seen(level.exitX - 8, level.exitX + 58)) ...exitDoor(knob: true, left: level.exitX - 8),
    ];
  }

  @override
  List<Widget> foreground(NightSim sim) => [
    ...floorAndControlBand(rules: true, width: level.width),
    // Loose planks: a lighter board in the floor trim.
    for (final o in level.objects)
      if (o.type == ObjectType.squeaker)
        if (sim.chain.spotOf(o.id) case final spotId?)
          box(level.spots[spotId]!.x - 18, _floor + 1, 36, 9, const Color(0xFFA8735A), border: 2),
  ];

  @override
  Offset snapAnchor(String spotId) {
    final s = level.spots[spotId]!;
    return s.at.y == _floor ? Offset(s.x, _floor - 18) : Offset(s.x, s.at.y - 15);
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
  Offset hideTag(Vec hide) => Offset(hide.x - 19, _floor - 102);

  @override
  List<Widget> hiding(Vec hide) => [miloPeek(Offset(hide.x - 15, _floor - 62))];
}
