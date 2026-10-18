import 'package:flutter/material.dart';

import '../art/art.dart';
import '../art/icons.dart';
import '../routes.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import '../widgets/chunky_button.dart';
import '../widgets/hud.dart';
import '../widgets/stage.dart';
import 'scene.dart';

class PauseScreen extends StatelessWidget {
  const PauseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stage(
      background: Palette.duskWall,
      children: [
        // The night, frozen behind a dim.
        box(0, 0, 300, 270, Palette.lampRoom),
        ...kitchenCounter(details: false),
        at(186, 146, const Prop(PropKind.toaster, size: 64)),
        at(432, 160, const Goose(width: 140)),
        ...floorAndControlBand(trimBottom: false),
        box(0, 0, 844, 390, Palette.shade, opacity: 0.74),

        at(66, 180, const Goose(mood: GooseMood.suspicious, width: 190, flip: true)),
        at(
          92,
          132,
          Transform.rotate(
            angle: deg(-3),
            child: Pill(
              '…was that a pause button?',
              borderWidth: 3,
              radius: 14,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              textStyle: ui(13),
            ),
          ),
        ),

        at(
          302,
          52,
          PanelCard(
            width: 420,
            radius: 24,
            padding: const EdgeInsets.fromLTRB(28, 26, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: 18,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Semantics(header: true, child: Text('Paused', style: display(40, height: 1))),
                    Text(
                      'Night 3 · Loot 1/3 · Gertrude is still snoring. Probably.',
                      style: ui(15, weight: FontWeight.w600, color: Palette.bodyInk),
                    ),
                  ],
                ),
                ChunkyButton.primary(
                  onPressed: () => Navigator.pop(context),
                  label: 'Resume',
                  icon: GameIcon.play,
                ),
                Row(
                  spacing: 10,
                  children: [
                    _Tile(
                      label: 'Restart night',
                      icon: GameIcon.retry,
                      onPressed: () => Routes.restartNight(context),
                    ),
                    _Tile(
                      label: 'Settings',
                      icon: GameIcon.gear,
                      onPressed: () => Navigator.pushNamed(context, Routes.settings),
                    ),
                    _Tile(
                      label: 'Main menu',
                      icon: GameIcon.home,
                      onPressed: () => Routes.toMenu(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.icon, required this.onPressed});

  final String label;
  final GameIcon icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ChunkyButton(
        onPressed: onPressed,
        semanticLabel: label,
        height: 76,
        radius: 16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Glyph(icon, size: 22),
            Text(label, style: ui(13, weight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
