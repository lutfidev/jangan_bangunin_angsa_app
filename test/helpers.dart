import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/chain.dart';
import 'package:jangan_bangunin_angsa_app/game/goose_brain.dart';
import 'package:jangan_bangunin_angsa_app/game/heist.dart';
import 'package:jangan_bangunin_angsa_app/game/night_sim.dart';
import 'package:jangan_bangunin_angsa_app/game/tools.dart';
import 'package:jangan_bangunin_angsa_app/game/noise.dart';
import 'package:jangan_bangunin_angsa_app/main.dart';
import 'package:jangan_bangunin_angsa_app/screens/gameplay_screen.dart';
import 'package:jangan_bangunin_angsa_app/state/levels.dart';
import 'package:jangan_bangunin_angsa_app/widgets/stage.dart';

import 'game/fixtures.dart';

/// Sizes the test surface to the design artboard, so screens render at 1:1.
void useStageSurface(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(Stage.width, Stage.height)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Pumps [screen] on its own inside a [MaterialApp]. A screen that never
/// settles (gameplay ticks every frame) gets a few frames instead.
Future<void> pumpScreen(WidgetTester tester, Widget screen, {bool settle = true}) async {
  useStageSurface(tester);
  await tester.pumpWidget(MaterialApp(home: screen));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// A Night 3 catch: [chain] lists the objects that went off, in order.
NightResult sampleCaught({
  List<String> chain = const ['glass', 'pot', 'robot'],
  WakeCause cause = WakeCause.noise,
  Tool tool = Tool.socks,
}) {
  final level = Levels.night3;
  return NightResult(
    level: level,
    outcome: Outcome.caught,
    loot: const [],
    wakeChain: [
      for (final (i, id) in chain.indexed)
        LinkFired(
          chainId: 1,
          link: i + 1,
          objectId: id,
          spotId: level.objects.firstWhere((o) => o.id == id).spot,
          noise: const Noise(x: 0, loudness: 1),
        ),
    ],
    wakeCause: cause,
    time: 42,
    tool: tool,
  );
}

/// A Night 3 getaway carrying [loot]; the rest defaults to the Level
/// Complete board's example.
NightResult sampleEscape({
  List<String> loot = const ['toaster', 'chicken', 'egg'],
  double time = 167,
  Tool tool = Tool.socks,
  int score = 8450,
  int bestChain = 6,
  int lures = 2,
  PlayStyle style = PlayStyle.trickster,
  Set<PlayStyle> goalsMet = const {PlayStyle.trickster, PlayStyle.chaos},
}) => NightResult(
  level: Levels.night3,
  outcome: Outcome.escaped,
  loot: loot,
  time: time,
  tool: tool,
  score: score,
  bestChain: bestChain,
  lures: lures,
  style: style,
  goalsMet: goalsMet,
);

/// Pumps 60fps frames for [seconds].
Future<void> play(WidgetTester tester, double seconds) async {
  for (var t = 0.0; t < seconds - 1e-9; t += frame) {
    await tester.pump(const Duration(microseconds: 16667));
  }
}

/// The gameplay screen on the app's real routes, driving [sim].
Future<NightSim> pumpGameplay(WidgetTester tester, [NightSim? sim]) async {
  final s = sim ?? NightSim(Levels.night3);
  useStageSurface(tester);
  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: MainApp.route,
      home: GameplayScreen(tool: s.tool, sim: s),
    ),
  );
  await tester.pump();
  return s;
}
