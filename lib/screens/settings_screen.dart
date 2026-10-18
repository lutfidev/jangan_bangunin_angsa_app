import 'package:flutter/material.dart';

import '../art/art.dart';
import '../art/icons.dart';
import '../routes.dart';
import '../state/game_settings.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import '../widgets/chunky_button.dart';
import '../widgets/controls.dart';
import '../widgets/hud.dart';
import '../widgets/outlined_text.dart';
import '../widgets/stage.dart';
import 'scene.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = GameSettings.instance;
    return Stage(
      background: Palette.midnight,
      children: [
        Positioned(
          left: 0,
          top: 330,
          width: 844,
          height: 64,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              color: Palette.floor,
              border: Border(top: BorderSide(color: Palette.ink, width: 4)),
            ),
          ),
        ),
        at(
          24,
          20,
          Row(
            spacing: 14,
            children: [
              RoundIconButton(
                onPressed: () => Navigator.pop(context),
                semanticLabel: 'Back',
                icon: GameIcon.back,
              ),
              Semantics(
                header: true,
                child: OutlinedText(
                  'Settings',
                  style: display(34, color: Palette.gooseWhite),
                  drop: 4,
                ),
              ),
            ],
          ),
        ),
        at(
          24,
          84,
          PanelCard(
            width: 548,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            child: ListenableBuilder(
              listenable: settings,
              builder: (context, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SliderRow(
                    label: 'Sound effects',
                    value: settings.sfx,
                    onChanged: (v) => settings.sfx = v,
                  ),
                  SliderRow(
                    label: 'Music',
                    value: settings.music,
                    onChanged: (v) => settings.music = v,
                  ),
                  ToggleRow(
                    label: 'Haptic feedback',
                    hint: 'Buzz on noise, chase and grabs',
                    value: settings.haptics,
                    onChanged: (v) => settings.haptics = v,
                  ),
                  ToggleRow(
                    label: 'Reduce screen shake',
                    hint: 'Replaces the wake-up nudge with a flash',
                    value: settings.reduceShake,
                    onChanged: (v) => settings.reduceShake = v,
                  ),
                  ToggleRow(
                    label: 'Left-handed controls',
                    hint: 'Swap joystick and action buttons',
                    value: settings.leftHanded,
                    onChanged: (v) => settings.leftHanded = v,
                    divider: false,
                  ),
                ],
              ),
            ),
          ),
        ),
        at(
          608,
          84,
          SizedBox(
            width: 212,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                ChunkyButton.secondary(
                  onPressed: () => Routes.toMenu(context),
                  label: 'Main menu',
                  icon: GameIcon.home,
                  fontSize: 15,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
                  child: Text(
                    'Changes save instantly. Gertrude respects your preferences, if nothing else.',
                    style: ui(12, weight: FontWeight.w600, color: Palette.paleBlue, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
        at(636, 196, const Goose(width: 170)),
        at(
          616,
          218,
          Transform.rotate(
            angle: deg(-6),
            child: Pill(
              'SHHH',
              color: Palette.lamp,
              borderWidth: 3,
              radius: 6,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              textStyle: ui(12, weight: FontWeight.w800, letterSpacing: 1),
            ),
          ),
        ),
      ],
    );
  }
}
