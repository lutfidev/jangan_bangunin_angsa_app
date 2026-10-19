import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/heist.dart';
import 'package:jangan_bangunin_angsa_app/game/tools.dart';
import 'package:jangan_bangunin_angsa_app/main.dart';
import 'package:jangan_bangunin_angsa_app/screens/briefing_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/gameplay_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/main_menu_screen.dart';
import 'package:jangan_bangunin_angsa_app/state/briefing_prefs.dart';
import 'package:jangan_bangunin_angsa_app/state/heist_log.dart';
import 'package:jangan_bangunin_angsa_app/widgets/chunky_button.dart';

import 'helpers.dart';

/// Earns [styles] as socks on Night 3.
void earn(Set<PlayStyle> styles) => HeistLog.instance.record(sampleEscape(goalsMet: styles));

Finder _tile(String name) => find.byWidgetPredicate((w) => w is ChunkyButton && w.semanticLabel == name);
Finder _button(String label) => find.ancestor(of: find.text(label), matching: find.byType(ChunkyButton)).first;
GameplayScreen _gameplay(WidgetTester tester) => tester.widget<GameplayScreen>(find.byType(GameplayScreen));

Future<void> _pumpOnRoutes(WidgetTester tester, Widget home) async {
  useStageSurface(tester);
  await tester.pumpWidget(MaterialApp(onGenerateRoute: MainApp.route, home: home));
  await tester.pump();
}

void main() {
  group('BriefingPrefs.setup', () {
    final today = DateTime(2026, 10, 19);

    test('locked picks never reach the night', () {
      final prefs = BriefingPrefs.instance
        ..tool = Tool.kazoo
        ..lightSleeper = true
        ..mirror = true;
      final low = prefs.setup(socks: 0, today: today);
      expect(low.tool, Tool.socks);
      expect(low.lightSleeper, isFalse);
      expect(low.mirror, isFalse);
      final one = prefs.setup(socks: 1, today: today);
      expect(one.lightSleeper, isTrue);
      expect(one.tool, Tool.socks);
      final all = prefs.setup(socks: 3, today: today);
      expect(all.tool, Tool.kazoo);
      expect(all.mirror, isTrue);
    });

    test('remix seeds from the day', () {
      final prefs = BriefingPrefs.instance;
      expect(prefs.remix, isTrue); // the Briefing board starts it on
      expect(prefs.setup(socks: 0, today: today).remixSeed, 20261019);
      prefs.remix = false;
      expect(prefs.setup(socks: 0, today: today).remixSeed, isNull);
    });

    test('changes notify', () {
      var heard = 0;
      final prefs = BriefingPrefs.instance;
      void listener() => heard++;
      prefs.addListener(listener);
      addTearDown(() => prefs.removeListener(listener));
      prefs
        ..tool = Tool.mouse
        ..remix = false
        ..lightSleeper = true
        ..mirror = true;
      expect(heard, 4);
    });
  });

  group('briefing screen', () {
    testWidgets('with no socks the modifiers wait', (tester) async {
      await pumpScreen(tester, const BriefingScreen());
      expect(find.text('Light Sleeper (1 sock)'), findsOneWidget);
      expect(find.text('Mirror (3 socks)'), findsOneWidget);
      expect(_tile('Kazoo (locked)'), findsOneWidget);
      await tester.tap(find.text('Light Sleeper (1 sock)'));
      await tester.pump();
      expect(BriefingPrefs.instance.lightSleeper, isFalse);
    });

    testWidgets('three socks open everything', (tester) async {
      earn(PlayStyle.values.toSet());
      await pumpScreen(tester, const BriefingScreen());
      expect(find.text('Light Sleeper'), findsOneWidget);
      expect(find.text('Mirror'), findsOneWidget);
      await tester.tap(_tile('Kazoo'));
      await tester.pump();
      expect(find.text("One loud toot right where you stand. Wakes her if she's close."), findsOneWidget);
      expect(tester.widget<ChunkyButton>(_button('Sneak in')).onPressed, isNotNull);
      await tester.tap(find.text('Mirror'));
      await tester.pump();
      expect(BriefingPrefs.instance.mirror, isTrue);
    });

    testWidgets('the count updates when a sock lands', (tester) async {
      await pumpScreen(tester, const BriefingScreen());
      expect(find.text('HEIST GOALS · 0 / 3 SOCKS'), findsOneWidget);
      earn({PlayStyle.trickster});
      await tester.pump();
      expect(find.text('HEIST GOALS · 1 / 3 SOCKS'), findsOneWidget);
      expect(find.text('Light Sleeper'), findsOneWidget);
    });

    testWidgets('picks are remembered', (tester) async {
      BriefingPrefs.instance.tool = Tool.marbles;
      await pumpScreen(tester, const BriefingScreen());
      expect(find.text('Bag of Marbles'), findsOneWidget); // the selected tool's card
      await tester.tap(_tile('Wind-up Mouse'));
      await tester.pump();
      expect(BriefingPrefs.instance.tool, Tool.mouse);
    });

    testWidgets('sneak in passes the setup', (tester) async {
      earn({PlayStyle.trickster});
      await _pumpOnRoutes(tester, const BriefingScreen());
      await tester.tap(find.text('Light Sleeper'));
      await tester.pump();
      await tester.tap(_button('Sneak in'));
      await play(tester, 0.3);
      final setup = _gameplay(tester).setup;
      expect(setup.lightSleeper, isTrue);
      expect(setup.remixSeed, isNotNull);
    });

    testWidgets('the menu\'s Nights button plays the remembered setup', (tester) async {
      earn({PlayStyle.trickster});
      BriefingPrefs.instance
        ..tool = Tool.mouse
        ..lightSleeper = true;
      await _pumpOnRoutes(tester, const MainMenuScreen());
      await tester.tap(find.text('Nights'));
      await play(tester, 0.3);
      final setup = _gameplay(tester).setup;
      expect(setup.tool, Tool.mouse);
      expect(setup.lightSleeper, isTrue);
    });
  });
}
