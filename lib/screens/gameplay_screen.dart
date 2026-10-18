import 'package:flutter/material.dart';

import '../art/art.dart';
import '../art/icons.dart';
import '../routes.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import '../widgets/chunky_button.dart';
import '../widgets/dashed_outline.dart';
import '../widgets/hud.dart';
import '../widgets/stage.dart';
import 'night_art.dart';
import 'scene.dart';

/// Landscape gameplay HUD over Night 3, The Midnight Kitchen.
class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  bool _sneak = true;

  @override
  Widget build(BuildContext context) {
    return Stage(
      background: Palette.duskWall,
      children: [
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

        // Counter with the glass, pot and the toaster in reach.
        box(24, 150, 250, 56, const Color(0xFFE9DCC2), opacity: 0.16),
        ...kitchenCounter(),
        at(44, 170, const Prop(PropKind.glass, size: 36)),
        at(88, 162, const Prop(PropKind.pot, size: 50)),
        at(
          172,
          132,
          const Opacity(
            opacity: 0.85,
            child: DashedOutline(color: Palette.lamp, oval: true),
          ),
          width: 92,
          height: 80,
        ),
        at(186, 146, const Prop(PropKind.toaster, size: 64)),
        at(182, 100, const PromptBubble('Grab')),

        // Bookshelf with the rubber chicken on top.
        box(316, 110, 76, 160, Palette.floor, border: 3),
        box(319, 160, 70, 3, Palette.ink),
        box(319, 212, 70, 3, Palette.ink),
        at(324, 126, const Books([
          (Palette.alarmTomato, 32.0, 0.0),
          (Palette.calmMint, 28.0, 0.0),
          (Palette.moonlight, 34.0, 0.0),
          (Palette.lamp, 26.0, 14.0),
        ])),
        at(324, 178, const Books([
          (Palette.lamp, 30.0, 0.0),
          (Color(0xFF4C5BA8), 30.0, 0.0),
          (Palette.alarmTomato, 26.0, 0.0),
        ])),
        at(330, 70, const Prop(PropKind.chicken, size: 46)),
        at(
          368,
          62,
          const InlineSvg(
            '<path d="M10 1 L12 8 L19 10 L12 12 L10 19 L8 12 L1 10 L8 8 Z" fill="#FFC14D" stroke="#1C1A2B" stroke-width="2" stroke-linejoin="round"/>',
            width: 20,
            height: 20,
          ),
        ),

        // Gertrude's ear zone, rug, nest and the Golden Egg.
        at(
          336,
          228,
          const Opacity(
            opacity: 0.4,
            child: DashedOutline(
              color: Palette.moonlight,
              strokeWidth: 2,
              oval: true,
              dash: 7,
              gap: 5,
            ),
          ),
          width: 344,
          height: 76,
        ),
        box(410, 258, 190, 22, Palette.rug, border: 3, oval: true),
        at(
          432,
          160,
          SceneHotspot(
            label: 'Gertrude, asleep',
            onTap: () => Navigator.pushNamed(context, Routes.chaosEscape),
            child: const Goose(width: 140),
          ),
        ),
        at(544, 206, const Prop(PropKind.egg, size: 34)),
        at(424, 234, const InlineSvg(nestSvg + nestStrawSvg, width: 160, height: 40)),
        at(446, 160, const Snores(reversed: true)),

        // Side tables: robot + clock, gnome in the hall.
        box(594, 236, 40, 34, Palette.wood, border: 3),
        at(594, 200, const Prop(PropKind.robot, size: 40)),
        at(612, 168, const Prop(PropKind.clock, size: 110)),
        box(708, 236, 44, 34, Palette.wood, border: 3),
        at(708, 196, const Prop(PropKind.gnome, size: 44)),

        // The way out.
        ...exitDoor(knob: true),
        at(
          758,
          108,
          SceneHotspot(
            label: 'Exit',
            onTap: () => Navigator.pushReplacementNamed(context, Routes.victory),
            child: const ExitSign(),
          ),
        ),

        // Milo, tiptoeing.
        at(236, 196, const Burglar(width: 60, flip: true)),
        at(
          240,
          256,
          const InlineSvg(
            '<path d="M8 14 Q4 8 8 2 M52 14 Q56 8 52 2" fill="none" stroke="#5CC9A7" stroke-width="2.5" stroke-linecap="round"/>',
            width: 60,
            height: 18,
          ),
        ),

        ...floorAndControlBand(rules: true),

        // HUD.
        at(
          14,
          12,
          NightPlate(
            padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
            radius: 16,
            depth: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LOOT', style: hudLabel(size: 10).copyWith(height: 1.1)),
                    Text('1/3', style: display(18, color: Palette.gooseWhite, height: 1.1)),
                  ],
                ),
                const LootSlot(kind: PropKind.toaster, state: LootState.stolen),
                const LootSlot(kind: PropKind.chicken, state: LootState.missing),
                const LootSlot(kind: PropKind.egg, state: LootState.missing),
              ],
            ),
          ),
        ),
        at(292, 14, const AlertMeter(value: 14)),
        at(
          782,
          12,
          RoundIconButton(
            onPressed: () => Navigator.pushNamed(context, Routes.pause),
            semanticLabel: 'Pause',
            child: const PauseBars(),
          ),
        ),
        at(
          14,
          70,
          Pill(
            'Lure her out of bed · 0/2',
            color: Palette.night,
            borderColor: Palette.slate,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            textStyle: ui(11, color: Palette.gooseWhite),
            leading: Text(
              'GOAL',
              style: ui(11, weight: FontWeight.w800, color: Palette.lamp, letterSpacing: 1),
            ),
          ),
        ),

        // Touch controls.
        ...joystick(arrows: true),
        at(
          596,
          316,
          _ToolButton(onPressed: () => Navigator.pushNamed(context, Routes.planView)),
        ),
        at(
          666,
          306,
          SneakButton(
            on: _sneak,
            onPressed: () => setState(() => _sneak = !_sneak),
          ),
        ),
        at(
          742,
          294,
          ActionButton(
            label: 'GRAB',
            semanticLabel: 'Grab toaster',
            icon: const Glyph(GameIcon.grab, size: 28, strokeWidth: 2.4),
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ChunkyButton(
            onPressed: onPressed,
            semanticLabel: 'Tool: spare sock, 3 left. Hold to aim and throw',
            width: 54,
            height: 54,
            depth: 3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SockGlyph(fill: Palette.lamp),
                Text('TOOL', style: ui(9, weight: FontWeight.w800, letterSpacing: 1, height: 1.1)),
              ],
            ),
          ),
          Positioned(
            right: -6,
            top: -6,
            child: IgnorePointer(
              child: Container(
                constraints: const BoxConstraints(minWidth: 22),
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Palette.ink,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('×3', style: ui(11, weight: FontWeight.w800, color: Palette.lamp)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sneak toggle: 56dp Hoodie Teal, mint ring when on.
class SneakButton extends StatelessWidget {
  const SneakButton({super.key, required this.on, required this.onPressed, this.showSock = true});

  final bool on;
  final VoidCallback? onPressed;
  final bool showSock;

  @override
  Widget build(BuildContext context) {
    return ChunkyButton(
      onPressed: onPressed,
      semanticLabel: 'Sneak',
      selected: on,
      color: Palette.hoodieTeal,
      width: 60,
      height: 60,
      depth: 3,
      shadows: on
          ? ringShadows(color: Palette.calmMint, width: 3, outline: 2, drop: 3)
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 1,
        children: [
          if (showSock) const SockGlyph(fill: Palette.calmMint, size: 24),
          Text(
            'SNEAK',
            style: ui(9, weight: FontWeight.w800, letterSpacing: 1, color: Palette.gooseWhite, height: 1.1),
          ),
        ],
      ),
    );
  }
}

/// The 76dp contextual Interact button.
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
    this.icon,
  });

  final String label;
  final String? semanticLabel;
  final Widget? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ChunkyButton(
      onPressed: onPressed,
      semanticLabel: semanticLabel ?? label,
      color: Palette.lamp,
      width: 78,
      height: 78,
      depth: 5,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 1,
        children: [
          ?icon,
          Text(label, style: ui(11, weight: FontWeight.w800, letterSpacing: 1, height: 1.1)),
        ],
      ),
    );
  }
}
