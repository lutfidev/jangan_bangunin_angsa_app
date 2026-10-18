import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/goose_brain.dart';
import 'package:jangan_bangunin_angsa_app/game/night_sim.dart';
import 'package:jangan_bangunin_angsa_app/game/noise.dart';
import 'package:jangan_bangunin_angsa_app/screens/briefing_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/caught_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/chaos_escape_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/main_menu_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/pause_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/plan_view_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/settings_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/trophy_room_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/victory_screen.dart';
import 'package:jangan_bangunin_angsa_app/state/levels.dart';
import 'package:jangan_bangunin_angsa_app/widgets/stage.dart';

import '../game/fixtures.dart';
import '../helpers.dart';

/// Screenshots of every screen and the main gameplay states, to hold up
/// against the canvas artboards. Regenerate after a visual change with
/// `flutter test test/screenshots --update-goldens`, then look at them.
Future<void> snap(WidgetTester tester, String name) async {
  // flutter_svg decodes off the fake clock; give it real time to finish.
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
  await tester.pump();
  await expectLater(find.byType(Stage), matchesGoldenFile('goldens/$name.png'));
}

/// Milo by the nest, the egg just grabbed outside her roll-over: HONK.
NightSim _wokenByTheEgg() {
  final sim = NightSim(Levels.night3)..setSneak(true);
  walkTo(sim, 561);
  tickUntil(sim, () => !sim.goose.rollingOver);
  sim.grab('egg');
  return sim;
}

void main() {
  final screens = <String, Widget Function()>{
    'menu': () => const MainMenuScreen(),
    'briefing': () => const BriefingScreen(),
    'plan_view': () => const PlanViewScreen(),
    'chaos_escape': () => const ChaosEscapeScreen(),
    'pause': () => const PauseScreen(),
    'settings': () => const SettingsScreen(),
    'victory': () => VictoryScreen(result: sampleEscape()),
    'caught': () => CaughtScreen(result: sampleCaught()),
    'trophy_room': () => const TrophyRoomScreen(),
  };
  for (final MapEntry(key: name, value: screen) in screens.entries) {
    testWidgets(name, (tester) async {
      await pumpScreen(tester, screen());
      await snap(tester, name);
    });
  }

  testWidgets('gameplay', (tester) async {
    await pumpGameplay(tester);
    await snap(tester, 'gameplay');
  });

  testWidgets('gameplay_chain', (tester) async {
    final sim = NightSim(Levels.night3);
    walkTo(sim, 62);
    sim.poke('counterLeft');
    await pumpGameplay(tester, sim);
    await play(tester, 0.5);
    await snap(tester, 'gameplay_chain');
  });

  testWidgets('gameplay_suspicious', (tester) async {
    final sim = NightSim(Levels.night3);
    walkTo(sim, 345);
    sim.goose
      ..hear(const Noise(x: 480, loudness: 1))
      ..hear(const Noise(x: 480, loudness: 1));
    expect(sim.goose.state, GooseState.suspicious);
    await pumpGameplay(tester, sim);
    await snap(tester, 'gameplay_suspicious');
  });

  testWidgets('gameplay_honk', (tester) async {
    await pumpGameplay(tester, _wokenByTheEgg());
    await snap(tester, 'gameplay_honk');
  });

  testWidgets('gameplay_chase', (tester) async {
    final sim = NightSim(Levels.night3)..setSneak(true);
    sim.poke('sideTable'); // the robot marches into the clock: DONG
    await pumpGameplay(tester, sim);
    for (var i = 0; i < 600 && sim.goose.state != GooseState.chase; i++) {
      await tester.pump(const Duration(microseconds: 16667));
    }
    await play(tester, 1);
    await snap(tester, 'gameplay_chase');
  });

  testWidgets('gameplay_caught', (tester) async {
    final sim = await pumpGameplay(tester, _wokenByTheEgg());
    await play(tester, 1.2);
    expect(sim.outcome, isNull);
    await snap(tester, 'gameplay_caught');
  });
}
