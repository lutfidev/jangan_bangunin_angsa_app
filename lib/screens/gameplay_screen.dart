import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../art/art.dart';
import '../art/icons.dart';
import '../game/goose_brain.dart';
import '../game/level.dart';
import '../game/night_sim.dart';
import '../game/tools.dart';
import '../game/noise_meter.dart';
import '../routes.dart';
import '../state/game_settings.dart';
import '../state/levels.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import '../widgets/chunky_button.dart';
import '../widgets/dashed_outline.dart';
import '../widgets/hud.dart';
import '../widgets/joystick.dart';
import '../widgets/noise_fx.dart';
import '../widgets/outlined_text.dart';
import '../widgets/stage.dart';
import '../widgets/tool_button.dart';
import 'night3_set.dart';
import 'night_art.dart';
import 'scene.dart';
import 'tool_art.dart';

/// Landscape gameplay over Night 3, The Midnight Kitchen, driven by a
/// [NightSim] that ticks once per frame.
class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key, this.level, this.tool = Tool.socks, @visibleForTesting this.sim});

  /// Defaults to [Levels.night3].
  final Level? level;

  /// The tool picked at the briefing. An injected [sim] brings its own.
  final Tool tool;

  /// A night already under way, for tests.
  final NightSim? sim;

  /// The room layer that takes HONK's 4px nudge.
  static const sceneKey = Key('gameplay-scene');

  /// The red edge drawn while she chases.
  static const chaseFrameKey = Key('gameplay-chase-frame');

  /// The speed lines behind her while she runs.
  static const speedLinesKey = Key('gameplay-speed-lines');

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> with SingleTickerProviderStateMixin {
  /// A frame longer than this (a hitch, the app resuming) plays in slow
  /// motion instead of skipping the night ahead.
  static const _maxFrame = 0.1;

  late final NightSim _sim = widget.sim ?? NightSim(widget.level ?? Levels.night3, tool: widget.tool);
  late final Ticker _ticker = createTicker(_onTick);
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(onInactive: _pause);
  late final NoiseFx _fx = NoiseFx(level: _sim.level, anchors: spotAnchors, tuning: _sim.tuning);

  Duration? _last;
  bool _sneak = true;
  bool _paused = false;
  bool _done = false;
  bool _gooseRight = false;

  /// HONK's freeze-frame: nothing ticks while this runs down.
  double _freezeLeft = 0;

  /// Drag since the finger went down on the Tool button; null when not aiming.
  double? _aimDx;

  /// The goose has landed on Milo; the caught tableau plays.
  bool _caught = false;
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
    if (_freezeLeft > 0) {
      setState(() => _freezeLeft -= dt);
      return;
    }
    _sim.tick(dt);
    _fx.advance(dt);
    for (final e in _sim.takeEvents()) {
      _fx.take(e, gooseX: _sim.goose.x);
      switch (e) {
        case GooseChanged(to: GooseState.awake):
          // "A 0.3s freeze-frame, one white flash ring and HONK lettering."
          _freezeLeft = _sim.tuning.awakeFreeze;
          if (GameSettings.instance.haptics) HapticFeedback.heavyImpact();
        case CaughtStarted():
          _caught = true;
        case _:
      }
    }

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
    await Navigator.pushNamed(context, Routes.pause, arguments: _sim.tool);
    _paused = false;
    if (mounted && !_done) _ticker.start();
  }

  /// Where the aimed sock would come down: 4 artboard px per px of drag.
  double _aimX(double dx) => _sim.throwLanding(_sim.playerX + dx * 4);

  void _aimStart() {
    // A freeze-frame freezes the player too.
    if (_freezeLeft > 0 || !_sim.toolReady) return;
    setState(() => _aimDx = 0);
  }

  void _release() {
    final dx = _aimDx;
    if (dx == null) return;
    setState(() {
      _aimDx = null;
      // A short press is a cancel, not a throw at his own feet.
      if (dx.abs() >= 6 && _freezeLeft <= 0) _sim.throwSock(_aimX(dx));
    });
  }

  @override
  Widget build(BuildContext context) {
    final level = _sim.level;
    final goose = _sim.goose;
    final interaction = _sim.interaction;
    final carried = _sim.carried;
    final band = goose.meter.band;
    final px = _sim.playerX;
    final chasing = goose.state == GooseState.chase || goose.state == GooseState.distracted;
    final honk = _fx.honk;
    final nudge = _freezeLeft > 0 && !GameSettings.instance.reduceShake ? 4.0 : 0.0;

    // System back pauses the night instead of throwing it away.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _pause();
      },
      child: Stage(
        background: Palette.duskWall,
        children: [
          Positioned.fill(
            child: Transform.translate(
              key: GameplayScreen.sceneKey,
              offset: Offset(nudge, 0),
              child: Stack(
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
                              child: DashedOutline(
                                color: Palette.beakOrange,
                                strokeWidth: 2,
                                oval: true,
                                dash: 7,
                                gap: 5,
                              ),
                            )
                          : const Opacity(
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
                      const Opacity(opacity: 0.85, child: DashedOutline(color: Palette.lamp, oval: true)),
                      width: lootArt[loot.id]!.box.size + 28,
                      height: lootArt[loot.id]!.box.size + 16,
                    ),
                  for (final loot in level.loot)
                    if (!carried.contains(loot.id) && !loot.guarded) _loot(loot.id),
                  if (!carried.contains('chicken')) chickenSparkle(),

                  // Tools on the floor.
                  if (_sim.spillX case final x?) ...marbleSpill(x),
                  if (_sim.mouse case final mouse?) toyMouse(mouse),

                  // Speed lines trail her while she runs.
                  if (chasing && !_caught)
                    at(
                      _gooseRight ? goose.x - 120 : goose.x + 60,
                      196,
                      const InlineSvg(
                        key: GameplayScreen.speedLinesKey,
                        '<path d="M4 10 H44 M14 26 H56 M4 42 H40" stroke="#FBF8F1" stroke-width="3" stroke-linecap="round" opacity="0.7"/>',
                        width: 60,
                        height: 50,
                      ),
                    ),

                  // Gertrude in her nest, the egg under her.
                  if (!_caught)
                    at(
                      goose.x - 70,
                      160,
                      Transform.rotate(
                        angle: goose.slipping ? deg(-20) : 0,
                        child: Goose(mood: moodFor(goose.state), width: 140, flip: _gooseRight),
                      ),
                    ),
                  for (final loot in level.loot)
                    if (!carried.contains(loot.id) && loot.guarded) _loot(loot.id),
                  night3Nest(),
                  ...switch (goose.state) {
                    GooseState.asleep || GooseState.drowsy => [at(goose.x - 56, 160, const Snores(reversed: true))],
                    GooseState.stirring => [
                      at(goose.x - 56, 166, Text('z…?', style: display(18, color: Palette.moonlight))),
                    ],
                    GooseState.suspicious || GooseState.lostYou => [
                      at(
                        goose.x - 72,
                        120,
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Palette.beakOrange,
                            shape: BoxShape.circle,
                            border: inkBorder(),
                          ),
                          child: Text('?', style: display(20, height: 1)),
                        ),
                      ),
                    ],
                    _ => const <Widget>[],
                  },

                  // Milo, or Milo under a goose.
                  if (_caught) ...[
                    at(px - 50, 160, const Burglar(pose: BurglarPose.caught, width: 100)),
                    at(px - 50, 182, const Goose(mood: GooseMood.awake, width: 100)),
                    at(
                      px - 90,
                      150,
                      const SizedBox(
                        width: 180,
                        height: 100,
                        child: FittedBox(child: InlineSvg(featherPuffSvg, width: 330, height: 200)),
                      ),
                    ),
                  ] else
                    at(px - 30, 196, Burglar(pose: _pose(goose, carried), width: 60, flip: _sim.facing > 0)),
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
                    Wind(:final spotId) => at(
                      spotAnchors[spotId]!.dx - 32,
                      spotAnchors[spotId]!.dy - 64,
                      const PromptBubble('Wind'),
                    ),
                    null => const SizedBox.shrink(),
                  },
                  at(
                    758,
                    108,
                    // The EXIT sign pulses while she chases.
                    Transform.scale(
                      scale: chasing ? 1 + 0.08 * math.sin(2 * math.pi * 1.5 * _sim.elapsed) : 1,
                      child: const ExitSign(),
                    ),
                  ),

                  // Socks in the air, and the one being aimed.
                  for (final f in _sim.flights) flyingSock(f, throwArc(fromX: f.fromX, end: throwEnd(_sim, f.toX))),
                  if (_aimDx case final dx?)
                    Positioned.fill(
                      child: AimLayer(arc: throwArc(fromX: px, end: throwEnd(_sim, _aimX(dx)))),
                    ),

                  FxLayer(fx: _fx),
                  if (honk != null) ...[
                    at(
                      honk.at.dx - 80,
                      honk.at.dy - 80,
                      Opacity(
                        opacity: 0.5 * honk.opacity,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Palette.gooseWhite, width: 6),
                          ),
                        ),
                      ),
                      width: 160,
                      height: 160,
                    ),
                    at(
                      honk.at.dx - 160,
                      honk.at.dy - 90,
                      Opacity(
                        opacity: honk.opacity,
                        child: Transform.rotate(
                          angle: deg(-8),
                          child: OutlinedText('HONK!', style: display(38, color: Palette.alarmTomato, height: 1)),
                        ),
                      ),
                    ),
                  ],
                  if (goose.state == GooseState.distracted)
                    at(
                      goose.x - 60,
                      102,
                      Pill(
                        'DISTRACTED · ${goose.distractLeft.ceil()}s',
                        color: Palette.lamp,
                        borderWidth: 3,
                        padding: const EdgeInsets.fromLTRB(4, 3, 10, 3),
                        textStyle: ui(12, weight: FontWeight.w800, letterSpacing: 1),
                        leading: const InlineSvg(
                          '<circle cx="12" cy="12" r="9" fill="#FBF8F1" stroke="#1C1A2B" stroke-width="2.5"/>'
                          '<path d="M12 3 A9 9 0 0 1 20.5 15 L12 12 Z" fill="#F0533B"/>',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),

                  ...floorAndControlBand(rules: true),
                  loosePlank(),

                  // Red chase frame.
                  if (chasing)
                    at(
                      0,
                      0,
                      IgnorePointer(
                        key: GameplayScreen.chaseFrameKey,
                        child: Opacity(
                          opacity: 0.55,
                          child: DecoratedBox(
                            decoration: BoxDecoration(border: Border.all(color: Palette.alarmTomato, width: 6)),
                          ),
                        ),
                      ),
                      width: 844,
                      height: 286,
                    ),
                ],
              ),
            ),
          ),

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
          if (chasing) at(600, 18, _ChasePill(left: goose.chaseLeft / _sim.tuning.chaseTime)),
          at(782, 12, RoundIconButton(onPressed: _pause, semanticLabel: 'Pause', child: const PauseBars())),
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
          at(0, 286, Joystick(onChanged: _sim.setMove)),
          if (_aimDx != null) aimHint(),
          at(
            596,
            316,
            ToolButton(
              tool: _sim.tool,
              left: _sim.toolLeft,
              ready: _sim.toolReady,
              aiming: _aimDx != null,
              onTap: () {
                if (_freezeLeft <= 0) setState(() => _sim.useTool());
              },
              onAimStart: _aimStart,
              onAim: (dx) {
                if (_aimDx != null) setState(() => _aimDx = dx);
              },
              onRelease: _release,
            ),
          ),
          at(666, 306, SneakButton(on: _sneak, onPressed: () => setState(() => _sim.setSneak(_sneak = !_sneak)))),
          at(742, 294, _interactButton(interaction)),
        ],
      ),
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
    void interact() {
      // A freeze-frame freezes the player too.
      if (_freezeLeft > 0) return;
      setState(() => _sim.interact());
    }

    const hand = Glyph(GameIcon.grab, size: 28, strokeWidth: 2.4);
    return switch (interaction) {
      GrabLoot(:final loot) => ActionButton(
        label: 'GRAB',
        semanticLabel: 'Grab ${lootArt[loot.id]!.name}',
        icon: hand,
        onPressed: interact,
      ),
      Wind(:final objectId) => ActionButton(
        label: 'WIND',
        semanticLabel: 'Wind up the $objectId',
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

/// Time left in the chase, as a draining red bar.
class _ChasePill extends StatelessWidget {
  const _ChasePill({required this.left});

  /// Fraction of the chase left, 1 → 0.
  final double left;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: Palette.night, border: inkBorder(), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Container(
            width: 70,
            height: 10,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(color: Palette.slate, borderRadius: BorderRadius.circular(5)),
            child: Container(
              width: 70 * left.clamp(0, 1),
              decoration: BoxDecoration(color: Palette.alarmTomato, borderRadius: BorderRadius.circular(5)),
            ),
          ),
          Text(
            'CHASE',
            style: ui(10, weight: FontWeight.w800, letterSpacing: 1, color: Palette.alarmTomato),
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
      shadows: on ? ringShadows(color: Palette.calmMint, width: 3, outline: 2, drop: 3) : null,
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
  const ActionButton({super.key, required this.label, required this.onPressed, this.semanticLabel, this.icon});

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
