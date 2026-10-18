import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../art/art.dart';
import '../art/icons.dart';
import '../game/goose_brain.dart';
import '../game/level.dart';
import '../game/night_sim.dart';
import '../game/noise_meter.dart';
import '../routes.dart';
import '../state/levels.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import '../widgets/chunky_button.dart';
import '../widgets/dashed_outline.dart';
import '../widgets/hud.dart';
import '../widgets/joystick.dart';
import '../widgets/stage.dart';
import 'night3_set.dart';
import 'night_art.dart';
import 'scene.dart';

/// Landscape gameplay over Night 3, The Midnight Kitchen, driven by a
/// [NightSim] that ticks once per frame.
class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key, this.level, @visibleForTesting this.sim});

  /// Defaults to [Levels.night3].
  final Level? level;

  /// A night already under way, for tests.
  final NightSim? sim;

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> with SingleTickerProviderStateMixin {
  /// A frame longer than this (a hitch, the app resuming) plays in slow
  /// motion instead of skipping the night ahead.
  static const _maxFrame = 0.1;

  late final NightSim _sim = widget.sim ?? NightSim(widget.level ?? Levels.night3);
  late final Ticker _ticker = createTicker(_onTick);
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(onInactive: _pause);

  Duration? _last;
  bool _sneak = true;
  bool _paused = false;
  bool _done = false;
  bool _miloRight = true;
  bool _gooseRight = false;
  late double _gooseX = _sim.goose.x;

  @override
  void initState() {
    super.initState();
    _sim.setSneak(_sneak);
    _lifecycle;
    _ticker.start();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final last = _last;
    _last = elapsed;
    final dt = last == null ? 0.0 : math.min((elapsed - last).inMicroseconds / 1e6, _maxFrame);
    _sim.tick(dt);
    _sim.takeEvents();

    final x = _sim.goose.x;
    if (x != _gooseX) _gooseRight = x > _gooseX;
    _gooseX = x;

    final result = _sim.result;
    if (result != null) {
      _done = true;
      _ticker.stop();
      Navigator.pushReplacementNamed(
        context,
        result.outcome == Outcome.caught ? Routes.caught : Routes.victory,
        arguments: result,
      );
    }
    setState(() {});
  }

  Future<void> _pause() async {
    if (_paused || _done) return;
    _paused = true;
    _ticker.stop();
    _last = null;
    await Navigator.pushNamed(context, Routes.pause);
    _paused = false;
    if (mounted && !_done) _ticker.start();
  }

  void _move(double dir) {
    _sim.setMove(dir);
    if (dir != 0) _miloRight = dir > 0;
  }

  @override
  Widget build(BuildContext context) {
    final level = _sim.level;
    final goose = _sim.goose;
    final interaction = _sim.interaction;
    final carried = _sim.carried;
    final band = goose.meter.band;
    final px = _sim.playerX;

    return Stage(
      background: Palette.duskWall,
      children: [
        ...night3Backdrop(),

        // Gertrude's ear zone: only rings that touch it raise the meter.
        if (!goose.isAwake)
          at(
            goose.x - 172,
            228,
            band == MeterBand.suspicious || band == MeterBand.danger
                ? const Opacity(
                    opacity: 0.7,
                    child: DashedOutline(color: Palette.beakOrange, strokeWidth: 2, oval: true, dash: 7, gap: 5),
                  )
                : const Opacity(
                    opacity: 0.4,
                    child: DashedOutline(color: Palette.moonlight, strokeWidth: 2, oval: true, dash: 7, gap: 5),
                  ),
            width: 344,
            height: 76,
          ),
        night3Rug(),

        // The chain kit; spent tippers and walkers lie where they fell.
        for (final MapEntry(key: id, value: art) in objectArt.entries)
          at(
            art.box.left,
            art.box.top,
            Transform.rotate(
              angle: switch (id) {
                'glass' when _sim.chain.isSpent(id) => deg(-70),
                'robot' when _sim.chain.isSpent(id) => deg(-80),
                _ => 0,
              },
              child: Prop(art.kind, size: art.box.size),
            ),
          ),

        // Loot still in the house, and what Interact would do.
        if (interaction case GrabLoot(:final loot))
          at(
            lootArt[loot.id]!.box.left - 14,
            lootArt[loot.id]!.box.top - 14,
            const Opacity(
              opacity: 0.85,
              child: DashedOutline(color: Palette.lamp, oval: true),
            ),
            width: lootArt[loot.id]!.box.size + 28,
            height: lootArt[loot.id]!.box.size + 16,
          ),
        for (final loot in level.loot)
          if (!carried.contains(loot.id) && !loot.guarded) _loot(loot.id),
        if (!carried.contains('chicken')) chickenSparkle(),

        // Gertrude in her nest, the egg under her.
        at(goose.x - 70, 160, Goose(mood: moodFor(goose.state), width: 140, flip: _gooseRight)),
        for (final loot in level.loot)
          if (!carried.contains(loot.id) && loot.guarded) _loot(loot.id),
        night3Nest(),
        ...switch (goose.state) {
          GooseState.asleep || GooseState.drowsy => [at(goose.x - 56, 160, const Snores(reversed: true))],
          GooseState.stirring => [at(goose.x - 56, 166, Text('z…?', style: display(18, color: Palette.moonlight)))],
          GooseState.suspicious || GooseState.lostYou => [
            at(
              goose.x - 72,
              120,
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Palette.beakOrange, shape: BoxShape.circle, border: inkBorder()),
                child: Text('?', style: display(20, height: 1)),
              ),
            ),
          ],
          _ => const <Widget>[],
        },

        // Milo.
        at(px - 30, 196, Burglar(pose: _pose(goose, carried), width: 60, flip: _miloRight)),
        if (_sneak && !goose.isAwake)
          at(
            px - 26,
            256,
            const InlineSvg(
              '<path d="M8 14 Q4 8 8 2 M52 14 Q56 8 52 2" fill="none" stroke="#5CC9A7" stroke-width="2.5" stroke-linecap="round"/>',
              width: 60,
              height: 18,
            ),
          ),

        switch (interaction) {
          GrabLoot(:final loot) => at(
            lootArt[loot.id]!.box.left - 4,
            lootArt[loot.id]!.box.top - 46,
            const PromptBubble('Grab'),
          ),
          Nudge(:final spotId) => at(
            spotAnchors[spotId]!.dx - 32,
            spotAnchors[spotId]!.dy - 64,
            const PromptBubble('Nudge'),
          ),
          null => const SizedBox.shrink(),
        },
        at(758, 108, const ExitSign()),

        ...floorAndControlBand(rules: true),
        loosePlank(),

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
                    Text(
                      '${carried.length}/${level.loot.length}',
                      style: display(18, color: Palette.gooseWhite, height: 1.1),
                    ),
                  ],
                ),
                for (final loot in level.loot)
                  LootSlot(
                    kind: lootArt[loot.id]!.kind,
                    state: carried.contains(loot.id)
                        ? LootState.stolen
                        : interaction is GrabLoot && interaction.loot.id == loot.id
                        ? LootState.nearby
                        : LootState.missing,
                  ),
              ],
            ),
          ),
        ),
        at(292, 14, AlertMeter(value: goose.meter.value)),
        at(
          782,
          12,
          RoundIconButton(
            onPressed: _pause,
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

        // Touch controls. Tools arrive with Throw.
        at(0, 286, Joystick(onChanged: _move)),
        at(596, 316, const Opacity(opacity: 0.6, child: _ToolButton())),
        at(
          666,
          306,
          SneakButton(
            on: _sneak,
            onPressed: () => setState(() => _sim.setSneak(_sneak = !_sneak)),
          ),
        ),
        at(742, 294, _interactButton(interaction)),
      ],
    );
  }

  Widget _loot(String id) {
    final art = lootArt[id]!;
    return at(art.box.left, art.box.top, Prop(art.kind, size: art.box.size));
  }

  static BurglarPose _pose(GooseBrain goose, List<String> carried) => goose.isAwake
      ? BurglarPose.panic
      : carried.isNotEmpty
      ? BurglarPose.carry
      : BurglarPose.sneak;

  Widget _interactButton(Interaction? interaction) {
    void interact() => setState(() => _sim.interact());
    const hand = Glyph(GameIcon.grab, size: 28, strokeWidth: 2.4);
    return switch (interaction) {
      GrabLoot(:final loot) => ActionButton(
        label: 'GRAB',
        semanticLabel: 'Grab ${lootArt[loot.id]!.name}',
        icon: hand,
        onPressed: interact,
      ),
      Nudge(:final objectId) => ActionButton(
        label: 'NUDGE',
        semanticLabel: 'Nudge $objectId',
        icon: hand,
        onPressed: interact,
      ),
      null => const Opacity(
        opacity: 0.6,
        child: ActionButton(label: 'GRAB', icon: hand, onPressed: null),
      ),
    };
  }
}

/// The tool slot; inert until Throw lands (langkah 3).
class _ToolButton extends StatelessWidget {
  const _ToolButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ChunkyButton(
            onPressed: null,
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
