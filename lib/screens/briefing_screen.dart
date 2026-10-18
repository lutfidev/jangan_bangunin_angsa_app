import 'package:flutter/material.dart';

import '../art/art.dart';
import '../art/icons.dart';
import '../routes.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import '../widgets/chunky_button.dart';
import '../widgets/controls.dart';
import '../widgets/hud.dart';
import '../widgets/outlined_text.dart';
import '../widgets/stage.dart';
import 'scene.dart';

typedef _Goal = ({String style, Color color, Color textColor, String text, bool earned});
typedef _Tool = ({PropKind kind, String name, String style, Color color, String desc, bool locked});

const List<_Goal> _goals = [
  (style: 'GHOST', color: Palette.calmMint, textColor: Palette.ink, text: 'Never let her turn suspicious', earned: false),
  (style: 'TRICK', color: Palette.lamp, textColor: Palette.ink, text: 'Lure her out of bed twice', earned: true),
  (style: 'CHAOS', color: Palette.alarmTomato, textColor: Palette.gooseWhite, text: 'Fire a 5-link chain', earned: false),
];

const List<_Tool> _tools = [
  (kind: PropKind.sock, name: 'Spare Socks ×3', style: 'TRICKSTER', color: Palette.lamp, desc: 'Hold Tool, drag to aim, release to throw. Hits whatever it lands on.', locked: false),
  (kind: PropKind.mouse, name: 'Wind-up Mouse', style: 'TRICKSTER', color: Palette.lamp, desc: 'Set it down facing a direction. It walks until it bumps something.', locked: false),
  (kind: PropKind.marbles, name: 'Bag of Marbles', style: 'CHAOS', color: Palette.alarmTomato, desc: 'Spill behind you mid-chase. Gertrude slips and loses 2 seconds.', locked: false),
  (kind: PropKind.kazoo, name: 'Kazoo (locked)', style: 'CHAOS', color: Palette.alarmTomato, desc: 'Earn 6 socks to unlock. One loud toot right where you stand.', locked: true),
];

/// Night briefing: heist goals, pick one tool, toggle modifiers.
class BriefingScreen extends StatefulWidget {
  const BriefingScreen({super.key});

  @override
  State<BriefingScreen> createState() => _BriefingScreenState();
}

class _BriefingScreenState extends State<BriefingScreen> {
  int _tool = 0;
  bool _remix = true;
  bool _lightSleeper = false;

  @override
  Widget build(BuildContext context) {
    final selected = _tools[_tool];
    return Stage(
      background: Palette.midnight,
      children: [
        at(
          24,
          16,
          Row(
            spacing: 14,
            children: [
              RoundIconButton(
                onPressed: () => Navigator.pop(context),
                semanticLabel: 'Back to main menu',
                icon: GameIcon.back,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NIGHT 3 · GUARDED LOOT: GOLDEN EGG', style: hudLabel().copyWith(height: 1.1)),
                  Semantics(
                    header: true,
                    child: OutlinedText(
                      'The Midnight Kitchen',
                      style: display(30, color: Palette.lamp, height: 1.1),
                      drop: 3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Heist goals.
        at(
          24,
          84,
          PanelCard(
            width: 292,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            radius: 18,
            borderWidth: 3,
            depth: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text('HEIST GOALS · 1 / 3 SOCKS', style: hudLabel(color: Palette.mutedInk)),
                for (final goal in _goals) _GoalRow(goal),
                Text(
                  'One style per run. Come back for the rest.',
                  style: ui(11, weight: FontWeight.w600, color: Palette.mutedInk),
                ),
              ],
            ),
          ),
        ),

        // Tool pick.
        at(
          332,
          84,
          SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                Text('PICK ONE TOOL', style: hudLabel()),
                Row(
                  spacing: 8,
                  children: [
                    for (var i = 0; i < _tools.length; i++)
                      Expanded(child: _ToolTile(
                        tool: _tools[i],
                        selected: i == _tool,
                        onPressed: () => setState(() => _tool = i),
                      )),
                  ],
                ),
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 92),
                  child: NightPlate(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(selected.name, style: display(18, color: Palette.gooseWhite)),
                            Pill(
                              selected.style,
                              color: selected.color,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                              textStyle: ui(10, weight: FontWeight.w800),
                            ),
                          ],
                        ),
                        Text(
                          selected.desc,
                          style: ui(12, weight: FontWeight.w600, color: Palette.paleBlue, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Modifiers.
        at(
          648,
          84,
          SizedBox(
            width: 172,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 6,
              children: [
                Text('MODIFIERS', style: hudLabel()),
                _ModifierButton(
                  label: 'Nightly Remix',
                  value: _remix,
                  onChanged: (v) => setState(() => _remix = v),
                ),
                _ModifierButton(
                  label: 'Light Sleeper',
                  value: _lightSleeper,
                  onChanged: (v) => setState(() => _lightSleeper = v),
                ),
                const _ModifierButton(label: 'Mirror (9 socks)', value: false),
              ],
            ),
          ),
        ),

        at(
          648,
          314,
          ChunkyButton.primary(
            onPressed: () => Navigator.pushReplacementNamed(context, Routes.gameplay),
            label: 'Sneak in',
            trailingIcon: GameIcon.arrow,
            iconSize: 18,
            width: 172,
            height: 56,
            fontSize: 22,
            padding: EdgeInsets.zero,
          ),
        ),

        // The guarded loot.
        at(332, 300, const Goose(width: 110)),
        at(404, 336, const Prop(PropKind.egg, size: 34)),
        at(
          456,
          320,
          Text(
            "She's sitting on it. You'll have to move her.",
            style: ui(12, color: Palette.paleBlue, height: 1.4),
          ),
          width: 176,
        ),
      ],
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow(this.goal);

  final _Goal goal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Palette.sand,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        spacing: 10,
        children: [
          Pill(
            goal.style,
            color: goal.color,
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            textStyle: ui(10, weight: FontWeight.w800, color: goal.textColor),
          ),
          Expanded(
            child: Text(goal.text, style: ui(13, height: 1.25)),
          ),
          Semantics(
            label: goal.earned ? 'Sock earned' : 'Sock not yet earned',
            child: SockGlyph(fill: goal.earned ? Palette.lamp : Palette.slate),
          ),
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({required this.tool, required this.selected, required this.onPressed});

  final _Tool tool;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: tool.locked ? 0.55 : 1,
      child: ChunkyButton(
        onPressed: onPressed,
        semanticLabel: tool.name,
        selected: selected,
        color: tool.locked ? Palette.duskWall : Palette.gooseWhite,
        height: 76,
        radius: 14,
        shadows: selected ? ringShadows() : null,
        child: Prop(tool.kind, size: 50),
      ),
    );
  }
}

class _ModifierButton extends StatelessWidget {
  const _ModifierButton({required this.label, required this.value, this.onChanged});

  final String label;
  final bool value;

  /// Null when the modifier is still locked.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final locked = onChanged == null;
    return Semantics(
      toggled: value,
      enabled: !locked,
      label: label,
      excludeSemantics: true,
      onTap: locked ? null : () => onChanged!(!value),
      child: GestureDetector(
        onTap: locked ? null : () => onChanged!(!value),
        child: Container(
          height: 40,
          padding: const EdgeInsets.only(left: 12, right: 8),
          decoration: BoxDecoration(
            color: Palette.night,
            border: Border.all(color: Palette.slate, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: ui(
                  12,
                  weight: FontWeight.w800,
                  color: locked ? const Color(0xFF6E6A90) : Palette.gooseWhite,
                ),
              ),
              ToggleSwitch(value: value, compact: true, offColor: Palette.slate),
            ],
          ),
        ),
      ),
    );
  }
}
