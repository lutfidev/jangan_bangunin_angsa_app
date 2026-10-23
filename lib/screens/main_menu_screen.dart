import 'dart:math';

import 'package:flutter/material.dart';

import '../art/art.dart';
import '../art/icons.dart';
import '../routes.dart';
import '../state/briefing_prefs.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import '../widgets/chunky_button.dart';
import '../widgets/hud.dart';
import '../widgets/outlined_text.dart';
import '../widgets/stage.dart';
import 'scene.dart';

/// `flutter run --dart-define=GREYBOX=true` adds a button into the greybox
/// house, until it replaces Night 3 (langkah 11).
const greyboxEntry = bool.fromEnvironment('GREYBOX');

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stage(
      background: Palette.midnight,
      children: [
        // Floorboards.
        Positioned(
          left: 0,
          top: 302,
          width: 844,
          height: 92,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              color: Palette.floor,
              border: Border(top: BorderSide(color: Palette.ink, width: 4)),
            ),
          ),
        ),
        box(0, 330, 844, 3, Palette.floorDark),
        box(0, 360, 844, 3, Palette.floorDark),

        // Moonlit window.
        at(
          660,
          34,
          Container(
            decoration: BoxDecoration(
              border: inkBorder(4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF16193A),
                border: Border.all(color: Palette.slate, width: 6),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          width: 140,
          height: 124,
        ),
        box(708, 52, 46, 46, const Color(0xFFF6E7B8), border: 3, oval: true),
        box(726, 38, 4, 112, Palette.slate),
        box(664, 92, 128, 4, Palette.slate),
        box(682, 110, 5, 5, Palette.moonlight, oval: true),
        box(770, 60, 4, 4, Palette.moonlight, oval: true),

        // Bedside lamp.
        at(
          600,
          120,
          const InlineSvg(
            '<path d="M196 6 L236 6 L250 40 L182 40 Z" fill="#FFC14D" stroke="#1C1A2B" stroke-width="4" stroke-linejoin="round"/>'
            '<path d="M186 40 L248 40 L300 186 L120 186 Z" fill="#FFC14D" opacity="0.13"/>'
            '<path d="M216 40 L216 186" stroke="#1C1A2B" stroke-width="5"/>',
            width: 244,
            height: 190,
          ),
        ),

        // Shelf with the gnome.
        box(500, 108, 92, 14, Palette.wood, border: 3, radius: 3),
        at(520, 66, const Prop(PropKind.gnome, size: 48)),

        // Gertrude asleep on her rug.
        box(556, 282, 240, 42, const Color(0xFFB8402E), border: 4, oval: true),
        at(588, 150, const Goose(width: 190, flip: true)),
        at(736, 176, const Snores()),

        // Milo, mid-heist.
        at(432, 120, const Prop(PropKind.toaster, size: 88)),
        at(424, 186, const Burglar(pose: BurglarPose.carry, width: 102)),
        at(404, 312, const Prop(PropKind.chicken, size: 54)),

        // Logo.
        at(
          36,
          26,
          Semantics(
            header: true,
            label: "Don't Wake the Goose",
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.rotate(
                  angle: -4 * pi / 180,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 2, 14, 4),
                    decoration: BoxDecoration(
                      color: Palette.alarmTomato,
                      border: inkBorder(),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Palette.ink, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Text(
                      "DON'T",
                      style: display(30, color: Palette.gooseWhite, height: 1.1),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedText(
                  'WAKE THE',
                  style: display(44, color: Palette.gooseWhite, height: 1),
                  drop: 4,
                ),
                OutlinedText(
                  'GOOSE',
                  style: display(
                    96,
                    color: Palette.lamp,
                    height: 0.95,
                  ).copyWith(letterSpacing: 1),
                  stroke: 4,
                  drop: 6,
                ),
              ],
            ),
          ),
        ),

        if (greyboxEntry)
          at(
            620,
            20,
            ChunkyButton.secondary(
              onPressed: () =>
                  Navigator.pushNamed(context, Routes.gameplay, arguments: BriefingPrefs.instance.tonight().withNight('house')),
              label: 'House',
              icon: GameIcon.moon,
              iconStroke: 2.5,
              height: 52,
              fontSize: 15,
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
          ),

        // Actions.
        at(
          36,
          228,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 14,
            children: [
              Row(
                spacing: 16,
                children: [
                  ChunkyButton.primary(
                    onPressed: () => Navigator.pushNamed(context, Routes.briefing),
                    label: 'PLAY',
                    icon: GameIcon.play,
                    iconSize: 22,
                    height: 66,
                    fontSize: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text('NEXT UP', style: hudLabel()),
                      Text(
                        'Night 3 · The Midnight Kitchen',
                        style: ui(15, color: Palette.gooseWhite),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                spacing: 10,
                children: [
                  ChunkyButton.secondary(
                    onPressed: () => Navigator.pushNamed(context, Routes.gameplay, arguments: BriefingPrefs.instance.tonight()),
                    label: 'Nights',
                    icon: GameIcon.moon,
                    iconStroke: 2.5,
                    height: 52,
                    fontSize: 15,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  ChunkyButton.secondary(
                    onPressed: () => Navigator.pushNamed(context, Routes.trophyRoom),
                    label: 'Trophy Room',
                    icon: GameIcon.trophy,
                    iconStroke: 2.5,
                    height: 52,
                    fontSize: 15,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  RoundIconButton(
                    onPressed: () => Navigator.pushNamed(context, Routes.settings),
                    semanticLabel: 'Settings',
                    icon: GameIcon.gear,
                    size: 46,
                    depth: 4,
                    iconStroke: 2.5,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
