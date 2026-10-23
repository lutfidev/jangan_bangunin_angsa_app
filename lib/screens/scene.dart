import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../art/icons.dart';
import '../theme/palette.dart';
import '../theme/type.dart';

/// Shared set pieces for the house: walls, furniture, floor line and the
/// touch-control band beneath it.

/// Mirror Night: whether the room around this widget is drawn flipped.
class MirrorScope extends InheritedWidget {
  const MirrorScope({super.key, required this.mirrored, required super.child});

  final bool mirrored;

  static bool of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<MirrorScope>()?.mirrored ?? false;

  @override
  bool updateShouldNotify(MirrorScope oldWidget) => oldWidget.mirrored != mirrored;
}

/// Words in a flipped room: flips [child] back about its own centre, so it
/// still reads left to right where the room put it.
class Unmirror extends StatelessWidget {
  const Unmirror({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MirrorScope.of(context) ? Transform.flip(flipX: true, child: child) : child;
}

/// Inline SVG markup, clipped to its box like an HTML `<svg>`.
class InlineSvg extends StatelessWidget {
  const InlineSvg(this.body, {super.key, required this.width, required this.height});

  final String body;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SvgPicture.string(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $width $height">$body</svg>',
        width: width,
        height: height,
        excludeFromSemantics: true,
      ),
    );
  }
}

/// Degrees to radians, for the design's CSS rotations.
double deg(double degrees) => degrees * math.pi / 180;

Widget at(double left, double top, Widget child, {double? width, double? height}) =>
    Positioned(left: left, top: top, width: width, height: height, child: child);

/// A flat block at an absolute position; sizes are outer (border included).
Widget box(
  double left,
  double top,
  double width,
  double height,
  Color color, {
  double border = 0,
  Color borderColor = Palette.ink,
  double radius = 0,
  bool oval = false,
  double opacity = 1,
}) {
  final side = border == 0
      ? BorderSide.none
      : BorderSide(color: borderColor, width: border);
  Widget child = DecoratedBox(
    decoration: ShapeDecoration(
      color: color,
      shape: oval
          ? OvalBorder(side: side)
          : RoundedRectangleBorder(
              side: side,
              borderRadius: BorderRadius.circular(radius),
            ),
    ),
  );
  if (opacity != 1) child = Opacity(opacity: opacity, child: child);
  return Positioned(left: left, top: top, width: width, height: height, child: child);
}

Border inkBorder([double width = 3]) => Border.all(color: Palette.ink, width: width);

/// The kitchen's hanging lamp: cord, shade and its translucent beam.
const kitchenLampSvg =
    '<path d="M190 0 L190 40" stroke="#1C1A2B" stroke-width="3"/>'
    '<path d="M164 62 L216 62 L202 40 L178 40 Z" fill="#FFC14D" stroke="#1C1A2B" stroke-width="4" stroke-linejoin="round"/>'
    '<path d="M168 62 L212 62 L292 270 L80 270 Z" fill="#FFC14D" opacity="0.12"/>';

/// Gertrude's nest bed.
const nestSvg =
    '<path d="M4 6 Q80 22 156 6 L148 32 Q80 42 12 32 Z" fill="#C98A4B" stroke="#1C1A2B" stroke-width="4" stroke-linejoin="round"/>';

const nestStrawSvg =
    '<path d="M30 16 L28 34 M56 20 L55 38 M82 21 L82 39 M108 20 L109 38 M134 16 L136 34" stroke="#1C1A2B" stroke-width="2" opacity="0.45"/>';

/// Feathers puffing out of a caught Milo (330×200).
const featherPuffSvg =
    '<g fill="#FBF8F1" stroke="#1C1A2B" stroke-width="3" stroke-linejoin="round">'
    '<path d="M30 40 Q44 22 60 30 Q46 46 30 40 Z" transform="rotate(-20 45 35)"/>'
    '<path d="M270 30 Q286 14 300 24 Q286 38 270 30 Z" transform="rotate(25 285 26)"/>'
    '<path d="M300 140 Q314 124 326 134 Q312 148 300 140 Z"/>'
    '<path d="M10 150 Q24 134 38 144 Q24 158 10 150 Z" transform="rotate(30 24 146)"/>'
    '</g>';

/// Kitchen counter with cabinet below (the lit room on the left).
List<Widget> kitchenCounter({bool details = true}) => [
  box(24, 206, 250, 64, Palette.wood, border: 3),
  box(18, 200, 262, 12, Palette.counterTop, border: 3, radius: 4),
  if (details) ...[
    box(106, 214, 3, 50, Palette.ink),
    box(190, 214, 3, 50, Palette.ink),
    box(92, 234, 12, 12, Palette.lamp, border: 2, oval: true),
    box(198, 234, 12, 12, Palette.lamp, border: 2, oval: true),
  ],
];

/// Floor line plus the dark 104dp control band under it; [top] is the
/// floor line, which on a storey above is the slab down to the next room.
List<Widget> floorAndControlBand({bool trimBottom = true, bool rules = false, double width = 844, double top = 270}) => [
  Positioned(
    left: 0,
    top: top,
    width: width,
    height: 16,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Palette.floorTrim,
        border: Border(
          top: const BorderSide(color: Palette.ink, width: 4),
          bottom: trimBottom
              ? const BorderSide(color: Palette.ink, width: 3)
              : BorderSide.none,
        ),
      ),
    ),
  ),
  box(0, top + 16, width, 104, Palette.night),
  if (rules) ...[
    box(0, top + 48, width, 2, const Color(0xFF201E38)),
    box(0, top + 82, width, 2, const Color(0xFF201E38)),
  ],
];

/// Exit door at the right edge of the hall, ajar onto moonlight; [left] is
/// its frame's left edge, [floorY] the floor it stands on.
List<Widget> exitDoor({bool open = true, bool knob = false, double left = 762, double floorY = 270}) => [
  if (open) box(left, floorY - 128, 66, 128, Palette.moonlight, border: 4),
  box(open ? left + 10 : left, floorY - 128, open ? 56 : 66, 128, Palette.floorTrim, border: 4),
  if (knob) box(left + 20, floorY - 66, 13, 13, Palette.lamp, border: 2, oval: true),
];

/// Gertrude's rug, under her bed at [bedX] on the floor [floorY].
Widget rug(double bedX, {double floorY = 270}) => box(bedX - 92, floorY - 12, 190, 22, Palette.rug, border: 3, oval: true);

/// Her nest at [bedX], drawn in front of her and the egg.
Widget nest(double bedX, {double floorY = 270}) =>
    at(bedX - 78, floorY - 36, const InlineSvg(nestSvg + nestStrawSvg, width: 160, height: 40));

class ExitSign extends StatelessWidget {
  const ExitSign({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: Palette.calmMint,
        border: inkBorder(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          // In a mirrored room the arrow turns to the door; the word still reads.
          Unmirror(child: Text('EXIT', style: ui(12, weight: FontWeight.w800, letterSpacing: 1, height: 1))),
          const Glyph(GameIcon.arrow, size: 12, strokeWidth: 3.5),
        ],
      ),
    );
  }
}

/// Virtual joystick: 96dp ring and its thumb.
List<Widget> joystick({double knobLeft = 66, bool arrows = false, double opacity = 1}) {
  final parts = [
    box(30, 290, 94, 94, Palette.midnight, border: 3, borderColor: Palette.slate, oval: true),
    if (arrows)
      at(
        30,
        290,
        const InlineSvg(
          '<path d="M14 47 L20 42 L20 52 Z M80 47 L74 42 L74 52 Z M47 14 L42 20 L52 20 Z M47 80 L42 74 L52 74 Z" fill="#9FB4E8" opacity="0.7"/>',
          width: 94,
          height: 94,
        ),
      ),
    Positioned(
      left: knobLeft,
      top: 314,
      width: 46,
      height: 46,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Palette.gooseWhite,
          shape: BoxShape.circle,
          border: inkBorder(),
          boxShadow: opacity == 1
              ? const [BoxShadow(color: Palette.ink, offset: Offset(0, 3))]
              : null,
        ),
      ),
    ),
  ];
  if (opacity == 1) return parts;
  return [
    Positioned.fill(
      child: Opacity(
        opacity: opacity,
        child: Stack(children: parts),
      ),
    ),
  ];
}

/// A full-bleed tap target for a scene object (stand-in for game triggers).
class SceneHotspot extends StatelessWidget {
  const SceneHotspot({super.key, required this.label, required this.onTap, required this.child});

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: child),
    );
  }
}
