import 'package:flutter/widgets.dart';

import '../art/art.dart';
import '../game/geom.dart';
import '../game/level.dart';
import '../game/night_sim.dart';
import 'night_art.dart';
import 'night_set.dart';

/// A house with no art yet, drawn from its level: rooms, furniture tops,
/// doors and props by object type.
class GreyboxSet implements NightSet {
  GreyboxSet(this.level);

  final Level level;

  @override
  List<Widget> backdrop(NightSim sim, double viewLeft, double viewRight) => throw UnimplementedError();

  @override
  List<Widget> foreground(NightSim sim) => throw UnimplementedError();

  @override
  Map<String, Offset> get spotAnchors => throw UnimplementedError();

  @override
  Offset snapAnchor(String spotId) => throw UnimplementedError();

  @override
  PropKind? objectKind(String objectId) => throw UnimplementedError();

  @override
  ArtBox objectBox(String objectId, String spotId) => throw UnimplementedError();

  @override
  ArtBox lootBox(Loot loot) => throw UnimplementedError();

  @override
  Offset hideTag(Vec hide) => throw UnimplementedError();

  @override
  List<Widget> hiding(Vec hide) => throw UnimplementedError();
}
