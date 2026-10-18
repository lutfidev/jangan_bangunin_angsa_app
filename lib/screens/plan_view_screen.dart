import 'package:flutter/material.dart';

import '../art/art.dart';
import '../art/icons.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import '../widgets/chunky_button.dart';
import '../widgets/dashed_outline.dart';
import '../widgets/hud.dart';
import '../widgets/stage.dart';
import 'gameplay_screen.dart';
import 'scene.dart';

/// Plan view: standing still in Sneak dims the room and draws the predicted
/// chains while aiming a throw.
class PlanViewScreen extends StatelessWidget {
  const PlanViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stage(
      background: Palette.duskWall,
      children: [
        box(0, 0, 300, 270, Palette.lampRoom),
        box(300, 0, 10, 270, Palette.wallShadow),
        box(690, 0, 10, 270, Palette.wallShadow),
        ...kitchenCounter(details: false),
        at(44, 170, const Prop(PropKind.glass, size: 36)),
        at(88, 162, const Prop(PropKind.pot, size: 50)),
        at(186, 146, const Prop(PropKind.toaster, size: 64)),
        box(410, 258, 190, 22, Palette.rug, border: 3, oval: true),
        at(432, 160, const Goose(width: 140)),
        at(544, 206, const Prop(PropKind.egg, size: 34)),
        at(424, 234, const InlineSvg(nestSvg, width: 160, height: 40)),
        box(594, 236, 40, 34, Palette.wood, border: 3),
        at(594, 200, const Prop(PropKind.robot, size: 40)),
        at(612, 168, const Prop(PropKind.clock, size: 110)),
        ...exitDoor(open: false),
        ...floorAndControlBand(),
        box(0, 0, 844, 286, Palette.shade, opacity: 0.42),

        // Milo aiming, with the predicted chain overlaid.
        at(352, 196, const Burglar(width: 60, flip: true)),
        at(
          0,
          0,
          const InlineSvg(
            '<path d="M356 212 Q210 40 66 176" fill="none" stroke="#FFC14D" stroke-width="3.5" stroke-dasharray="2 9" stroke-linecap="round"/>'
            '<circle cx="62" cy="184" r="20" fill="none" stroke="#FFC14D" stroke-width="3"/>'
            '<path d="M62 158 L62 166 M62 202 L62 210 M36 184 L44 184 M80 184 L88 184" stroke="#FFC14D" stroke-width="3" stroke-linecap="round"/>'
            '<path d="M72 166 Q92 140 110 162" fill="none" stroke="#FF8A2A" stroke-width="3" stroke-dasharray="4 5" stroke-linecap="round"/>'
            '<path d="M614 214 Q640 190 652 214" fill="none" stroke="#9FB4E8" stroke-width="2.5" stroke-dasharray="3 5" stroke-linecap="round" opacity="0.8"/>'
            '<path d="M470 262 L160 262" fill="none" stroke="#FBF8F1" stroke-width="3" stroke-dasharray="6 8" stroke-linecap="round"/>'
            '<path d="M172 254 L158 262 L172 270" fill="none" stroke="#FBF8F1" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>',
            width: 844,
            height: 290,
          ),
        ),
        at(50, 136, const LinkBadge(1, color: Palette.lamp, size: 24)),
        at(102, 132, const LinkBadge(2, color: Palette.beakOrange, size: 24)),
        at(
          136,
          100,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Palette.gooseWhite,
              border: inkBorder(),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  'PREDICTED · LOUD',
                  style: ui(11, weight: FontWeight.w800, letterSpacing: 1, color: const Color(0xFFB85A00)),
                ),
                Text('Glass → Pot ×2, far from her bed', style: ui(12)),
              ],
            ),
          ),
        ),
        at(230, 240, const Pill("She'll sleepwalk here · ~6s away")),
        at(
          500,
          186,
          Pill('GUARDED', color: Palette.goldEgg, textStyle: ui(10, weight: FontWeight.w800)),
        ),
        at(
          268,
          226,
          const Opacity(
            opacity: 0.8,
            child: DashedOutline(color: Palette.lamp, oval: true, dash: 7, gap: 5),
          ),
          width: 30,
          height: 30,
        ),
        at(
          640,
          150,
          Pill(
            'walker → chimer',
            color: Palette.night,
            borderColor: Palette.moonlight,
            radius: 6,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            textStyle: ui(10, weight: FontWeight.w800, color: Palette.moonlight),
          ),
        ),

        // Mode banner.
        at(
          292,
          14,
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Palette.lamp,
              border: inkBorder(),
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [BoxShadow(color: Palette.ink, offset: Offset(0, 3))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                const Glyph(GameIcon.eye, size: 16),
                Text('PLAN VIEW', style: ui(12, weight: FontWeight.w800, letterSpacing: 1)),
                Text('still + Sneak shows the chains', style: ui(12, weight: FontWeight.w600)),
              ],
            ),
          ),
        ),

        // Controls: joystick idle, tool aiming.
        ...joystick(knobLeft: 54, opacity: 0.5),
        // Right-aligned so it ends beside the tool button rather than under it.
        Positioned(
          right: 258,
          top: 324,
          child: Pill(
            'Drag to aim · release to throw',
            color: Palette.night,
            borderColor: Palette.lamp,
            radius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            textStyle: ui(12, weight: FontWeight.w800, color: Palette.lamp),
          ),
        ),
        at(
          596,
          318,
          ChunkyButton(
            onPressed: () => Navigator.pop(context),
            semanticLabel: 'Tool: aiming spare sock',
            color: Palette.lamp,
            width: 54,
            height: 54,
            shadows: ringShadows(color: Palette.gooseWhite, width: 4, outline: 3, drop: 0),
            child: const SockGlyph(fill: Palette.gooseWhite, size: 24),
          ),
        ),
        at(
          666,
          306,
          SneakButton(on: true, showSock: false, onPressed: () => Navigator.pop(context)),
        ),
        at(
          742,
          294,
          const Opacity(
            opacity: 0.55,
            child: ActionButton(label: 'MOVE POT', onPressed: null),
          ),
        ),
      ],
    );
  }
}
