import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/art/art.dart';
import 'package:jangan_bangunin_angsa_app/game/heist.dart';
import 'package:jangan_bangunin_angsa_app/screens/trophy_room_screen.dart';
import 'package:jangan_bangunin_angsa_app/state/heist_log.dart';
import 'package:jangan_bangunin_angsa_app/widgets/chunky_button.dart';

import 'helpers.dart';

/// The shelf's tile labels, in order.
List<String> _shelf(WidgetTester tester) => [
  for (final b in tester.widgetList<ChunkyButton>(find.byType(ChunkyButton)))
    if (b.semanticLabel != 'Back to main menu') b.semanticLabel!,
];

void main() {
  testWidgets('an empty log shows six locked tiles', (tester) async {
    await pumpScreen(tester, const TrophyRoomScreen());
    expect(find.text('0 / 4 pilfered'), findsOneWidget);
    expect(find.text('???'), findsNWidgets(6));
    expect(find.byWidgetPredicate((w) => w is Prop && w.kind == PropKind.toaster), findsNothing);
    // The first tile is picked; its card says how to get it.
    expect(find.text('NOT YET PILFERED'), findsOneWidget);
    expect(find.text('Carry it out of Night 3 · The Midnight Kitchen'), findsOneWidget);
  });

  testWidgets('stolen loot takes its place on the shelf', (tester) async {
    HeistLog.instance.record(sampleEscape(loot: ['toaster', 'egg'], goalsMet: {}));
    await pumpScreen(tester, const TrophyRoomScreen());
    expect(find.text('2 / 4 pilfered'), findsOneWidget);
    expect(find.text('Mega Toaster'), findsOneWidget);
    expect(find.text('Golden Egg'), findsOneWidget);
    expect(find.text('???'), findsNWidgets(4));
    expect(find.text('Oversized Toaster'), findsOneWidget); // picked: the detail card
    expect(find.text('Stolen on Night 3 · The Midnight Kitchen'), findsOneWidget);

    await tester.tap(find.text('Golden Egg'));
    await tester.pump();
    expect(find.text('GUARDED · PRICELESS'), findsOneWidget);
  });

  testWidgets('three socks earn the duck', (tester) async {
    HeistLog.instance.record(sampleEscape(loot: ['toaster', 'egg'], goalsMet: PlayStyle.values.toSet()));
    await pumpScreen(tester, const TrophyRoomScreen());
    expect(find.text('3 / 4 pilfered'), findsOneWidget);
    expect(find.text('Duck Trophy'), findsOneWidget);
    await tester.tap(find.text('Duck Trophy'));
    await tester.pump();
    expect(find.text('Earned: all 3 socks on Night 3'), findsOneWidget);
  });

  testWidgets('the teasers point at later nights', (tester) async {
    await pumpScreen(tester, const TrophyRoomScreen());
    final teaser = find.byWidgetPredicate((w) => w is ChunkyButton && w.semanticLabel == 'Locked').last;
    await tester.tap(teaser);
    await tester.pump();
    expect(find.text('Coming on a later night'), findsOneWidget);
  });

  testWidgets('the room follows the log', (tester) async {
    await pumpScreen(tester, const TrophyRoomScreen());
    HeistLog.instance.record(sampleEscape(loot: ['chicken'], goalsMet: {}));
    await tester.pump();
    expect(find.text('1 / 4 pilfered'), findsOneWidget);
    expect(_shelf(tester)[1], 'Rubber Chicken');
  });
}
