import 'package:flutter/material.dart';

import '../art/art.dart';
import '../art/icons.dart';
import '../game/heist.dart';
import '../game/night_sim.dart';
import '../routes.dart';
import '../state/heist_log.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import '../widgets/chunky_button.dart';
import '../widgets/dashed_outline.dart';
import '../widgets/hud.dart';
import '../widgets/outlined_text.dart';
import '../widgets/stage.dart';
import 'heist_copy.dart';
import 'night_art.dart';
import 'scene.dart';

/// Level complete: loot haul, run stats and the morning-after vignette.
class VictoryScreen extends StatelessWidget {
  const VictoryScreen({super.key, required this.result});

  final NightResult result;

  /// The morning-after line names the guarded loot if it went, else the
  /// last thing grabbed.
  String get _morning {
    if (result.loot.isEmpty) return 'Morning. Nothing is missing.';
    final guarded = result.level.loot.where((l) => l.guarded && result.loot.contains(l.id));
    final id = guarded.isEmpty ? result.loot.last : guarded.first.id;
    return 'Morning. The ${lootArt[id]!.name} is gone.';
  }

  /// Under the badge: the best combo, else the lures, else nothing at all.
  String get _styleLine {
    if (result.bestChain >= 2) return 'Best chain ×${result.bestChain}';
    if (result.lures > 0) return 'Lured ×${result.lures}';
    return 'Not a peep';
  }

  /// Goals met tonight first, then the rest, each in level order.
  List<(HeistGoal, bool)> get _goalsMetFirst => [
    for (final g in result.level.goals)
      if (result.goalsMet.contains(g.style)) (g, true),
    for (final g in result.level.goals)
      if (!result.goalsMet.contains(g.style)) (g, false),
  ];

  /// After the goals: where the next sock is, counting socks [earned] on
  /// earlier runs.
  String _hint(Set<PlayStyle> earned) {
    final missing = [for (final (g, met) in _goalsMetFirst) if (!met) g];
    if (missing.isEmpty) return 'every sock tonight!';
    final unearned = [for (final g in missing) if (!earned.contains(g.style)) g];
    if (unearned.isEmpty) return 'every sock collected!';
    final name = styleLook(unearned.first.style).name;
    return unearned.length == 1 ? 'try a $name run for the last sock.' : 'try a $name run for another sock.';
  }

  /// "✓ Lured her out twice · ✓ 5+ link chain · ✗ Never seen — try a Ghost
  /// run for the last sock." The ticks are drawn; the font has no glyph.
  Widget _recap(Set<PlayStyle> earned) {
    if (result.level.goals.isEmpty) return const SizedBox.shrink();
    final hint = _hint(earned);
    final style = ui(12, weight: FontWeight.w600, color: Palette.paleBlue);
    final goals = _goalsMetFirst;
    final spoken = [for (final (g, met) in goals) '${met ? '✓' : '✗'} ${goalRecap(g)}'].join(' · ');
    return Semantics(
      label: '$spoken — $hint',
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              style: style,
              children: [
                for (final (i, (g, met)) in goals.indexed) ...[
                  if (i > 0) const TextSpan(text: ' · '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Glyph(met ? GameIcon.check : GameIcon.cross, size: 11, strokeWidth: 3.5, color: Palette.paleBlue),
                  ),
                  TextSpan(text: ' ${goalRecap(g)}'),
                ],
                TextSpan(text: ' — $hint'),
              ],
            ),
            softWrap: false,
          ),
        ),
      ),
    );
  }

  static String _clock(double seconds) {
    final s = seconds.floor();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final look = styleLook(result.style);
    final goals = result.level.goals;
    final earnedBefore = HeistLog.instance.earned(result.level.id);
    return Stage(
      background: Palette.midnight,
      children: [
        at(
          28,
          20,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text('NIGHT 3 · THE MIDNIGHT KITCHEN', style: hudLabel(size: 12)),
              Semantics(
                header: true,
                child: OutlinedText(
                  'Clean getaway!',
                  style: display(46, color: Palette.calmMint, height: 1.05),
                  drop: 5,
                ),
              ),
            ],
          ),
        ),

        // Loot haul.
        at(
          28,
          102,
          Row(
            spacing: 12,
            children: [
              for (final loot in result.level.loot)
                _LootCard(
                  lootArt[loot.id]!.kind,
                  lootArt[loot.id]!.name,
                  stolen: result.loot.contains(loot.id),
                ),
            ],
          ),
        ),

        // Stats.
        at(
          28,
          218,
          SizedBox(
            width: 440,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  _StatCard(
                    color: look.color,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    children: [
                      Text('STYLE', style: hudLabel(color: look.text, size: 10, spacing: 1.4)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        // One line, or the row's intrinsic height counts it wrapped.
                        child: Text(look.name, style: display(19, color: look.text, height: 1.15), maxLines: 1),
                      ),
                      Text(_styleLine, style: ui(10, weight: FontWeight.w800, color: look.text), maxLines: 1),
                    ],
                  ),
                  _StatCard(
                    children: [
                      Text('SCORE', style: hudLabel(size: 10, spacing: 1.4)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(thousands(result.score), style: display(21, color: Palette.lamp, height: 1.2), maxLines: 1),
                      ),
                    ],
                  ),
                  _StatCard(
                    children: [
                      Text('TIME', style: hudLabel(size: 10, spacing: 1.4)),
                      Text(_clock(result.time), style: display(21, color: Palette.gooseWhite, height: 1.2)),
                    ],
                  ),
                  _StatCard(
                    spacing: 3,
                    children: [
                      Text('HEIST GOALS', style: hudLabel(size: 10, spacing: 1.4)),
                      Semantics(
                        label: 'Heist goals ${{...result.goalsMet, ...earnedBefore}.length} of ${goals.length} socks',
                        child: Row(
                          spacing: 2,
                          children: [
                            // Socks met tonight in lamp; earned on an earlier run in mint.
                            for (final g in goals)
                              result.goalsMet.contains(g.style)
                                  ? const SockGlyph(fill: Palette.lamp, size: 21)
                                  : earnedBefore.contains(g.style)
                                  ? const SockGlyph(fill: Palette.calmMint, size: 21)
                                  : const SockGlyph(fill: Palette.slate, stroke: Color(0xFF55598F), size: 21),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        at(
          28,
          290,
          SizedBox(
            width: 440,
            child: _recap(earnedBefore),
          ),
        ),
        at(
          28,
          318,
          Row(
            spacing: 12,
            children: [
              ChunkyButton.secondary(
                onPressed: () => Routes.restartNight(context, result.setup),
                label: 'Replay',
                icon: GameIcon.retry,
                iconStroke: 2.8,
                height: 58,
              ),
              ChunkyButton.primary(
                onPressed: () => Routes.toMenu(context),
                label: 'Continue',
                trailingIcon: GameIcon.arrow,
                iconSize: 18,
                height: 58,
                fontSize: 22,
                depth: 4,
                padding: const EdgeInsets.symmetric(horizontal: 28),
              ),
            ],
          ),
        ),

        // Morning after.
        at(492, 22, _MorningVignette(_morning)),
      ],
    );
  }
}

class _LootCard extends StatelessWidget {
  const _LootCard(this.kind, this.name, {required this.stolen});

  final PropKind kind;
  final String name;

  /// Loot left behind shows as a silhouette, without the tick.
  final bool stolen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 100,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: PanelCard(
              padding: EdgeInsets.zero,
              radius: 16,
              borderWidth: 3,
              depth: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 2,
                children: [
                  Prop(kind, size: 56, silhouette: !stolen),
                  Text(name, style: ui(12, weight: FontWeight.w800), softWrap: false),
                ],
              ),
            ),
          ),
          if (stolen) const Positioned(right: -8, top: -8, child: CheckBadge(size: 24, border: 3)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.children,
    this.color = Palette.night,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.spacing = 2,
  });

  final List<Widget> children;
  final Color color;
  final EdgeInsets padding;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          border: inkBorder(),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: spacing,
          children: children,
        ),
      ),
    );
  }
}

class _MorningVignette extends StatelessWidget {
  const _MorningVignette(this.caption);

  final String caption;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      width: 326,
      height: 346,
      color: Palette.lampRoom,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            at(
              0,
              0,
              const InlineSvg(
                '<path d="M150 0 L150 34" stroke="#1C1A2B" stroke-width="3"/>'
                '<path d="M126 54 L174 54 L162 34 L138 34 Z" fill="#FFC14D" stroke="#1C1A2B" stroke-width="4" stroke-linejoin="round"/>'
                '<path d="M130 54 L170 54 L250 262 L50 262 Z" fill="#FFC14D" opacity="0.12"/>',
                width: 318,
                height: 338,
              ),
            ),
            box(20, 188, 200, 74, Palette.wood, border: 3),
            box(14, 180, 212, 12, Palette.counterTop, border: 3, radius: 4),
            // Where the loot used to be.
            at(
              40,
              120,
              const Opacity(
                opacity: 0.6,
                child: DashedOutline(color: Palette.gooseWhite, radius: 10),
              ),
              width: 66,
              height: 60,
            ),
            at(
              132,
              136,
              const Opacity(
                opacity: 0.6,
                child: DashedOutline(color: Palette.gooseWhite, oval: true, dash: 6, gap: 5),
              ),
              width: 44,
              height: 44,
            ),
            Positioned(
              left: 0,
              top: 262,
              width: 318,
              height: 80,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: Palette.floorTrim,
                  border: Border(top: BorderSide(color: Palette.ink, width: 4)),
                ),
              ),
            ),
            at(148, 156, const Goose(mood: GooseMood.suspicious, width: 150, flip: true)),
            at(60, 254, Transform.rotate(angle: deg(-24), child: const Prop(PropKind.sock, size: 34))),
            at(
              226,
              92,
              Transform.rotate(
                angle: deg(10),
                child: OutlinedText('?!', style: display(44, color: Palette.beakOrange)),
              ),
            ),
            at(
              16,
              16,
              Pill(
                caption,
                borderWidth: 3,
                radius: 10,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                textStyle: ui(12, weight: FontWeight.w800),
              ),
            ),
            at(
              16,
              304,
              Text('Left behind: one mint sock.', style: ui(12, color: Palette.gooseWhite)),
            ),
          ],
        ),
      ),
    );
  }
}
