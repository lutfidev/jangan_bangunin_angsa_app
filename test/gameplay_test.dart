import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/art/art.dart';
import 'package:jangan_bangunin_angsa_app/game/night_sim.dart';
import 'package:jangan_bangunin_angsa_app/main.dart';
import 'package:jangan_bangunin_angsa_app/screens/gameplay_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/pause_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/victory_screen.dart';
import 'package:jangan_bangunin_angsa_app/state/levels.dart';
import 'package:jangan_bangunin_angsa_app/widgets/chunky_button.dart';
import 'package:jangan_bangunin_angsa_app/widgets/hud.dart';
import 'package:jangan_bangunin_angsa_app/widgets/joystick.dart';

import 'game/fixtures.dart';
import 'helpers.dart';

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
  await tester.pumpWidget(MaterialApp(onGenerateRoute: MainApp.route, home: GameplayScreen(sim: s)));
  await tester.pump();
  return s;
}

Finder _prop(PropKind kind) => find.byWidgetPredicate((w) => w is Prop && w.kind == kind);

ActionButton _interact(WidgetTester tester) => tester.widget<ActionButton>(find.byType(ActionButton));

Future<void> _tapPause(WidgetTester tester) => tester.tap(
  find.byWidgetPredicate((w) => w is RoundIconButton && w.semanticLabel == 'Pause'),
  warnIfMissed: false,
);

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
}
