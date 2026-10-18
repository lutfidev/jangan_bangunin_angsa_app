import 'package:flutter/material.dart';

import '../art/art.dart';
import '../routes.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import '../widgets/chunky_button.dart';
import '../widgets/hud.dart';
import '../widgets/outlined_text.dart';
import '../widgets/stage.dart';
import 'gameplay_screen.dart';
import 'scene.dart';

/// Mid-chase: a deliberate 4-link chain distracts Gertrude while Milo runs
/// for the exit with all three loot.
class ChaosEscapeScreen extends StatelessWidget {
  const ChaosEscapeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stage(
      background: Palette.duskWall,
      children: [
        box(520, 0, 10, 270, Palette.wallShadow),
        box(530, 0, 314, 270, Palette.hallWall),

        // The chain: plank → clock → pot → robot, with loudness rings.
        at(
          0,
          60,
          const InlineSvg(
            '<circle cx="130" cy="140" r="40" fill="none" stroke="#F0533B" stroke-width="3"/>'
            '<circle cx="130" cy="140" r="64" fill="none" stroke="#F0533B" stroke-width="3" opacity="0.6"/>'
            '<circle cx="130" cy="140" r="88" fill="none" stroke="#F0533B" stroke-width="2.5" opacity="0.35"/>',
            width: 360,
            height: 220,
          ),
        ),
        at(76, 156, const Prop(PropKind.clock, size: 116)),
        at(24, 236, Transform.rotate(angle: deg(-30), child: const Prop(PropKind.pot, size: 40))),
        at(168, 234, Transform.rotate(angle: deg(-80), child: const Prop(PropKind.robot, size: 38))),
        at(228, 228, const Prop(PropKind.board, size: 56)),
        at(
          0,
          140,
          const InlineSvg(
            '<path d="M250 88 Q222 50 196 88" fill="none" stroke="#FFC14D" stroke-width="3" stroke-dasharray="4 5" stroke-linecap="round"/>'
            '<path d="M182 86 Q162 40 140 60" fill="none" stroke="#FF8A2A" stroke-width="3" stroke-dasharray="4 5" stroke-linecap="round"/>'
            '<path d="M118 60 Q80 30 50 88" fill="none" stroke="#F0533B" stroke-width="3" stroke-dasharray="4 5" stroke-linecap="round"/>',
            width: 290,
            height: 110,
          ),
        ),
        at(244, 200, const LinkBadge(1, color: Palette.lamp)),
        at(176, 196, const LinkBadge(2, color: Palette.beakOrange)),
        at(120, 136, const LinkBadge(3, color: Palette.alarmTomato, textColor: Palette.gooseWhite)),
        at(34, 206, const LinkBadge(4, color: Palette.alarmTomato, textColor: Palette.gooseWhite)),
        at(
          28,
          96,
          Transform.rotate(
            angle: deg(-8),
            child: OutlinedText('DONG ×3', style: display(30, color: Palette.alarmTomato)),
          ),
        ),

        // Gertrude, peeled off to the noise.
        at(
          290,
          150,
          SceneHotspot(
            label: 'Gertrude, distracted',
            onTap: () => Navigator.pushReplacementNamed(context, Routes.caught),
            child: const Goose(mood: GooseMood.awake, width: 150),
          ),
        ),
        at(
          318,
          102,
          Pill(
            'DISTRACTED · 4s',
            color: Palette.lamp,
            borderWidth: 3,
            padding: const EdgeInsets.fromLTRB(4, 3, 10, 3),
            textStyle: ui(12, weight: FontWeight.w800, letterSpacing: 1),
            leading: const InlineSvg(
              '<circle cx="12" cy="12" r="9" fill="#FBF8F1" stroke="#1C1A2B" stroke-width="2.5"/>'
              '<path d="M12 3 A9 9 0 0 1 20.5 15 L12 12 Z" fill="#F0533B"/>',
              width: 24,
              height: 24,
            ),
          ),
        ),

        // Milo legging it, dropping marbles.
        box(556, 230, 16, 16, Palette.calmMint, border: 2, oval: true),
        box(574, 254, 14, 14, Palette.moonlight, border: 2, oval: true),
        box(540, 256, 14, 14, Palette.lamp, border: 2, oval: true),
        at(
          566,
          196,
          const InlineSvg(
            '<path d="M4 10 H44 M14 26 H56 M4 42 H40" stroke="#FBF8F1" stroke-width="3" stroke-linecap="round" opacity="0.7"/>',
            width: 60,
            height: 50,
          ),
        ),
        at(640, 130, Transform.rotate(angle: deg(-10), child: const Prop(PropKind.egg, size: 40))),
        at(622, 196, const Burglar(pose: BurglarPose.panic, width: 60)),

        // Coat rack hide spot.
        box(700, 172, 10, 102, Palette.floor, border: 2),
        at(
          686,
          176,
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF4C5BA8),
              border: inkBorder(),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
                bottom: Radius.circular(4),
              ),
            ),
          ),
          width: 34,
          height: 54,
        ),
        at(
          684,
          146,
          Pill(
            'HIDE',
            radius: 6,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            textStyle: ui(10, weight: FontWeight.w800),
          ),
        ),
        ...exitDoor(),
        at(
          756,
          108,
          SceneHotspot(
            label: 'Exit',
            onTap: () => Navigator.pushReplacementNamed(context, Routes.victory),
            child: const ExitSign(),
          ),
        ),

        ...floorAndControlBand(),
        // Red chase frame.
        at(
          0,
          0,
          IgnorePointer(
            child: Opacity(
              opacity: 0.55,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Palette.alarmTomato, width: 6),
                ),
              ),
            ),
          ),
          width: 844,
          height: 286,
        ),

        // HUD.
        at(
          14,
          12,
          NightPlate(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            radius: 16,
            depth: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Text('LOOT', style: hudLabel(size: 10)),
                Text('3/3', style: display(18, color: Palette.calmMint)),
              ],
            ),
          ),
        ),
        at(
          290,
          10,
          Column(
            children: [
              Transform.rotate(
                angle: deg(-3),
                child: OutlinedText(
                  'CHAIN ×4!',
                  style: display(34, color: Palette.lamp, height: 1),
                  drop: 4,
                ),
              ),
              const SizedBox(height: 6),
              Pill(
                'CHAOS COMBO +1,200',
                color: Palette.alarmTomato,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                textStyle: ui(11, weight: FontWeight.w800, letterSpacing: 1, color: Palette.gooseWhite),
              ),
            ],
          ),
        ),
        at(
          600,
          18,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Palette.night,
              border: inkBorder(),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Container(
                  width: 70,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Palette.alarmTomato,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                Text(
                  'CHASE',
                  style: ui(10, weight: FontWeight.w800, letterSpacing: 1, color: Palette.alarmTomato),
                ),
              ],
            ),
          ),
        ),
        at(
          782,
          12,
          RoundIconButton(
            onPressed: () => Navigator.pushNamed(context, Routes.pause),
            semanticLabel: 'Pause',
            child: const PauseBars(),
          ),
        ),

        // Controls.
        ...joystick(knobLeft: 70),
        at(
          596,
          316,
          Opacity(
            opacity: 0.6,
            child: ChunkyButton(
              onPressed: null,
              semanticLabel: 'Tool: marbles, none left',
              color: Palette.slate,
              width: 54,
              height: 54,
              shadows: const [],
              child: const Prop(PropKind.marbles, size: 34),
            ),
          ),
        ),
        at(666, 306, SneakButton(on: false, showSock: false, onPressed: () {})),
        at(
          742,
          294,
          ActionButton(label: 'DROP', semanticLabel: 'Drop loot to run faster', onPressed: () {}),
        ),
        at(
          150,
          330,
          Pill(
            'Stepped on the loose plank on purpose. Totally the plan.',
            color: Palette.night,
            borderColor: Palette.slate,
            radius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            textStyle: ui(12, color: Palette.paleBlue),
          ),
        ),
      ],
    );
  }
}
