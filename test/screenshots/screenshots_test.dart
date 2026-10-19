import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/geom.dart';
import 'package:jangan_bangunin_angsa_app/game/goose_brain.dart';
import 'package:jangan_bangunin_angsa_app/game/heist.dart';
import 'package:jangan_bangunin_angsa_app/game/night_sim.dart';
import 'package:jangan_bangunin_angsa_app/game/modifiers.dart';
import 'package:jangan_bangunin_angsa_app/game/noise.dart';
import 'package:jangan_bangunin_angsa_app/game/tools.dart';
import 'package:jangan_bangunin_angsa_app/screens/briefing_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/caught_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/chaos_escape_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/main_menu_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/pause_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/plan_view_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/settings_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/trophy_room_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/victory_screen.dart';
import 'package:jangan_bangunin_angsa_app/state/heist_log.dart';
import 'package:jangan_bangunin_angsa_app/state/levels.dart';
import 'package:jangan_bangunin_angsa_app/widgets/stage.dart';
import 'package:jangan_bangunin_angsa_app/widgets/tool_button.dart';

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
  // The HUD board's GOAL pill is the lure goal, so Ghost is already earned.
  setUp(() => HeistLog.instance.record(sampleEscape(goalsMet: {PlayStyle.ghost})));
  tearDown(HeistLog.instance.clear);

  final screens = <String, Widget Function()>{
    'menu': () => const MainMenuScreen(),
    'briefing': () {
      // The briefing board has only the Trickster sock.
      HeistLog.instance
        ..clear()
        ..record(sampleEscape(goalsMet: {PlayStyle.trickster}));
      return const BriefingScreen();
    },
    'plan_view': () => const PlanViewScreen(),
    'chaos_escape': () => const ChaosEscapeScreen(),
    'pause': () => const PauseScreen(),
    'settings': () => const SettingsScreen(),
    'victory': () {
      // Board D: no sock from an earlier run, so the recap reads like the board.
      HeistLog.instance.clear();
      return VictoryScreen(result: sampleEscape());
    },
    'caught': () => CaughtScreen(result: sampleCaught()),
    'trophy_room': () {
      // Two of Night 3's loot taken; the egg and the duck still to get.
      HeistLog.instance
        ..clear()
        ..record(sampleEscape(loot: ['toaster', 'chicken'], goalsMet: {PlayStyle.ghost}));
      return const TrophyRoomScreen();
    },
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

  testWidgets('gameplay_mirror', (tester) async {
    // Mirror Night with a chain going, so its words show too.
    final sim = NightSim(Levels.night3, setup: const NightSetup(mirror: true));
    walkTo(sim, 62);
    sim.poke('counterLeft');
    await pumpGameplay(tester, sim);
    await play(tester, 0.5);
    await snap(tester, 'gameplay_mirror');
  });

  testWidgets('gameplay_remix', (tester) async {
    // Chicken near the plank's left end, pot under the shelf.
    final level = Levels.night3.rearranged(lootAt: {'chicken': const Vec(300, 106)}, objectSpots: {'pot': 'underShelf'});
    await pumpGameplay(tester, NightSim(level));
    await snap(tester, 'gameplay_remix');
  });

  testWidgets('gameplay_remix_kitchen', (tester) async {
    final level = Levels.night3.rearranged(lootAt: {'toaster': const Vec(60, 270)}, objectSpots: {'pot': 'underSideTable'});
    await pumpGameplay(tester, NightSim(level));
    await snap(tester, 'gameplay_remix_kitchen');
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

  testWidgets('gameplay_aim', (tester) async {
    // Plan View: Milo at 352–412, aiming at the glass.
    final sim = NightSim(Levels.night3)..setSneak(true);
    walkTo(sim, 382);
    await pumpGameplay(tester, sim);
    final g = await tester.startGesture(tester.getCenter(find.byType(ToolButton)));
    await g.moveBy(const Offset(-80, 0));
    await tester.pump();
    await snap(tester, 'gameplay_aim');
    await g.up();
  });

  testWidgets('gameplay_throw', (tester) async {
    final sim = NightSim(Levels.night3)..setSneak(true);
    walkTo(sim, 382);
    sim
      ..throwSock(62)
      ..tick(0.25)
      ..takeEvents();
    await pumpGameplay(tester, sim);
    await snap(tester, 'gameplay_throw');
  });

  testWidgets('gameplay_mouse', (tester) async {
    final sim = NightSim(Levels.night3, setup: const NightSetup(tool: Tool.mouse))..setSneak(true);
    sim
      ..useTool()
      ..tick(0.8)
      ..takeEvents();
    await pumpGameplay(tester, sim);
    await snap(tester, 'gameplay_mouse');
  });

  testWidgets('gameplay_marbles', (tester) async {
    final sim = NightSim(Levels.night3, setup: const NightSetup(tool: Tool.marbles))..setSneak(true);
    walkTo(sim, 561);
    tickUntil(sim, () => !sim.goose.rollingOver);
    sim.grab('egg');
    sim.setSneak(false);
    walkTo(sim, 721);
    sim
      ..useTool()
      ..takeEvents();
    await pumpGameplay(tester, sim);
    await snap(tester, 'gameplay_marbles');
  });

  testWidgets('gameplay_slip', (tester) async {
    final sim = NightSim(Levels.night3, setup: const NightSetup(tool: Tool.marbles))..setSneak(true);
    walkTo(sim, 561);
    tickUntil(sim, () => !sim.goose.rollingOver);
    sim.grab('egg');
    sim.setSneak(false);
    walkTo(sim, 621);
    sim
      ..takeEvents()
      ..useTool();
    tickUntil(sim, () => sim.goose.slipping);
    sim.tick(0.1);
    await pumpGameplay(tester, sim);
    await play(tester, 0.05);
    await snap(tester, 'gameplay_slip');
  });

  testWidgets('gameplay_carry', (tester) async {
    final sim = NightSim(Levels.night3)..setSneak(true);
    walkTo(sim, 113);
    sim.interact();
    walkTo(sim, 300);
    await pumpGameplay(tester, sim);
    await snap(tester, 'gameplay_carry');
  });

  testWidgets('gameplay_hidden', (tester) async {
    final sim = NightSim(Levels.night3)..setSneak(true);
    walkTo(sim, 703);
    sim
      ..toggleHide()
      ..poke('sideTable');
    tickUntil(sim, () => sim.goose.state == GooseState.chase);
    sim.takeEvents();
    await pumpGameplay(tester, sim);
    await snap(tester, 'gameplay_hidden');
  });

  testWidgets('gameplay_crawl', (tester) async {
    final sim = NightSim(Levels.night3)..setSneak(true);
    walkTo(sim, 260);
    sim.toggleClimb();
    walkTo(sim, 353);
    await pumpGameplay(tester, sim);
    await snap(tester, 'gameplay_crawl');
  });

  testWidgets('gameplay_cabinet', (tester) async {
    final sim = NightSim(Levels.night3)..setSneak(true);
    walkTo(sim, 148);
    sim.toggleHide();
    await pumpGameplay(tester, sim);
    await snap(tester, 'gameplay_cabinet');
  });

  testWidgets('gameplay_place', (tester) async {
    final sim = NightSim(Levels.night3)..setSneak(true);
    walkTo(sim, 113);
    sim.interact();
    walkTo(sim, 596);
    sim.place('underSideTable');
    walkTo(sim, 372);
    await pumpGameplay(tester, sim);
    await snap(tester, 'gameplay_place');
  });

  testWidgets('gameplay_combo', (tester) async {
    // Over the loose plank and back three times, then into the coat rack:
    // plank, clock, plank, clock... one combo.
    final sim = NightSim(Levels.night3)..setSneak(true);
    walkTo(sim, 600);
    sim.setSneak(false);
    walkTo(sim, 650);
    walkTo(sim, 630);
    walkTo(sim, 650);
    walkTo(sim, 703);
    sim.toggleHide();
    tickUntil(sim, () => sim.combo.count >= 4);
    await pumpGameplay(tester, sim);
    await snap(tester, 'gameplay_combo');
  });

  testWidgets('gameplay_combo_asleep', (tester) async {
    // Glass → pot lures her, then the books: a 3-link combo while she sleeps.
    final sim = NightSim(Levels.night3);
    sim.poke('counterLeft');
    tickUntil(sim, () => sim.combo.count >= 2);
    sim.poke('shelfBooks');
    tickUntil(sim, () => sim.combo.count >= 3);
    await pumpGameplay(tester, sim);
    await snap(tester, 'gameplay_combo_asleep');
  });
}
