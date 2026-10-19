import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/art/art.dart';
import 'package:jangan_bangunin_angsa_app/game/goose_brain.dart';
import 'package:jangan_bangunin_angsa_app/game/heist.dart';
import 'package:jangan_bangunin_angsa_app/game/level.dart';
import 'package:jangan_bangunin_angsa_app/game/night_sim.dart';
import 'package:jangan_bangunin_angsa_app/game/tools.dart';
import 'package:jangan_bangunin_angsa_app/screens/caught_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/victory_screen.dart';
import 'package:jangan_bangunin_angsa_app/state/heist_log.dart';
import 'package:jangan_bangunin_angsa_app/theme/palette.dart';
import 'package:jangan_bangunin_angsa_app/art/icons.dart';
import 'package:jangan_bangunin_angsa_app/widgets/hud.dart';

import 'game/fixtures.dart';
import 'helpers.dart';

void main() {
  tearDown(HeistLog.instance.clear);

  /// Prop kinds in the "what woke her" recap, left to right.
  List<PropKind> recap(WidgetTester tester) {
    final props = find.descendant(of: find.byKey(CaughtScreen.recapKey), matching: find.byType(Prop));
    final found = props.evaluate().map((e) => (e.widget as Prop, tester.getTopLeft(find.byWidget(e.widget)).dx)).toList()
      ..sort((a, b) => a.$2.compareTo(b.$2));
    return [for (final (p, _) in found) p.kind];
  }

  testWidgets('Caught recaps the chain in order', (tester) async {
    await pumpScreen(tester, CaughtScreen(result: sampleCaught()));
    expect(recap(tester), [PropKind.glass, PropKind.pot, PropKind.robot]);
    expect(find.text('HONK'), findsOneWidget);
    expect(find.textContaining('robot marches'), findsOneWidget);
  });

  testWidgets('Caught without a chain shows the footsteps', (tester) async {
    await pumpScreen(tester, CaughtScreen(result: sampleCaught(chain: [], cause: WakeCause.footsteps)));
    expect(find.descendant(of: find.byKey(CaughtScreen.recapKey), matching: find.byType(Burglar)), findsOneWidget);
    expect(find.textContaining('Sneak'), findsOneWidget);
  });

  testWidgets('Caught: grabbing the egg', (tester) async {
    await pumpScreen(tester, CaughtScreen(result: sampleCaught(chain: [], cause: WakeCause.grabbedGuarded)));
    expect(recap(tester), [PropKind.egg]);
    expect(find.textContaining('roll-over'), findsOneWidget);
  });

  testWidgets('a kazoo wake shows the kazoo and its tip', (tester) async {
    await pumpScreen(tester, CaughtScreen(result: sampleCaught(chain: [], cause: WakeCause.tool, tool: Tool.kazoo)));
    expect(recap(tester), [PropKind.kazoo]);
    expect(find.textContaining('kazoo is loud'), findsOneWidget);
  });

  testWidgets('a missed sock wake shows the sock and its tip', (tester) async {
    await pumpScreen(tester, CaughtScreen(result: sampleCaught(chain: [], cause: WakeCause.tool)));
    expect(recap(tester), [PropKind.sock]);
    expect(find.textContaining('sock that misses'), findsOneWidget);
  });

  testWidgets('a six-link chain fits', (tester) async {
    await pumpScreen(
      tester,
      CaughtScreen(result: sampleCaught(chain: ['glass', 'pot', 'books', 'robot', 'plank', 'clock'])),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Victory shows what was taken', (tester) async {
    await pumpScreen(tester, VictoryScreen(result: sampleEscape(loot: ['toaster'])));
    expect(find.byType(CheckBadge), findsOneWidget);
    expect(find.text('Morning. The Mega Toaster is gone.'), findsOneWidget);
  });

  testWidgets('Victory names the egg first', (tester) async {
    await pumpScreen(tester, VictoryScreen(result: sampleEscape(loot: ['egg', 'toaster'])));
    expect(find.byType(CheckBadge), findsNWidgets(2));
    expect(find.text('Morning. The Golden Egg is gone.'), findsOneWidget);
  });

  testWidgets('Victory time is m:ss', (tester) async {
    await pumpScreen(tester, VictoryScreen(result: sampleEscape(time: 167.9)));
    expect(find.text('2:47'), findsOneWidget);
  });

  testWidgets('empty-handed', (tester) async {
    await pumpScreen(tester, VictoryScreen(result: sampleEscape(loot: [])));
    expect(find.text('Morning. Nothing is missing.'), findsOneWidget);
    expect(find.byType(CheckBadge), findsNothing);
  });

  testWidgets('Victory shows the style badge and score', (tester) async {
    await pumpScreen(tester, VictoryScreen(result: sampleEscape()));
    expect(find.text('Trickster'), findsOneWidget);
    expect(find.text('Best chain ×6'), findsOneWidget);
    expect(find.text('8,450'), findsOneWidget);
  });

  testWidgets('Victory sub line without a chain', (tester) async {
    await pumpScreen(tester, VictoryScreen(result: sampleEscape(bestChain: 0, lures: 0, style: PlayStyle.ghost)));
    expect(find.text('Ghost'), findsOneWidget);
    expect(find.text('Not a peep'), findsOneWidget);
    await pumpScreen(tester, VictoryScreen(result: sampleEscape(bestChain: 1, lures: 3)));
    expect(find.text('Lured ×3'), findsOneWidget);
  });

  testWidgets('Victory recap line', (tester) async {
    await pumpScreen(tester, VictoryScreen(result: sampleEscape()));
    expect(
      find.bySemanticsLabel('✓ Lured her out twice · ✓ 5+ link chain · ✗ Never seen — try a Ghost run for the last sock.'),
      findsOneWidget,
    );
    await pumpScreen(tester, VictoryScreen(result: sampleEscape(goalsMet: PlayStyle.values.toSet())));
    expect(find.bySemanticsLabel(RegExp('— every sock tonight!\$')), findsOneWidget);
    await pumpScreen(tester, VictoryScreen(result: sampleEscape(goalsMet: {})));
    expect(find.bySemanticsLabel(RegExp(r'— try a Ghost run for another sock\.$')), findsOneWidget);
  });

  testWidgets('Victory socks', (tester) async {
    HeistLog.instance.record(sampleEscape(goalsMet: {PlayStyle.ghost}));
    await pumpScreen(tester, VictoryScreen(result: sampleEscape()));
    final fills = tester.widgetList<SockGlyph>(find.byType(SockGlyph)).map((s) => s.fill);
    expect(fills, [Palette.calmMint, Palette.lamp, Palette.lamp]);
    expect(find.bySemanticsLabel('Heist goals 3 of 3 socks'), findsOneWidget);
  });

  testWidgets('Victory with no goals', (tester) async {
    final result = NightResult(level: Level.parse(minimalLevel()), outcome: Outcome.escaped, loot: const [], time: 5);
    await pumpScreen(tester, VictoryScreen(result: result));
    expect(tester.takeException(), isNull);
    expect(find.byType(SockGlyph), findsNothing);
    expect(find.bySemanticsLabel(RegExp('—')), findsNothing);
  });

  testWidgets('the hint counts socks earned on earlier runs', (tester) async {
    HeistLog.instance.record(sampleEscape(goalsMet: {PlayStyle.ghost}));
    await pumpScreen(tester, VictoryScreen(result: sampleEscape()));
    expect(find.bySemanticsLabel(RegExp(r'✗ Never seen — every sock collected!$')), findsOneWidget);

    HeistLog.instance
      ..clear()
      ..record(sampleEscape(goalsMet: {PlayStyle.trickster}));
    await pumpScreen(tester, VictoryScreen(result: sampleEscape(goalsMet: {PlayStyle.chaos})));
    expect(find.bySemanticsLabel(RegExp(r'— try a Ghost run for the last sock\.$')), findsOneWidget);
  });

  testWidgets('a long score stays on one line', (tester) async {
    await pumpScreen(tester, VictoryScreen(result: sampleEscape(score: 24615400)));
    expect(tester.getSize(find.text('24,615,400')).height, lessThan(30));
    expect(tester.getBottomLeft(find.text('STYLE')).dy, lessThan(290));
    expect(tester.takeException(), isNull);
  });
}
