import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/art/art.dart';
import 'package:jangan_bangunin_angsa_app/game/goose_brain.dart';
import 'package:jangan_bangunin_angsa_app/game/night_sim.dart';
import 'package:jangan_bangunin_angsa_app/game/tools.dart';
import 'package:jangan_bangunin_angsa_app/screens/caught_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/gameplay_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/pause_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/victory_screen.dart';
import 'package:jangan_bangunin_angsa_app/state/game_settings.dart';
import 'package:jangan_bangunin_angsa_app/state/levels.dart';
import 'package:jangan_bangunin_angsa_app/widgets/chunky_button.dart';
import 'package:jangan_bangunin_angsa_app/widgets/hud.dart';
import 'package:jangan_bangunin_angsa_app/widgets/joystick.dart';
import 'package:jangan_bangunin_angsa_app/widgets/tool_button.dart';

import 'game/fixtures.dart';
import 'helpers.dart';

Finder _prop(PropKind kind) => find.byWidgetPredicate((w) => w is Prop && w.kind == kind);

ActionButton _interact(WidgetTester tester) => tester.widget<ActionButton>(find.byType(ActionButton));

Future<void> _tapPause(WidgetTester tester) =>
    tester.tap(find.byWidgetPredicate((w) => w is RoundIconButton && w.semanticLabel == 'Pause'), warnIfMissed: false);

void main() {
  testWidgets('the joystick walks Milo right', (tester) async {
    await pumpGameplay(tester);
    final before = tester.getTopLeft(find.byType(Burglar)).dx;
    final g = await tester.startGesture(tester.getCenter(find.byType(Joystick)));
    await g.moveBy(const Offset(30, 0));
    await play(tester, 0.5);
    expect(tester.getTopLeft(find.byType(Burglar)).dx, closeTo(before + 30, 2)); // sneaking, 60px/s
    await g.up();
  });

  testWidgets('GRAB takes the toaster', (tester) async {
    await pumpGameplay(tester);
    expect(_prop(PropKind.toaster), findsNWidgets(2)); // on the counter and in the HUD slot
    await tester.tap(find.text('GRAB'));
    await play(tester, 0.05);
    expect(find.text('1/3'), findsOneWidget);
    expect(_prop(PropKind.toaster), findsOneWidget);
    final slot = tester.widget<LootSlot>(find.byWidgetPredicate((w) => w is LootSlot && w.kind == PropKind.toaster));
    expect(slot.state, LootState.stolen);
  });

  testWidgets('WIND sets off the robot', (tester) async {
    final sim = NightSim(Levels.night3)..setSneak(true);
    walkTo(sim, 614);
    await pumpGameplay(tester, sim);
    expect(find.text('WIND'), findsOneWidget);
    await tester.tap(find.text('WIND'));
    await play(tester, 0.1);
    expect(sim.chain.isSpent('robot'), isTrue);
  });

  testWidgets('nothing in reach disables Interact', (tester) async {
    final sim = NightSim(Levels.night3);
    walkTo(sim, 300);
    await pumpGameplay(tester, sim);
    expect(_interact(tester).onPressed, isNull);
  });

  testWidgets('the alert meter follows the goose', (tester) async {
    final sim = NightSim(Levels.night3);
    walkTo(sim, 420); // at a walk, footsteps inside her ear zone
    await pumpGameplay(tester, sim);
    await play(tester, 0.1);
    final meter = tester.widget<AlertMeter>(find.byType(AlertMeter));
    expect(meter.value, sim.goose.meter.value);
    expect(meter.value, greaterThan(0));
  });

  testWidgets('a long frame advances at most 0.1s', (tester) async {
    final sim = await pumpGameplay(tester);
    await tester.pump(const Duration(seconds: 5));
    expect(sim.elapsed, lessThanOrEqualTo(0.1 + 1e-9));
  });

  testWidgets('pause stops the night', (tester) async {
    final sim = await pumpGameplay(tester);
    await play(tester, 0.2);
    await _tapPause(tester);
    await play(tester, 0.3);
    expect(find.byType(PauseScreen), findsOneWidget);
    final t = sim.elapsed;
    await play(tester, 1);
    expect(sim.elapsed, t);
    await tester.tap(find.text('Resume'));
    await play(tester, 0.5);
    expect(sim.elapsed, greaterThan(t));
  });

  testWidgets('backgrounding opens Pause', (tester) async {
    await pumpGameplay(tester);
    addTearDown(() => tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await play(tester, 0.3);
    expect(find.byType(PauseScreen), findsOneWidget);
  });

  testWidgets('reaching the exit opens Victory with the loot', (tester) async {
    final sim = NightSim(Levels.night3)..setSneak(true);
    sim.interact();
    walkTo(sim, 760);
    await pumpGameplay(tester, sim);
    final g = await tester.startGesture(tester.getCenter(find.byType(Joystick)));
    await g.moveBy(const Offset(30, 0));
    await play(tester, 0.6);
    await g.up();
    expect(find.byType(VictoryScreen), findsOneWidget);
    expect(find.byType(GameplayScreen), findsNothing);
    expect(find.text('Mega Toaster'), findsOneWidget);
  });

  testWidgets('the night ends once', (tester) async {
    final sim = NightSim(Levels.night3)..setSneak(true);
    walkTo(sim, 768);
    sim.setMove(1);
    await pumpGameplay(tester, sim);
    for (var i = 0; i < 30 && sim.outcome == null; i++) {
      await tester.pump(const Duration(microseconds: 16667));
    }
    expect(sim.outcome, Outcome.escaped);
    await _tapPause(tester); // lands on the screen as it fades out
    await play(tester, 0.6);
    expect(find.byType(VictoryScreen), findsOneWidget);
    expect(find.byType(PauseScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  group('on screen', () {
    /// Milo by the nest, the egg just grabbed outside her roll-over: HONK.
    NightSim wokenByTheEgg() {
      final sim = NightSim(Levels.night3)..setSneak(true);
      walkTo(sim, 561);
      tickUntil(sim, () => !sim.goose.rollingOver);
      expect(sim.grab('egg'), isFalse);
      expect(sim.goose.state, GooseState.awake);
      return sim;
    }

    Finder badge(int n) => find.byWidgetPredicate((w) => w is LinkBadge && w.number == n);

    testWidgets('a chain counts up its badges 0.4s apart', (tester) async {
      final sim = NightSim(Levels.night3);
      walkTo(sim, 62);
      sim.poke('counterLeft');
      await pumpGameplay(tester, sim);
      await play(tester, 0.05);
      expect(badge(1), findsOneWidget);
      expect(badge(2), findsNothing);
      await play(tester, 0.4);
      expect(badge(2), findsOneWidget);
      expect(find.text('CLANG!'), findsWidgets);
    });

    testWidgets('HONK freezes the night for 0.3s', (tester) async {
      final sim = await pumpGameplay(tester, wokenByTheEgg());
      expect(find.text('HONK!'), findsWidgets);
      final t = sim.elapsed;
      await play(tester, 0.25);
      expect(sim.elapsed, t);
      await play(tester, 0.1);
      expect(sim.elapsed, greaterThan(t));
    });

    double nudge(WidgetTester tester) =>
        tester.widget<Transform>(find.byKey(GameplayScreen.sceneKey)).transform.getTranslation().x;

    testWidgets('Interact does nothing during the freeze-frame', (tester) async {
      final sim = await pumpGameplay(tester, wokenByTheEgg());
      await tester.tap(find.text('GRAB'));
      await tester.pump();
      expect(sim.carried, isEmpty);
    });

    testWidgets('system back pauses the night instead of leaving it', (tester) async {
      await pumpGameplay(tester);
      await tester.binding.handlePopRoute();
      await play(tester, 0.3);
      expect(find.byType(PauseScreen), findsOneWidget);
    });

    testWidgets('the HONK nudge is 4px', (tester) async {
      await pumpGameplay(tester, wokenByTheEgg());
      expect(nudge(tester), 4);
      await play(tester, 0.4);
      expect(nudge(tester), 0);
    });

    testWidgets('reduced shake turns the nudge off', (tester) async {
      final before = GameSettings.instance.reduceShake;
      addTearDown(() => GameSettings.instance.reduceShake = before);
      GameSettings.instance.reduceShake = true;
      await pumpGameplay(tester, wokenByTheEgg());
      expect(nudge(tester), 0);
    });

    testWidgets('the chase shows the frame and the CHASE pill', (tester) async {
      final sim = await pumpGameplay(tester, wokenByTheEgg());
      expect(find.text('CHASE'), findsNothing);
      await play(tester, 0.7);
      expect(sim.goose.state, GooseState.chase);
      expect(find.text('CHASE'), findsOneWidget);
      expect(find.byKey(GameplayScreen.chaseFrameKey), findsOneWidget);
    });

    testWidgets('caught: the tableau, then the Caught screen after 1.2s', (tester) async {
      final sim = await pumpGameplay(tester, wokenByTheEgg());
      for (
        var i = 0;
        i < 120 && !find.byWidgetPredicate((w) => w is Burglar && w.pose == BurglarPose.caught).evaluate().isNotEmpty;
        i++
      ) {
        await tester.pump(const Duration(microseconds: 16667));
      }
      expect(find.byWidgetPredicate((w) => w is Burglar && w.pose == BurglarPose.caught), findsOneWidget);
      expect(sim.outcome, isNull);
      expect(find.byKey(GameplayScreen.speedLinesKey), findsNothing);
      await play(tester, 1.5);
      expect(find.byType(CaughtScreen), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Prop && w.kind == PropKind.egg), findsOneWidget);
    });
  });

  group('tool button', () {
    Offset toolCenter(WidgetTester tester) => tester.getCenter(find.byType(ToolButton));
    ToolButton toolButton(WidgetTester tester) => tester.widget<ToolButton>(find.byType(ToolButton));

    testWidgets('hold, drag and release throws a sock', (tester) async {
      final sim = await pumpGameplay(tester);
      expect(find.text('×3'), findsOneWidget);
      final g = await tester.startGesture(toolCenter(tester));
      await g.moveBy(const Offset(-40, 0));
      await play(tester, 0.05);
      expect(toolButton(tester).aiming, isTrue);
      await g.up();
      await play(tester, 0.05);
      expect(sim.flights, hasLength(1));
      expect(sim.flights.single.toX, closeTo(sim.playerX - 160, 1));
      expect(sim.toolLeft, 2);
      expect(find.text('×2'), findsOneWidget);
      expect(toolButton(tester).aiming, isFalse);
      await play(tester, 0.6);
      expect(sim.flights, isEmpty);
    });

    testWidgets('a tap without a drag throws nothing', (tester) async {
      final sim = await pumpGameplay(tester);
      await tester.tap(find.byType(ToolButton));
      await play(tester, 0.05);
      expect(sim.toolLeft, 3);
    });

    testWidgets('letting go far off the button still throws', (tester) async {
      final sim = await pumpGameplay(tester);
      final g = await tester.startGesture(toolCenter(tester));
      await g.moveBy(const Offset(-200, -150));
      await g.up();
      await play(tester, 0.05);
      expect(sim.toolLeft, 2);
    });

    testWidgets('the joystick keeps working while aiming', (tester) async {
      final sim = await pumpGameplay(tester);
      final x = sim.playerX;
      final aim = await tester.startGesture(toolCenter(tester), pointer: 7);
      await aim.moveBy(const Offset(-30, 0));
      final walk = await tester.startGesture(tester.getCenter(find.byType(Joystick)), pointer: 8);
      await walk.moveBy(const Offset(30, 0));
      await play(tester, 0.5);
      expect(sim.playerX, greaterThan(x + 20));
      await walk.up();
      await aim.up();
      await play(tester, 0.05);
      expect(sim.toolLeft, 2);
    });

    testWidgets('a release during the HONK freeze throws nothing', (tester) async {
      final sim = NightSim(Levels.night3)..setSneak(true);
      walkTo(sim, 561);
      tickUntil(sim, () => !sim.goose.rollingOver);
      sim.grab('egg');
      await pumpGameplay(tester, sim);
      await play(tester, 0.05);
      final g = await tester.startGesture(toolCenter(tester));
      await g.moveBy(const Offset(-40, 0));
      await g.up();
      await play(tester, 0.05);
      expect(sim.toolLeft, 3);
    });

    testWidgets('an aim begun before HONK and let go in the freeze throws nothing', (tester) async {
      final sim = NightSim(Levels.night3)..setSneak(true);
      walkTo(sim, 561);
      tickUntil(sim, () => !sim.goose.rollingOver);
      await pumpGameplay(tester, sim);
      final g = await tester.startGesture(toolCenter(tester));
      await g.moveBy(const Offset(-40, 0));
      sim.grab('egg');
      await play(tester, 0.05);
      await g.up();
      await play(tester, 0.05);
      expect(sim.toolLeft, 3);
    });

    testWidgets('a cancelled touch throws nothing', (tester) async {
      final sim = await pumpGameplay(tester);
      final g = await tester.startGesture(toolCenter(tester));
      await g.moveBy(const Offset(-40, 0));
      await g.cancel();
      await play(tester, 0.05);
      expect(sim.toolLeft, 3);
      expect(toolButton(tester).aiming, isFalse);
    });

    testWidgets('pausing mid-aim drops the aim', (tester) async {
      final sim = await pumpGameplay(tester);
      final g = await tester.startGesture(toolCenter(tester), pointer: 7);
      await g.moveBy(const Offset(-40, 0));
      await _tapPause(tester);
      await play(tester, 0.3);
      await g.up();
      await play(tester, 0.05);
      expect(sim.toolLeft, 3);
    });

    testWidgets('marbles stay dim while she sleeps', (tester) async {
      final sim = await pumpGameplay(tester, NightSim(Levels.night3, tool: Tool.marbles));
      expect(toolButton(tester).ready, isFalse);
      await tester.tap(find.byType(ToolButton), warnIfMissed: false);
      await play(tester, 0.05);
      expect(sim.toolLeft, 1);
    });

    testWidgets('a tap sets the mouse down', (tester) async {
      final sim = await pumpGameplay(tester, NightSim(Levels.night3, tool: Tool.mouse));
      expect(toolButton(tester).ready, isTrue);
      await tester.tap(find.byType(ToolButton));
      await play(tester, 0.05);
      expect(sim.mouse, isNotNull);
      expect(find.text('×0'), findsOneWidget);
      expect(toolButton(tester).ready, isFalse);
    });
  });

  group('rearrange, hide, crawl', () {
    NightSim sneakTo(double x) {
      final sim = NightSim(Levels.night3)..setSneak(true);
      walkTo(sim, x);
      return sim;
    }

    Future<void> tapInteract(WidgetTester tester, String label) async {
      await tester.tap(find.widgetWithText(ActionButton, label));
      await play(tester, 0.1);
    }

    testWidgets('MOVE POT lifts the pot over his head', (tester) async {
      final sim = await pumpGameplay(tester, sneakTo(113));
      await tapInteract(tester, 'MOVE POT');
      expect(sim.held, 'pot');
      final milo = tester.widget<Burglar>(find.byType(Burglar));
      expect(milo.pose, BurglarPose.carry);
      expect(tester.getTopLeft(_prop(PropKind.pot)).dy, lessThan(tester.getTopLeft(find.byType(Burglar)).dy));
    });

    testWidgets('PLACE puts the pot down under the shelf', (tester) async {
      final sim = sneakTo(113);
      sim.interact();
      walkTo(sim, 372);
      await pumpGameplay(tester, sim);
      await tapInteract(tester, 'PLACE');
      expect(sim.chain.spotOf('pot'), 'underShelf');
      expect(tester.getTopLeft(_prop(PropKind.pot)), const Offset(347, 232));
    });

    testWidgets('HIDE hides Milo and OUT brings him back', (tester) async {
      final sim = await pumpGameplay(tester, sneakTo(148));
      expect(find.text('HIDE'), findsNWidgets(2)); // the tag and the button
      await tapInteract(tester, 'HIDE');
      expect(sim.hidden, isTrue);
      expect(find.byType(Burglar), findsNothing);
      await tapInteract(tester, 'OUT');
      expect(sim.hidden, isFalse);
      expect(find.byType(Burglar), findsOneWidget);
    });

    testWidgets('no HIDE tag out of reach while she sleeps', (tester) async {
      await pumpGameplay(tester);
      expect(find.text('HIDE'), findsNothing);
    });

    testWidgets('CLIMB puts Milo on the crawlway, crawling', (tester) async {
      final sim = await pumpGameplay(tester, sneakTo(260));
      await tapInteract(tester, 'CLIMB');
      expect(sim.up, isTrue);
      expect(tester.widget<Burglar>(find.byType(Burglar)).pose, BurglarPose.crawl);
      expect(tester.getTopLeft(find.byType(Burglar)).dy, 106 - 74);
      expect(find.widgetWithText(ActionButton, 'DOWN'), findsOneWidget);
    });

    testWidgets('hands full and no snap spot in reach: a dim PLACE, not GRAB', (tester) async {
      final sim = sneakTo(113);
      sim.interact();
      walkTo(sim, 250);
      await pumpGameplay(tester, sim);
      expect(find.text('GRAB'), findsNothing);
      expect(_interact(tester).label, 'PLACE');
      expect(_interact(tester).onPressed, isNull);
    });

    testWidgets('the chicken shows in front of Milo while he crawls up to it', (tester) async {
      final sim = sneakTo(260);
      sim.toggleClimb();
      walkTo(sim, 353);
      await pumpGameplay(tester, sim);
      final order = tester
          .widgetList(find.byWidgetPredicate((w) => w is Burglar || (w is Prop && w.kind == PropKind.chicken && w.size == 46)))
          .toList();
      expect(order.indexWhere((w) => w is Prop), greaterThan(order.indexWhere((w) => w is Burglar)));
    });
  });
}
