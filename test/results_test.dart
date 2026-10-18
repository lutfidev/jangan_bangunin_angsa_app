import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/art/art.dart';
import 'package:jangan_bangunin_angsa_app/game/goose_brain.dart';
import 'package:jangan_bangunin_angsa_app/screens/caught_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/victory_screen.dart';
import 'package:jangan_bangunin_angsa_app/widgets/hud.dart';

import 'helpers.dart';

void main() {
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
}
