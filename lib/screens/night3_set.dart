import 'package:flutter/material.dart';

import '../art/art.dart';
import '../game/geom.dart';
import '../game/level.dart';
import '../game/night_sim.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import '../widgets/hud.dart';
import 'night_art.dart';
import 'night_art.dart' as art;
import 'night_set.dart';
import 'scene.dart';

/// Night 3's room, The Midnight Kitchen: everything that never moves.

/// Night 3 as a [NightSet]: its own art, at the artboard's positions.
class Night3Set implements NightSet {
  const Night3Set();

  @override
  List<Widget> backdrop(NightSim sim, double viewLeft, double viewRight) => night3Backdrop();

  @override
  List<Widget> foreground(NightSim sim) => [...floorAndControlBand(rules: true), loosePlank()];

  @override
  Map<String, Offset> get spotAnchors => art.spotAnchors;

  @override
  Offset snapAnchor(String spotId) => snapAnchors[spotId]!;

  @override
  PropKind? objectKind(String objectId) => objectArt[objectId]?.kind;

  @override
  ArtBox objectBox(String objectId, String spotId) => objectId == 'pot' ? potBoxAt(spotId) : objectArt[objectId]!.box;

  @override
  ArtBox lootBox(Loot loot) => art.lootBox(loot);

  @override
  Offset hideTag(Vec hide) => hideArt[hide.x]!.tag;

  @override
  List<Widget> hiding(Vec hide) => hidingMilo(hide.x);
}

/// Walls, window, lamp, counter, bookshelf, crawlway, side tables, coat
/// rack and the exit door.
List<Widget> night3Backdrop() => [
  // Rooms: lit kitchen, living room, hall.
  box(0, 0, 300, 270, Palette.lampRoom),
  box(300, 0, 10, 270, Palette.wallShadow),
  box(690, 0, 10, 270, Palette.wallShadow),
  box(700, 0, 144, 270, Palette.hallWall),

  // Kitchen window.
  at(
    40,
    62,
    Container(
      decoration: BoxDecoration(
        border: inkBorder(4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF16193A),
          border: Border.all(color: const Color(0xFF4A4680), width: 5),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
    width: 96,
    height: 86,
  ),
  box(92, 74, 30, 30, const Color(0xFFF6E7B8), border: 3, oval: true),
  box(82, 66, 4, 78, const Color(0xFF4A4680)),
  at(0, 0, const InlineSvg(kitchenLampSvg, width: 300, height: 270)),

  // Counter.
  box(24, 150, 250, 56, const Color(0xFFE9DCC2), opacity: 0.16),
  ...kitchenCounter(),

  // Bookshelf.
  box(316, 110, 76, 160, Palette.floor, border: 3),
  box(319, 160, 70, 3, Palette.ink),
  box(319, 212, 70, 3, Palette.ink),
  at(324, 126, const Books([...bookIcon, (Palette.lamp, 26.0, 14.0)])),
  at(324, 178, const Books([
    (Palette.lamp, 30.0, 0.0),
    (Color(0xFF4C5BA8), 30.0, 0.0),
    (Palette.alarmTomato, 26.0, 0.0),
  ])),
  ...crawlway(),

  // Side tables, and the gnome in the hall.
  box(594, 236, 40, 34, Palette.wood, border: 3),
  box(708, 236, 44, 34, Palette.wood, border: 3),
  at(708, 196, const Prop(PropKind.gnome, size: 44)),
  ...coatRack(),

  // The way out.
  ...exitDoor(knob: true),
];

/// The sparkle that marks the rubber chicken drawn at [box], up high.
Widget chickenSparkle(ArtBox box) => at(
  box.centerX + 15,
  box.top - 8,
  const InlineSvg(
    '<path d="M10 1 L12 8 L19 10 L12 12 L10 19 L8 12 L1 10 L8 8 Z" fill="#FFC14D" stroke="#1C1A2B" stroke-width="2" stroke-linejoin="round"/>',
    width: 20,
    height: 20,
  ),
);

/// The loose plank: a lighter board in the floor trim. Drawn after the
/// floor band. The HUD board doesn't show it; the chain board says "the
/// loose plank is a lighter colour".
Widget loosePlank() => box(622, 271, 36, 9, const Color(0xFFA8735A), border: 2);

/// Where the crawlway plank is drawn; it covers the level's crawlway.
const crawlwayArt = (left: 244.0, right: 426.0);

/// The cabinet-top crawlway: a plank from the counter's end to the top of
/// the bookshelf, with a bracket under its free left end.
List<Widget> crawlway() => [
  at(
    252,
    112,
    const InlineSvg(
      '<path d="M2 2 L14 2 L2 18 Z" fill="#5A3B2E" stroke="#1C1A2B" stroke-width="2.5" stroke-linejoin="round"/>',
      width: 16,
      height: 20,
    ),
  ),
  box(crawlwayArt.left, crawlwayTop, crawlwayArt.right - crawlwayArt.left, 10, Palette.wood, border: 3, radius: 3),
];

/// The coat rack in the hall (Chaos escape board), a hide spot.
List<Widget> coatRack() => [
  box(700, 172, 10, 102, Palette.floor, border: 2),
  at(
    686,
    176,
    Container(
      decoration: BoxDecoration(
        color: const Color(0xFF4C5BA8),
        border: inkBorder(),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10), bottom: Radius.circular(4)),
      ),
    ),
    width: 34,
    height: 54,
  ),
];

/// The white HIDE tag over a hide spot.
Widget hideTag(Offset at_) => at(
  at_.dx,
  at_.dy,
  Unmirror(child: Pill(
    'HIDE',
    radius: 6,
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    textStyle: ui(10, weight: FontWeight.w800),
  )),
);

/// Milo tucked into the hide spot at [x]: only his masked eyes show. The
/// kitchen cabinet door stands open a crack around them.
List<Widget> hidingMilo(double x) {
  final (:peek, :crack, tag: _) = hideArt[x]!;
  return [
    if (crack != null) box(crack.left, crack.top, crack.width, crack.height, Palette.ink),
    at(
      peek.dx,
      peek.dy,
      const InlineSvg(
        '<rect x="1.5" y="2" width="27" height="10" rx="4" fill="#F0533B" stroke="#1C1A2B" stroke-width="2.5"/>'
        '<circle cx="10" cy="7" r="3.5" fill="#FFFFFF" stroke="#1C1A2B" stroke-width="2"/>'
        '<circle cx="20" cy="7" r="3.5" fill="#FFFFFF" stroke="#1C1A2B" stroke-width="2"/>'
        '<circle cx="10.5" cy="7" r="1.6" fill="#1C1A2B"/>'
        '<circle cx="20.5" cy="7" r="1.6" fill="#1C1A2B"/>',
        width: 30,
        height: 14,
      ),
    ),
  ];
}
