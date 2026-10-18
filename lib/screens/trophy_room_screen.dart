import 'package:flutter/material.dart';

import '../art/art.dart';
import '../art/icons.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import '../widgets/chunky_button.dart';
import '../widgets/hud.dart';
import '../widgets/outlined_text.dart';
import '../widgets/stage.dart';
import 'scene.dart';

typedef _Trophy = ({PropKind kind, String short, String name, String tag, String desc, String how});

const List<_Trophy> _trophies = [
  (kind: PropKind.toilet, short: 'Golden Toilet', name: 'Golden Toilet Trophy', tag: 'LEGENDARY · HEAVY', desc: 'For excellence in sitting. Gertrude polished it every morning. She will notice.', how: 'Stolen on Night 5 · The Upstairs Loo'),
  (kind: PropKind.toaster, short: 'Mega Toaster', name: 'Oversized Toaster', tag: 'HEAVY · SLOWS YOU DOWN', desc: 'Toasts four slices and one burglar’s dignity. Weighs about as much as a small fridge.', how: 'Stolen on Night 3 · The Midnight Kitchen'),
  (kind: PropKind.chicken, short: 'Rubber Chicken', name: 'Rubber Chicken', tag: 'LIGHT · SQUEAKS IF YOU RUN', desc: 'Squeaks if you so much as look at it. Do not squeeze. Do not sprint.', how: 'Stolen on Night 3 · The Midnight Kitchen'),
  (kind: PropKind.gnome, short: 'Shifty Gnome', name: 'Suspicious Garden Gnome', tag: 'LIGHT · ALWAYS WATCHING', desc: 'Was here before you arrived. Will be here after you leave. Saw everything.', how: 'Stolen on Night 2 · The Hallway'),
  (kind: PropKind.duck, short: 'Duck Trophy', name: 'Duck-Shaped Trophy', tag: 'RARE · LIGHT', desc: 'First place, Duck Look-Alike Contest. Gertrude came second and has never recovered.', how: 'Earned: 3-sock silent run on Night 1'),
  (kind: PropKind.locked, short: '???', name: 'Locked', tag: 'NOT YET PILFERED', desc: 'Something heavy is wrapped in a tea towel upstairs. It ticks.', how: 'Finish Night 4 without the goose ever turning suspicious'),
];

class TrophyRoomScreen extends StatefulWidget {
  const TrophyRoomScreen({super.key});

  @override
  State<TrophyRoomScreen> createState() => _TrophyRoomScreenState();
}

class _TrophyRoomScreenState extends State<TrophyRoomScreen> {
  int _picked = 1;

  @override
  Widget build(BuildContext context) {
    final sel = _trophies[_picked];
    return Stage(
      background: Palette.duskWall,
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
              Semantics(
                header: true,
                child: OutlinedText(
                  'Trophy Room',
                  style: display(32, color: Palette.lamp),
                  drop: 4,
                ),
              ),
              Pill(
                '5 / 12 pilfered',
                color: Palette.night,
                borderColor: Palette.slate,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                textStyle: ui(12, weight: FontWeight.w800, color: Palette.gooseWhite),
              ),
            ],
          ),
        ),

        // Shelf.
        at(
          24,
          80,
          SizedBox(
            width: 470,
            child: Column(
              spacing: 26,
              children: [
                for (var row = 0; row < 2; row++)
                  Row(
                    spacing: 14,
                    children: [
                      for (var i = row * 3; i < row * 3 + 3; i++)
                        Expanded(
                          child: _TrophyTile(
                            trophy: _trophies[i],
                            selected: i == _picked,
                            onPressed: () => setState(() => _picked = i),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),

        // Detail card.
        at(
          516,
          16,
          PanelCard(
            width: 306,
            height: 356,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                // Sized so the longest entry (two-line name, three-line
                // blurb, two-line "how") still fits the card.
                Container(
                  height: 112,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Palette.parchment,
                    border: inkBorder(),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Prop(sel.kind, size: 100),
                ),
                Text(
                  sel.tag,
                  style: hudLabel(color: const Color(0xFF6A6480), spacing: 1.4),
                ),
                Text(sel.name, style: display(24, height: 1.05)),
                Text(
                  sel.desc,
                  style: ui(14, weight: FontWeight.w600, color: const Color(0xFF3A3750), height: 1.4),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Palette.sand,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    spacing: 8,
                    children: [
                      const Glyph(GameIcon.moon, size: 16),
                      Expanded(child: Text(sel.how, style: ui(12))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TrophyTile extends StatelessWidget {
  const _TrophyTile({required this.trophy, required this.selected, required this.onPressed});

  final _Trophy trophy;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ChunkyButton(
      onPressed: onPressed,
      semanticLabel: trophy.name,
      selected: selected,
      color: trophy.kind == PropKind.locked ? Palette.midnight : Palette.lampRoom,
      height: 118,
      radius: 16,
      shadows: selected ? ringShadows() : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 4,
          children: [
            Prop(trophy.kind, size: 70),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 4, bottom: 6),
              decoration: const BoxDecoration(
                color: Palette.wood,
                border: Border(top: BorderSide(color: Palette.ink, width: 3)),
              ),
              child: Text(
                trophy.short,
                textAlign: TextAlign.center,
                style: ui(11, weight: FontWeight.w800, color: Palette.gooseWhite),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
