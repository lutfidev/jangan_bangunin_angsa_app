import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jangan_bangunin_angsa_app/screens/briefing_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/caught_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/chaos_escape_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/gameplay_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/main_menu_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/pause_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/plan_view_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/settings_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/trophy_room_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/victory_screen.dart';

import 'helpers.dart';

void main() {
  const screens = <String, Widget>{
    'MainMenu': MainMenuScreen(),
    'Briefing': BriefingScreen(),
    'Gameplay': GameplayScreen(),
    'PlanView': PlanViewScreen(),
    'ChaosEscape': ChaosEscapeScreen(),
    'Pause': PauseScreen(),
    'Settings': SettingsScreen(),
    'Victory': VictoryScreen(),
    'Caught': CaughtScreen(),
    'TrophyRoom': TrophyRoomScreen(),
  };

  for (final MapEntry(key: name, value: screen) in screens.entries) {
    testWidgets('$name renders at 844x390 without errors', (tester) async {
      await pumpScreen(tester, screen);

      // Overflows and build errors are reported as FlutterErrors.
      expect(tester.takeException(), isNull);
      expect(find.byWidget(screen), findsOneWidget);

      // Every font the screen asked for resolves from the bundled assets
      // (runtime fetching is off; see flutter_test_config.dart).
      await tester.runAsync(GoogleFonts.pendingFonts);
    });
  }
}
