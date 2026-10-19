import 'dart:math' as math;
import 'dart:ui';

import '../game/heist.dart';
import '../game/night_sim.dart';
import '../theme/palette.dart';

/// How a play style shows: its tag on goal rows, its badge name, and the
/// tag colours from the briefing.
typedef StyleLook = ({String tag, String name, Color color, Color text});

StyleLook styleLook(PlayStyle style) => switch (style) {
  PlayStyle.ghost => (tag: 'GHOST', name: 'Ghost', color: Palette.calmMint, text: Palette.ink),
  PlayStyle.trickster => (tag: 'TRICK', name: 'Trickster', color: Palette.lamp, text: Palette.ink),
  PlayStyle.chaos => (tag: 'CHAOS', name: 'Chaos', color: Palette.alarmTomato, text: Palette.gooseWhite),
};

/// The goal as the briefing lists it.
String goalBrief(HeistGoal goal) => switch (goal.kind) {
  GoalKind.neverSuspicious => 'Never let her turn suspicious',
  GoalKind.lure => 'Lure her out of bed ${_times(goal.count)}',
  GoalKind.chain => 'Fire a ${goal.count}-link chain',
};

/// The goal on the HUD's GOAL pill, with tonight's progress.
String goalPill(HeistGoal goal, NightSim sim) => switch (goal.kind) {
  GoalKind.neverSuspicious => 'Never let her turn suspicious',
  GoalKind.lure => 'Lure her out of bed · ${math.min(sim.lures, goal.count)}/${goal.count}',
  GoalKind.chain => 'Fire a ${goal.count}-link chain · ${math.min(sim.combo.best, goal.count)}/${goal.count}',
};

/// The goal in the Victory recap line.
String goalRecap(HeistGoal goal) => switch (goal.kind) {
  GoalKind.neverSuspicious => 'Never seen',
  GoalKind.lure => 'Lured her out ${_times(goal.count)}',
  GoalKind.chain => '${goal.count}+ link chain',
};

/// 8450 → "8,450".
String thousands(int n) {
  final digits = n.abs().toString();
  final out = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

String _times(int n) => switch (n) {
  1 => 'once',
  2 => 'twice',
  _ => '$n times',
};
