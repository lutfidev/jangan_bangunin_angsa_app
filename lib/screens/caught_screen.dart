import 'package:flutter/material.dart';

import '../art/art.dart';
import '../art/icons.dart';
import '../game/goose_brain.dart';
import '../game/night_sim.dart';
import '../routes.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import '../widgets/chunky_button.dart';
import '../widgets/hud.dart';
import '../widgets/outlined_text.dart';
import '../widgets/stage.dart';
import 'night_art.dart';
import 'scene.dart';

/// Caught: Gertrude sits on Milo, and the chain that woke her is recapped.
class CaughtScreen extends StatelessWidget {
  const CaughtScreen({super.key, required this.result});

  final NightResult result;

  static const recapKey = Key('caught-recap');

  @override
  Widget build(BuildContext context) {
    return Stage(
      background: Palette.midnight,
      children: [
        at(
          0,
          0,
          const InlineSvg(
            '<path d="M190 20 L222 112 L310 66 L276 156 L384 168 L290 222 L352 302 L254 284 L232 380 L182 296 L100 352 L120 262 L18 248 L102 196 L30 118 L136 140 Z" fill="#F0533B" stroke="#1C1A2B" stroke-width="5" stroke-linejoin="round"/>',
            width: 400,
            height: 390,
          ),
        ),
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
        at(60, 131, const Burglar(pose: BurglarPose.caught, width: 170)),
        at(60, 171, const Goose(mood: GooseMood.awake, width: 170)),
        at(
          20,
          100,
          const InlineSvg(
            '<g fill="#FBF8F1" stroke="#1C1A2B" stroke-width="3" stroke-linejoin="round">'
            '<path d="M30 40 Q44 22 60 30 Q46 46 30 40 Z" transform="rotate(-20 45 35)"/>'
            '<path d="M270 30 Q286 14 300 24 Q286 38 270 30 Z" transform="rotate(25 285 26)"/>'
            '<path d="M300 140 Q314 124 326 134 Q312 148 300 140 Z"/>'
            '<path d="M10 150 Q24 134 38 144 Q24 158 10 150 Z" transform="rotate(30 24 146)"/>'
            '</g>',
            width: 330,
            height: 200,
          ),
        ),

        at(
          436,
          18,
          Transform.rotate(
            angle: deg(-5),
            child: OutlinedText(
              'HONK!',
              style: display(78, color: Palette.alarmTomato, height: 1),
              stroke: 4,
              drop: 6,
            ),
          ),
        ),
        at(
          440,
          112,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Semantics(
                header: true,
                child: Text(
                  "You've been goosed.",
                  style: display(30, color: Palette.gooseWhite, height: 1.05),
                ),
              ),
              Text(
                'Gertrude has filed a formal noise complaint. With her beak.',
                style: ui(15, weight: FontWeight.w600, color: Palette.paleBlue),
              ),
            ],
          ),
          width: 380,
        ),

        // What woke her.
        at(
          440,
          190,
          NightPlate(
            width: 380,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            radius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Text('WHAT WOKE HER', style: hudLabel(size: 10, spacing: 1.4)),
                // A long chain shrinks to fit rather than overflow.
                SizedBox(
                  key: recapKey,
                  width: 352,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      spacing: 6,
                      children: [
                        ..._causes(),
                        Text('HONK', style: display(18, color: Palette.alarmTomato)),
                      ],
                    ),
                  ),
                ),
                Text(wakeTip(result), style: ui(12, weight: FontWeight.w600, color: Palette.gooseWhite)),
              ],
            ),
          ),
        ),

        at(
          440,
          316,
          Row(
            spacing: 12,
            children: [
              ChunkyButton.primary(
                onPressed: () => Routes.restartNight(context),
                label: 'Retry',
                icon: GameIcon.retry,
                height: 62,
              ),
              ChunkyButton.secondary(
                onPressed: () => Routes.toMenu(context),
                label: 'Main menu',
                icon: GameIcon.home,
                height: 62,
                depth: 5,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The chain that woke her, link by link; or, with no chain, what did.
  List<Widget> _causes() {
    if (result.wakeChain.isNotEmpty) {
      return [
        for (final link in result.wakeChain) ...[
          _ChainTile(objectIcon(link.objectId)),
          _ChainArrow(linkColor(link.link)),
        ],
      ];
    }
    final level = result.level;
    final Widget cause = switch (result.wakeCause) {
      WakeCause.footsteps => const Burglar(width: 26),
      WakeCause.grabbedGuarded => Prop(lootArt[level.loot.firstWhere((l) => l.guarded).id]!.kind, size: 32),
      _ => Prop(lootArt[level.loot.firstWhere((l) => l.squeaks).id]!.kind, size: 32),
    };
    return [_ChainTile(cause), const _ChainArrow(Palette.alarmTomato)];
  }
}

class _ChainTile extends StatelessWidget {
  const _ChainTile(this.icon);

  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Palette.gooseWhite,
        border: inkBorder(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: icon,
    );
  }
}

class _ChainArrow extends StatelessWidget {
  const _ChainArrow(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    final hex = '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    return InlineSvg(
      '<path d="M1 6 H15" stroke="$hex" stroke-width="3" stroke-dasharray="3 3"/>'
      '<path d="M14 1 L21 6 L14 11 Z" fill="$hex"/>',
      width: 22,
      height: 12,
    );
  }
}
