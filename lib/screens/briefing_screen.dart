import 'package:flutter/material.dart';

import '../art/art.dart';
import '../art/icons.dart';
import '../game/heist.dart';
import '../game/tools.dart';
import '../game/unlocks.dart';
import '../routes.dart';
import '../state/briefing_prefs.dart';
import '../state/heist_log.dart';
import '../state/levels.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import '../widgets/chunky_button.dart';
import '../widgets/controls.dart';
import '../widgets/hud.dart';
import '../widgets/outlined_text.dart';
import '../widgets/stage.dart';
import 'heist_copy.dart';
import 'scene.dart';

typedef _Tool = ({Tool tool, PropKind kind, String name, String style, Color color, String desc, bool locked});

/// The four tools with [socks] earned; the kazoo waits for [Unlock.kazoo].
List<_Tool> _tools(int socks) {
  final kazoo = Unlock.kazoo.openWith(socks);
  return [
    (tool: Tool.socks, kind: PropKind.sock, name: 'Spare Socks ×3', style: 'TRICKSTER', color: Palette.lamp, desc: 'Hold Tool, drag to aim, release to throw. Hits whatever it lands on.', locked: false),
    (tool: Tool.mouse, kind: PropKind.mouse, name: 'Wind-up Mouse', style: 'TRICKSTER', color: Palette.lamp, desc: 'Set it down facing a direction. It walks until it bumps something.', locked: false),
    (tool: Tool.marbles, kind: PropKind.marbles, name: 'Bag of Marbles', style: 'CHAOS', color: Palette.alarmTomato, desc: 'Spill behind you mid-chase. Gertrude slips and loses 2 seconds.', locked: false),
    kazoo
        ? (tool: Tool.kazoo, kind: PropKind.kazoo, name: 'Kazoo', style: 'CHAOS', color: Palette.alarmTomato, desc: "One loud toot right where you stand. Wakes her if she's close.", locked: false)
        : (tool: Tool.kazoo, kind: PropKind.kazoo, name: 'Kazoo (locked)', style: 'CHAOS', color: Palette.alarmTomato, desc: 'Earn ${Unlock.kazoo.socks} socks to unlock. One loud toot right where you stand.', locked: true),
  ];
}

/// A modifier's switch label: its sock price shows until it is paid.
String _modLabel(String name, Unlock unlock, int socks) =>
    unlock.openWith(socks) ? name : '$name (${unlock.socks} sock${unlock.socks == 1 ? '' : 's'})';

/// Night briefing: heist goals, pick one tool, toggle modifiers. Picks are
/// kept in [BriefingPrefs]; socks earned open the locked ones.
class BriefingScreen extends StatelessWidget {
  const BriefingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = BriefingPrefs.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([prefs, HeistLog.instance]),
      builder: (context, _) => _build(context, prefs),
    );
  }

  Widget _build(BuildContext context, BriefingPrefs prefs) {
    final socks = HeistLog.instance.totalSocks;
    final tools = _tools(socks);
    final selected = tools.firstWhere((t) => t.tool == prefs.tool);
    final level = Levels.night3;
    final earned = HeistLog.instance.earned(level.id);
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
                Text(
                  'HEIST GOALS · ${earned.length} / ${level.goals.length} SOCKS',
                  style: hudLabel(color: Palette.mutedInk),
                ),
                for (final goal in level.goals) _GoalRow(goal, earned: earned.contains(goal.style)),
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
                    for (final tool in tools)
                      Expanded(child: _ToolTile(
                        tool: tool,
                        selected: tool.tool == prefs.tool,
                        onPressed: () => prefs.tool = tool.tool,
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
                  value: prefs.remix,
                  onChanged: (v) => prefs.remix = v,
                ),
                _ModifierButton(
                  label: _modLabel('Light Sleeper', Unlock.lightSleeper, socks),
                  value: prefs.lightSleeper && Unlock.lightSleeper.openWith(socks),
                  onChanged: Unlock.lightSleeper.openWith(socks) ? (v) => prefs.lightSleeper = v : null,
                ),
                _ModifierButton(
                  label: _modLabel('Mirror', Unlock.mirror, socks),
                  value: prefs.mirror && Unlock.mirror.openWith(socks),
                  onChanged: Unlock.mirror.openWith(socks) ? (v) => prefs.mirror = v : null,
                ),
              ],
            ),
          ),
        ),

        at(
          648,
          314,
          // A locked tool can be read about, not taken.
          Opacity(
            opacity: selected.locked ? 0.6 : 1,
            child: ChunkyButton.primary(
              onPressed: selected.locked
                  ? null
                  : () => Navigator.pushReplacementNamed(context, Routes.gameplay, arguments: prefs.tonight()),
              label: 'Sneak in',
              trailingIcon: GameIcon.arrow,
              iconSize: 18,
              width: 172,
              height: 56,
              fontSize: 22,
              padding: EdgeInsets.zero,
            ),
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
  const _GoalRow(this.goal, {required this.earned});

  final HeistGoal goal;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final look = styleLook(goal.style);
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
            look.tag,
            color: look.color,
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            textStyle: ui(10, weight: FontWeight.w800, color: look.text),
          ),
          Expanded(
            child: Text(goalBrief(goal), style: ui(13, height: 1.25)),
          ),
          Semantics(
            label: earned ? 'Sock earned' : 'Sock not yet earned',
            child: SockGlyph(fill: earned ? Palette.lamp : Palette.slate),
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
            spacing: 6,
            children: [
              // A label with its sock price shrinks to fit.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: ui(
                      12,
                      weight: FontWeight.w800,
                      color: locked ? const Color(0xFF6E6A90) : Palette.gooseWhite,
                    ),
                  ),
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
