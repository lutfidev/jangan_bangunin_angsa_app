import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/night_sim.dart';
import 'package:jangan_bangunin_angsa_app/game/tools.dart';
import 'package:jangan_bangunin_angsa_app/main.dart';
import 'package:jangan_bangunin_angsa_app/routes.dart';
import 'package:jangan_bangunin_angsa_app/screens/briefing_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/caught_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/gameplay_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/victory_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/settings_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/trophy_room_screen.dart';
import 'package:jangan_bangunin_angsa_app/state/game_settings.dart';
import 'package:jangan_bangunin_angsa_app/state/levels.dart';
import 'package:jangan_bangunin_angsa_app/widgets/chunky_button.dart';
import 'package:jangan_bangunin_angsa_app/widgets/controls.dart';

import 'helpers.dart';

void main() {
  testWidgets('PLAY on the main menu opens the briefing', (tester) async {
    useStageSurface(tester);
    await tester.pumpWidget(const MainApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('PLAY'));
    await tester.pumpAndSettle();

    final briefing = find.byType(BriefingScreen);
    expect(briefing, findsOneWidget);
    expect(ModalRoute.of(tester.element(briefing))!.settings.name, Routes.briefing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('picking a briefing tool updates the info box', (tester) async {
    await pumpScreen(tester, const BriefingScreen());

    Finder tile(String name) => find.byWidgetPredicate(
      (w) => w is ChunkyButton && w.semanticLabel == name,
    );

    expect(find.text('Spare Socks ×3'), findsOneWidget);
    expect(find.text('Wind-up Mouse'), findsNothing);

    await tester.tap(tile('Wind-up Mouse'));
    await tester.pump();

    expect(find.text('Wind-up Mouse'), findsOneWidget);
    expect(find.textContaining('walks until it bumps something'), findsOneWidget);
    expect(find.text('Spare Socks ×3'), findsNothing);

    await tester.tap(tile('Bag of Marbles'));
    await tester.pump();

    expect(find.text('Bag of Marbles'), findsOneWidget);
    expect(find.text('CHAOS'), findsWidgets);
    expect(find.text('Wind-up Mouse'), findsNothing);
  });

  testWidgets('every trophy fits the trophy room detail card', (tester) async {
    await pumpScreen(tester, const TrophyRoomScreen());

    const names = [
      'Golden Toilet Trophy',
      'Oversized Toaster',
      'Rubber Chicken',
      'Suspicious Garden Gnome',
      'Duck-Shaped Trophy',
      'Locked',
    ];
    for (final name in names) {
      await tester.tap(find.byWidgetPredicate(
        (w) => w is ChunkyButton && w.semanticLabel == name,
      ));
      await tester.pump();

      // Overflow is only reported once per RenderFlex, so check the geometry:
      // the card's last line must end inside the card's column.
      final card = find.ancestor(of: find.text(name).last, matching: find.byType(Column)).first;
      final lastLine = find.descendant(of: card, matching: find.byType(Text)).last;
      expect(
        tester.getRect(lastLine).bottom,
        lessThanOrEqualTo(tester.getRect(card).bottom),
        reason: name,
      );
    }
    expect(tester.takeException(), isNull);
  });

  group('settings toggles write to GameSettings', () {
    final settings = GameSettings.instance;

    final toggles = <String, (bool Function(), void Function(bool))>{
      'Haptic feedback': (() => settings.haptics, (v) => settings.haptics = v),
      'Reduce screen shake': (() => settings.reduceShake, (v) => settings.reduceShake = v),
      'Left-handed controls': (() => settings.leftHanded, (v) => settings.leftHanded = v),
    };

    for (final MapEntry(key: label, value: (read, write)) in toggles.entries) {
      testWidgets(label, (tester) async {
        final before = read();
        addTearDown(() => write(before));
        await pumpScreen(tester, const SettingsScreen());

        final row = find.widgetWithText(ToggleRow, label);
        await tester.tap(row);
        await tester.pump();
        expect(read(), !before);
        expect(tester.widget<ToggleRow>(row).value, !before);

        await tester.tap(row);
        await tester.pump();
        expect(read(), before);
      });
    }
  });

  group('the picked tool', () {
    Finder tile(String name) => find.byWidgetPredicate((w) => w is ChunkyButton && w.semanticLabel == name);
    Finder button(String label) => find.ancestor(of: find.text(label), matching: find.byType(ChunkyButton)).first;
    Finder gameplayWith(Tool tool) => find.byWidgetPredicate((w) => w is GameplayScreen && w.tool == tool);

    Future<void> pumpOnRoutes(WidgetTester tester, Widget home) async {
      useStageSurface(tester);
      await tester.pumpWidget(MaterialApp(onGenerateRoute: MainApp.route, home: home));
      await tester.pump();
    }

    testWidgets('Sneak in starts the night with it', (tester) async {
      await pumpOnRoutes(tester, const BriefingScreen());
      await tester.tap(tile('Wind-up Mouse'));
      await tester.pump();
      await tester.tap(button('Sneak in'));
      await play(tester, 0.3);
      expect(gameplayWith(Tool.mouse), findsOneWidget);
    });

    testWidgets('the locked kazoo can be read but not taken', (tester) async {
      await pumpOnRoutes(tester, const BriefingScreen());
      await tester.tap(tile('Kazoo (locked)'));
      await tester.pump();
      expect(find.text('Earn 6 socks to unlock. One loud toot right where you stand.'), findsOneWidget);
      expect(tester.widget<ChunkyButton>(button('Sneak in')).onPressed, isNull);
      final dim = find.ancestor(of: button('Sneak in'), matching: find.byType(Opacity));
      expect(tester.widget<Opacity>(dim.first).opacity, 0.6);
    });

    testWidgets('Retry after a catch keeps it', (tester) async {
      await pumpOnRoutes(tester, CaughtScreen(result: sampleCaught(tool: Tool.marbles)));
      await tester.tap(button('Retry'));
      await play(tester, 0.3);
      expect(gameplayWith(Tool.marbles), findsOneWidget);
    });

    testWidgets('Replay after a getaway keeps it', (tester) async {
      await pumpOnRoutes(tester, VictoryScreen(result: sampleEscape(tool: Tool.mouse)));
      await tester.tap(button('Replay'));
      await play(tester, 0.3);
      expect(gameplayWith(Tool.mouse), findsOneWidget);
    });

    testWidgets('Restart night from pause keeps it', (tester) async {
      await pumpGameplay(tester, NightSim(Levels.night3, tool: Tool.mouse));
      await tester.tap(
        find.byWidgetPredicate((w) => w is RoundIconButton && w.semanticLabel == 'Pause'),
        warnIfMissed: false,
      );
      await play(tester, 0.3);
      await tester.tap(button('Restart night'));
      await play(tester, 0.3);
      expect(gameplayWith(Tool.mouse), findsOneWidget);
      expect(find.byType(GameplayScreen), findsOneWidget);
    });
  });
}
