import 'package:flutter/material.dart';

import '../art/art.dart';
import '../theme/palette.dart';
import 'night_art.dart';
import 'scene.dart';

/// Night 3's room, The Midnight Kitchen: everything that never moves.

/// Walls, window, lamp, counter, bookshelf, side tables and the exit door.
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

  // Side tables, and the gnome in the hall.
  box(594, 236, 40, 34, Palette.wood, border: 3),
  box(708, 236, 44, 34, Palette.wood, border: 3),
  at(708, 196, const Prop(PropKind.gnome, size: 44)),

  // The way out.
  ...exitDoor(knob: true),
];

/// Gertrude's rug, under her bed.
Widget night3Rug() => box(410, 258, 190, 22, Palette.rug, border: 3, oval: true);

/// Her nest, drawn in front of her and the egg.
Widget night3Nest() => at(424, 234, const InlineSvg(nestSvg + nestStrawSvg, width: 160, height: 40));

/// The sparkle that marks the rubber chicken on top of the shelf.
Widget chickenSparkle() => at(
  368,
  62,
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
