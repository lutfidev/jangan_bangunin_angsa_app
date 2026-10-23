import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/geom.dart';
import 'package:jangan_bangunin_angsa_app/art/art.dart';
import 'package:jangan_bangunin_angsa_app/game/goose_brain.dart';
import 'package:jangan_bangunin_angsa_app/game/heist.dart';
import 'package:jangan_bangunin_angsa_app/game/night_sim.dart';
import 'package:jangan_bangunin_angsa_app/game/modifiers.dart';
import 'package:jangan_bangunin_angsa_app/game/noise.dart';
import 'package:jangan_bangunin_angsa_app/game/remix.dart';
import 'package:jangan_bangunin_angsa_app/game/tools.dart';
import 'package:jangan_bangunin_angsa_app/screens/caught_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/gameplay_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/night_art.dart';
import 'package:jangan_bangunin_angsa_app/screens/pause_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/victory_screen.dart';
import 'package:jangan_bangunin_angsa_app/state/game_settings.dart';
import 'package:jangan_bangunin_angsa_app/state/heist_log.dart';
import 'package:jangan_bangunin_angsa_app/state/levels.dart';
import 'package:jangan_bangunin_angsa_app/main.dart';
import 'package:jangan_bangunin_angsa_app/theme/palette.dart';
import 'package:jangan_bangunin_angsa_app/widgets/chunky_button.dart';
import 'package:jangan_bangunin_angsa_app/widgets/goose_arrow.dart';
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
  tearDown(HeistLog.instance.clear);

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

  testWidgets('an escape records its socks', (tester) async {
    final sim = NightSim(Levels.night3)..setSneak(true);
    sim.interact(); // the toaster: no sock without loot
    walkTo(sim, 768);
    sim.setMove(1);
    await pumpGameplay(tester, sim);
    await play(tester, 0.6);
    expect(find.byType(VictoryScreen), findsOneWidget);
    expect(HeistLog.instance.earned('night3'), {PlayStyle.ghost});
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
      final sim = await pumpGameplay(tester, NightSim(Levels.night3, setup: const NightSetup(tool: Tool.marbles)));
      expect(toolButton(tester).ready, isFalse);
      await tester.tap(find.byType(ToolButton), warnIfMissed: false);
      await play(tester, 0.05);
      expect(sim.toolLeft, 1);
    });

    testWidgets('a tap sets the mouse down', (tester) async {
      final sim = await pumpGameplay(tester, NightSim(Levels.night3, setup: const NightSetup(tool: Tool.mouse)));
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

    testWidgets('no HIDE tags while she is up and Milo is up on the counter', (tester) async {
      final sim = sneakTo(260);
      climbTo(sim, 'counter');
      sim.goose.wake(WakeCause.noise);
      await pumpGameplay(tester, sim);
      expect(find.text('HIDE'), findsNothing);
    });

    testWidgets('no HIDE tags while she is up and Milo holds the pot', (tester) async {
      final sim = sneakTo(113);
      expect(sim.lift('pot'), isTrue);
      sim.goose.wake(WakeCause.noise);
      await pumpGameplay(tester, sim);
      expect(find.text('HIDE'), findsNothing);
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
      climbTo(sim, 'crawlPlank');
      walkTo(sim, 353);
      await pumpGameplay(tester, sim);
      final order = tester
          .widgetList(find.byWidgetPredicate((w) => w is Burglar || (w is Prop && w.kind == PropKind.chicken && w.size == 46)))
          .toList();
      expect(order.indexWhere((w) => w is Prop), greaterThan(order.indexWhere((w) => w is Burglar)));
    });
  });

  group('heist HUD', () {
    void earn(Set<PlayStyle> styles) => HeistLog.instance.record(sampleEscape(goalsMet: styles));

    testWidgets('the GOAL pill starts on Ghost', (tester) async {
      await pumpGameplay(tester);
      expect(find.text('Never let her turn suspicious'), findsOneWidget);
    });

    testWidgets('the GOAL pill skips earned goals', (tester) async {
      earn({PlayStyle.ghost});
      await pumpGameplay(tester);
      expect(find.text('Lure her out of bed · 0/2'), findsOneWidget);
    });

    testWidgets('the GOAL pill skips a failed Ghost', (tester) async {
      final sim = NightSim(Levels.night3);
      sim.goose
        ..hear(const Noise(x: 480, loudness: 1))
        ..hear(const Noise(x: 480, loudness: 1));
      sim.tick(frame);
      expect(sim.seen, isTrue);
      await pumpGameplay(tester, sim);
      expect(find.text('Lure her out of bed · 0/2'), findsOneWidget);
    });

    testWidgets('with every sock earned the pill points at the exit', (tester) async {
      earn(PlayStyle.values.toSet());
      await pumpGameplay(tester);
      expect(find.text('Make it to the exit'), findsOneWidget);
    });

    testWidgets('a two-link chain while she sleeps keeps the meter, no banner', (tester) async {
      final sim = NightSim(Levels.night3);
      sim.poke('counterLeft'); // glass → pot
      tickUntil(sim, () => sim.combo.count >= 2);
      expect(sim.goose.isAwake, isFalse);
      await pumpGameplay(tester, sim);
      expect(find.byType(AlertMeter), findsOneWidget);
      expect(find.byKey(GameplayScreen.comboKey), findsNothing);
    });

    testWidgets('a bigger combo while she sleeps shows beside the meter', (tester) async {
      final sim = NightSim(Levels.night3);
      sim.poke('counterLeft'); // glass → pot
      tickUntil(sim, () => sim.combo.count >= 2);
      sim.poke('shelfBooks');
      tickUntil(sim, () => sim.combo.count >= 3);
      expect(sim.goose.isAwake, isFalse);
      await pumpGameplay(tester, sim);
      expect(find.byType(AlertMeter), findsOneWidget);
      expect(find.byKey(GameplayScreen.comboKey), findsOneWidget);
      expect(tester.getTopLeft(find.byKey(GameplayScreen.comboKey)).dx, greaterThan(552));
    });

    testWidgets('a combo shows the banner in place of the meter', (tester) async {
      final sim = NightSim(Levels.night3)..setSneak(true);
      walkTo(sim, 600);
      sim.setSneak(false);
      walkTo(sim, 650);
      walkTo(sim, 630);
      walkTo(sim, 703);
      sim.toggleHide();
      tickUntil(sim, () => sim.combo.count >= 2 && sim.goose.isAwake);
      await pumpGameplay(tester, sim);
      // The outlined text draws its words more than once.
      expect(find.descendant(of: find.byKey(GameplayScreen.comboKey), matching: find.text('CHAIN ×${sim.combo.count}!')), findsWidgets);
      expect(find.descendant(of: find.byKey(GameplayScreen.comboKey), matching: find.textContaining('CHAOS COMBO +')), findsOneWidget);
      expect(find.byType(AlertMeter), findsNothing);
      await play(tester, 6);
      expect(find.byKey(GameplayScreen.comboKey), findsNothing);
      expect(find.byType(AlertMeter), findsOneWidget);
    });
  });

  group('night setup', () {
    Finder inScene(Finder f) => find.descendant(of: find.byKey(GameplayScreen.sceneKey), matching: f);

    /// Every line of text in the room reads left to right.
    void expectReadable(WidgetTester tester) {
      final texts = inScene(find.byType(RichText));
      expect(texts, findsWidgets);
      for (final e in texts.evaluate()) {
        final scaleX = e.renderObject!.getTransformTo(null).storage[0];
        expect(scaleX, greaterThan(0), reason: (e.widget as RichText).text.toPlainText());
      }
    }

    testWidgets('a remixed night draws loot where the level put it', (tester) async {
      await pumpGameplay(tester, NightSim(Levels.night3.rearranged(lootAt: {'toaster': const Vec(60, 270)})));
      expect(tester.getTopLeft(inScene(_prop(PropKind.toaster))).dx, 60 - 32);
    });

    testWidgets('mirror draws the house flipped', (tester) async {
      final sim = await pumpGameplay(tester, NightSim(Levels.night3, setup: const NightSetup(mirror: true)));
      expect(tester.getCenter(find.byType(Burglar)).dx, closeTo(844 - sim.playerX, 1));
      expect(tester.getCenter(find.text('EXIT')).dx, lessThan(100));
    });

    testWidgets('mirror: joystick right walks Milo right on screen', (tester) async {
      final sim = await pumpGameplay(tester, NightSim(Levels.night3, setup: const NightSetup(mirror: true)));
      final start = sim.playerX;
      final before = tester.getTopLeft(find.byType(Burglar)).dx;
      final g = await tester.startGesture(tester.getCenter(find.byType(Joystick)));
      await g.moveBy(const Offset(30, 0));
      await play(tester, 0.5);
      expect(sim.playerX, lessThan(start));
      expect(tester.getTopLeft(find.byType(Burglar)).dx, greaterThan(before));
      await g.up();
    });

    testWidgets('mirror: a sock lands the way you drag', (tester) async {
      final sim = await pumpGameplay(tester, NightSim(Levels.night3, setup: const NightSetup(mirror: true)));
      final g = await tester.startGesture(tester.getCenter(find.byType(ToolButton)));
      await g.moveBy(const Offset(40, 0));
      await play(tester, 0.05);
      await g.up();
      await play(tester, 0.05);
      expect(sim.flights.single.toX, closeTo(sim.playerX - 160, 1));
    });

    testWidgets('mirror keeps every word readable', (tester) async {
      final sim = NightSim(Levels.night3, setup: const NightSetup(tool: Tool.kazoo, mirror: true));
      await pumpGameplay(tester, sim);
      expectReadable(tester); // EXIT, snores
      sim.poke('shelfBooks');
      await play(tester, 0.2);
      expectReadable(tester); // SFX word, link badge
      sim.useTool();
      await play(tester, 0.1);
      expect(find.text('HONK!'), findsWidgets); // outline and fill
      expectReadable(tester);
      await play(tester, 0.6);
      expectReadable(tester); // mid-chase
    });

    testWidgets('pause and restart keep the setup', (tester) async {
      const setup = NightSetup(tool: Tool.mouse, lightSleeper: true, remixSeed: 20261019);
      await pumpGameplay(tester, NightSim(remixed(Levels.night3, 20261019), setup: setup));
      await _tapPause(tester);
      await play(tester, 0.3);
      await tester.tap(find.text('Restart night'));
      await play(tester, 0.3);
      final screen = tester.widget<GameplayScreen>(find.byType(GameplayScreen));
      expect(screen.setup, setup);
    });

    testWidgets('retry replays the same remix', (tester) async {
      const seed = 20261019;
      final level = remixed(Levels.night3, seed);
      useStageSurface(tester);
      await tester.pumpWidget(MaterialApp(
        onGenerateRoute: MainApp.route,
        home: CaughtScreen(result: NightResult(
          level: level,
          outcome: Outcome.caught,
          loot: const [],
          time: 3,
          setup: const NightSetup(remixSeed: seed),
        )),
      ));
      await tester.pump();
      await tester.tap(find.text('Retry'));
      await play(tester, 0.3);
      for (final loot in level.loot.where((l) => !l.guarded)) {
        final kind = lootArt[loot.id]!.kind;
        expect(tester.getTopLeft(inScene(_prop(kind))).dx, lootBox(loot).left, reason: loot.id);
      }
    });
  });

  group('jump and climb', () {
    JumpButton jumpButton(WidgetTester tester) => tester.widget<JumpButton>(find.byType(JumpButton));
    double miloTop(WidgetTester tester) => tester.getTopLeft(find.byType(Burglar)).dy;

    NightSim sneakTo(double x, {NightSetup setup = const NightSetup()}) {
      final sim = NightSim(Levels.night3, setup: setup)..setSneak(true);
      walkTo(sim, x);
      return sim;
    }

    Future<void> pushStickUp(WidgetTester tester) async {
      final g = await tester.startGesture(tester.getCenter(find.byType(Joystick)));
      await g.moveBy(const Offset(0, -30));
      await play(tester, 0.6);
      await g.up();
      await play(tester, 0.05);
    }

    testWidgets('the control band follows board B', (tester) async {
      await pumpGameplay(tester);
      expect(tester.getTopLeft(find.byType(ToolButton)), const Offset(520, 318));
      expect(tester.getTopLeft(find.byType(SneakButton)), const Offset(588, 312));
      expect(tester.getTopLeft(find.byType(ActionButton)), const Offset(662, 290));
      expect(tester.getTopLeft(find.byType(JumpButton)), const Offset(752, 302));
    });

    testWidgets('JUMP jumps; at the start he lands on the counter', (tester) async {
      final sim = await pumpGameplay(tester);
      await tester.tap(find.byType(JumpButton));
      await play(tester, 0.1);
      expect(sim.grounded, isFalse);
      await play(tester, 0.2);
      expect(miloTop(tester), lessThan(156));
      await play(tester, 0.6);
      expect(sim.standingOn?.id, 'counter');
      expect(miloTop(tester), 126);
    });

    testWidgets('JUMP is lit on the floor', (tester) async {
      await pumpGameplay(tester);
      expect(jumpButton(tester).onPressed, isNotNull);
    });

    testWidgets('JUMP is dim while hidden', (tester) async {
      await pumpGameplay(tester, sneakTo(148)..toggleHide());
      expect(jumpButton(tester).onPressed, isNull);
    });

    testWidgets('JUMP is dim while holding the pot', (tester) async {
      final holding = sneakTo(113)..interact();
      expect(holding.held, 'pot');
      await pumpGameplay(tester, holding);
      expect(jumpButton(tester).onPressed, isNull);
    });

    testWidgets('JUMP is dim while crawling', (tester) async {
      final crawling = sneakTo(236);
      climbTo(crawling, 'crawlPlank');
      await pumpGameplay(tester, crawling);
      expect(jumpButton(tester).onPressed, isNull);
    });

    testWidgets('JUMP does nothing during the freeze-frame', (tester) async {
      final sim = NightSim(Levels.night3)..setSneak(true);
      walkTo(sim, 561);
      tickUntil(sim, () => !sim.goose.rollingOver);
      sim.grab('egg');
      await pumpGameplay(tester, sim);
      await tester.tap(find.byType(JumpButton));
      await play(tester, 0.4);
      expect(sim.playerY, 270);
    });

    testWidgets('in front of the counter the up arrow lights, and up climbs it', (tester) async {
      final sim = await pumpGameplay(tester, sneakTo(260));
      expect(find.byKey(Joystick.hintUpKey), findsOneWidget);
      expect(find.byKey(Joystick.hintDownKey), findsNothing);
      await pushStickUp(tester);
      expect(sim.playerY, 200);
      expect(miloTop(tester), 126);
      expect(find.byKey(Joystick.hintDownKey), findsOneWidget);
    });

    testWidgets('up on the crawl plank Milo crawls; no CLIMB or DOWN anywhere', (tester) async {
      final sim = sneakTo(236);
      climbTo(sim, 'crawlPlank');
      await pumpGameplay(tester, sim);
      expect(tester.widget<Burglar>(find.byType(Burglar)).pose, BurglarPose.crawl);
      expect(miloTop(tester), 106 - 74);
      expect(find.text('CLIMB'), findsNothing);
      expect(find.text('DOWN'), findsNothing);
    });

    testWidgets('the pot rides over his head up on the counter too', (tester) async {
      final sim = sneakTo(236);
      climbTo(sim, 'counter');
      walkTo(sim, 113);
      expect(sim.lift('pot'), isTrue);
      await pumpGameplay(tester, sim);
      expect(tester.getTopLeft(_prop(PropKind.pot)), const Offset(113 - 20, 200 - 102));
    });

    testWidgets('Mirror Night flips left and right, not up and down', (tester) async {
      final sim = await pumpGameplay(tester, sneakTo(260, setup: const NightSetup(mirror: true)));
      expect(find.byKey(Joystick.hintUpKey), findsOneWidget);
      await pushStickUp(tester);
      expect(sim.playerY, 200);
    });
  });

  group('house', () {
    NightSim inHouse() => NightSim(Levels.house, setup: const NightSetup(night: 'house'))..setSneak(true);

    double scroll(WidgetTester tester) =>
        tester.widget<Transform>(find.byKey(GameplayScreen.sceneKey)).transform.getTranslation().x;

    testWidgets('the room scrolls to follow Milo', (tester) async {
      final sim = inHouse();
      walkTo(sim, 620);
      sim.useDoor('kitchenDoor');
      walkTo(sim, 1000);
      await pumpGameplay(tester, sim);
      await play(tester, 0.2);
      expect(scroll(tester), closeTo(-(1000 + 120 - 422), 1));
    });

    double rise(WidgetTester tester) =>
        tester.widget<Transform>(find.byKey(GameplayScreen.sceneKey)).transform.getTranslation().y;

    testWidgets('the ground floor sits where the screen has its floor', (tester) async {
      await pumpGameplay(tester, inHouse());
      expect(rise(tester), -390);
    });

    testWidgets('upstairs the camera rises, and she is below', (tester) async {
      await pumpGameplay(tester, NightSim(houseWith({'playerStart': [1450, 270]}), setup: const NightSetup(night: 'house')));
      expect(rise(tester), 0);
      final arrow = find.byKey(GameplayScreen.gooseArrowKey);
      expect(tester.getTopLeft(arrow).dx, 8);
      expect(tester.widget<GooseArrow>(arrow).vertical, 1);
      expect(find.bySemanticsLabel('Gertrude is off screen, below'), findsOneWidget);
    });

    testWidgets('on a stair Milo is drawn over the floors', (tester) async {
      final sim = NightSim(houseWith({'playerStart': [1460, 270]}), setup: const NightSetup(night: 'house'))
        ..setVertical(1)
        ..tick(frame)
        ..setVertical(0);
      expect(sim.onStairs, isTrue);
      await pumpGameplay(tester, sim);
      expect(find.byKey(GameplayScreen.miloOverKey), findsOneWidget);
    });

    testWidgets('VENT at a vent mouth crawls him in', (tester) async {
      final sim = NightSim(houseWith({'playerStart': [80, 270]}), setup: const NightSetup(night: 'house'));
      await pumpGameplay(tester, sim);
      expect(_interact(tester).label, 'VENT');
      await tester.tap(find.text('VENT'));
      await tester.pump();
      expect(sim.inVent, isTrue);
      expect(find.byKey(GameplayScreen.miloOverKey), findsOneWidget);
    });

    testWidgets('night 3 never scrolls', (tester) async {
      final sim = NightSim(Levels.night3)..setSneak(true);
      walkTo(sim, 700);
      await pumpGameplay(tester, sim);
      await play(tester, 0.2);
      expect(scroll(tester), 0);
    });

    testWidgets('rooms out of view are not built', (tester) async {
      await pumpGameplay(tester, inHouse());
      expect(find.text('KITCHEN'), findsOneWidget);
      expect(find.text('HALL'), findsNothing);
    });

    testWidgets('walking into the hall builds it', (tester) async {
      final sim = inHouse();
      walkTo(sim, 620);
      sim.useDoor('kitchenDoor');
      walkTo(sim, 1600);
      await pumpGameplay(tester, sim);
      expect(find.text('HALL'), findsOneWidget);
      expect(find.text('KITCHEN'), findsNothing);
    });

    testWidgets('OPEN opens the door, then it offers CLOSE', (tester) async {
      final sim = inHouse();
      walkTo(sim, 620);
      await pumpGameplay(tester, sim);
      expect(_interact(tester).label, 'OPEN');
      await tester.tap(find.text('OPEN'));
      await tester.pump();
      expect(sim.doors.isOpen('kitchenDoor'), isTrue);
      expect(_interact(tester).label, 'CLOSE');
    });
  });

  group('goose arrow', () {
    NightSim inHouse({bool mirror = false}) =>
        NightSim(Levels.house, setup: NightSetup(night: 'house', mirror: mirror))..setSneak(true);
    final arrow = find.byKey(GameplayScreen.gooseArrowKey);
    Color colorOf(WidgetTester tester) => GooseArrow.colorFor(tester.widget<GooseArrow>(arrow).state);

    testWidgets('she sleeps off screen to the right', (tester) async {
      await pumpGameplay(tester, inHouse());
      expect(tester.getTopLeft(arrow).dx, 772);
      expect(tester.getTopLeft(arrow).dy, 160);
      expect(colorOf(tester), Palette.moonlight);
      expect(find.bySemanticsLabel('Gertrude is off screen to the right'), findsOneWidget);
    });

    testWidgets('it goes once she is on screen', (tester) async {
      final sim = inHouse();
      walkTo(sim, 620);
      sim.useDoor('kitchenDoor');
      walkTo(sim, 900);
      await pumpGameplay(tester, sim);
      expect(arrow, findsNothing);
    });

    testWidgets('Mirror Night puts it on the other edge', (tester) async {
      await pumpGameplay(tester, inHouse(mirror: true));
      expect(tester.getTopLeft(arrow).dx, 8);
      expect(find.bySemanticsLabel('Gertrude is off screen to the left'), findsOneWidget);
    });

    testWidgets('night 3 never shows it', (tester) async {
      await pumpGameplay(tester);
      expect(arrow, findsNothing);
    });

    testWidgets('chasing from off screen, it turns red', (tester) async {
      final sim = inHouse();
      walkTo(sim, 620);
      sim.useDoor('kitchenDoor');
      walkTo(sim, 1700);
      sim.poke('sideTable');
      tickUntil(sim, () => sim.goose.state == GooseState.chase);
      sim.takeEvents();
      await pumpGameplay(tester, sim);
      expect(tester.getTopLeft(arrow).dx, 8);
      expect(colorOf(tester), Palette.alarmTomato);
    });
  });

  group('debug overlay', () {
    final overlay = find.byKey(GameplayScreen.debugKey);

    testWidgets('off unless the debug tools are on', (tester) async {
      await pumpGameplay(tester, NightSim(Levels.house, setup: const NightSetup(night: 'house')));
      expect(find.text('DEBUG'), findsNothing);
      expect(overlay, findsNothing);
    });

    testWidgets('the DEBUG chip turns it on and off', (tester) async {
      await pumpGameplay(tester, NightSim(Levels.house, setup: const NightSetup(night: 'house')), true);
      expect(overlay, findsNothing);
      await tester.tap(find.text('DEBUG'));
      await tester.pump();
      expect(overlay, findsOneWidget);
      await play(tester, 0.5);
      await tester.tap(find.text('DEBUG'));
      await tester.pump();
      expect(overlay, findsNothing);
    });
  });
}
