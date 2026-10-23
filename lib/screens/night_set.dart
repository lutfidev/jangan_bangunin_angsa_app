import 'package:flutter/widgets.dart';

import '../art/art.dart';
import '../game/geom.dart';
import '../game/level.dart';
import '../game/night_sim.dart';
import 'greybox_set.dart';
import 'night3_set.dart';
import 'night_art.dart';

/// How a night's house is drawn: its set pieces and where each sim id
/// stands on the artboard. Night 3 has its own art; anything else is
/// greybox, drawn from the level's geometry.
abstract interface class NightSet {
  factory NightSet.of(Level level) => level.id == 'night3' ? const Night3Set() : GreyboxSet(level);

  /// Behind everything: walls, furniture, doors, the exit door. Only what
  /// lies within world x [viewLeft]..[viewRight] needs building.
  List<Widget> backdrop(NightSim sim, double viewLeft, double viewRight);

  /// Over the room, under the effects: the floor trim, the control band and
  /// loose planks.
  List<Widget> foreground(NightSim sim);

  /// Where each spot's rings, badges and Wind bubble go.
  Map<String, Offset> get spotAnchors;

  /// The centre of a free snap spot's glowing circle.
  Offset snapAnchor(String spotId);

  /// The prop an object is drawn as, or null when the set draws it (the
  /// books, the loose plank).
  PropKind? objectKind(String objectId);

  /// Where [objectId] stands on [spotId].
  ArtBox objectBox(String objectId, String spotId);

  ArtBox lootBox(Loot loot);

  /// Where the HIDE tag over [hide] goes.
  Offset hideTag(Vec hide);

  /// Milo tucked into [hide].
  List<Widget> hiding(Vec hide);
}
