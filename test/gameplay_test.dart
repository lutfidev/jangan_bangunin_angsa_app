import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/art/art.dart';
import 'package:jangan_bangunin_angsa_app/game/goose_brain.dart';
import 'package:jangan_bangunin_angsa_app/game/night_sim.dart';
import 'package:jangan_bangunin_angsa_app/screens/caught_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/gameplay_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/pause_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/victory_screen.dart';
import 'package:jangan_bangunin_angsa_app/state/game_settings.dart';
import 'package:jangan_bangunin_angsa_app/state/levels.dart';
import 'package:jangan_bangunin_angsa_app/widgets/chunky_button.dart';
import 'package:jangan_bangunin_angsa_app/widgets/hud.dart';
import 'package:jangan_bangunin_angsa_app/widgets/joystick.dart';

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

  testWidgets('NUDGE sets off the glass', (tester) async {
    final sim = NightSim(Levels.night3);
    walkTo(sim, 62);
    await pumpGameplay(tester, sim);
    expect(find.text('NUDGE'), findsOneWidget);
    await tester.tap(find.text('NUDGE'));
    await play(tester, 0.1);
    expect(sim.chain.isSpent('glass'), isTrue);
  });

  testWidgets('nothing in reach disables Interact', (tester) async {
    final sim = NightSim(Levels.night3);
    walkTo(sim, 280);
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
      await pumpGameplay(tester, sim);
      await tester.tap(find.text('NUDGE'));
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
}
