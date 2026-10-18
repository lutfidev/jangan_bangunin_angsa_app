import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'routes.dart';
import 'screens/briefing_screen.dart';
import 'screens/caught_screen.dart';
import 'screens/chaos_escape_screen.dart';
import 'screens/gameplay_screen.dart';
import 'screens/main_menu_screen.dart';
import 'screens/pause_screen.dart';
import 'screens/plan_view_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/trophy_room_screen.dart';
import 'screens/victory_screen.dart';
import 'theme/palette.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Fonts ship in assets/google_fonts/; never hit the network for them.
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(_fontLicenses);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MainApp());
}

Stream<LicenseEntry> _fontLicenses() async* {
  for (final family in ['BagelFatOne', 'BricolageGrotesque']) {
    final license = await rootBundle.loadString(
      'assets/google_fonts/$family-OFL.txt',
    );
    yield LicenseEntryWithLineBreaks([family], license);
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  static final Map<String, WidgetBuilder> _screens = {
    Routes.menu: (_) => const MainMenuScreen(),
    Routes.briefing: (_) => const BriefingScreen(),
    Routes.gameplay: (_) => const GameplayScreen(),
    Routes.planView: (_) => const PlanViewScreen(),
    Routes.chaosEscape: (_) => const ChaosEscapeScreen(),
    Routes.pause: (_) => const PauseScreen(),
    Routes.settings: (_) => const SettingsScreen(),
    Routes.victory: (_) => const VictoryScreen(),
    Routes.caught: (_) => const CaughtScreen(),
    Routes.trophyRoom: (_) => const TrophyRoomScreen(),
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Don't Wake the Goose",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Palette.lamp,
          brightness: Brightness.dark,
          surface: Palette.midnight,
        ),
        scaffoldBackgroundColor: Palette.midnight,
      ),
      initialRoute: Routes.menu,
      onGenerateRoute: (settings) {
        final builder = _screens[settings.name];
        if (builder == null) return null;
        return PageRouteBuilder<void>(
          settings: settings,
          transitionDuration: const Duration(milliseconds: 200),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (context, _, _) => builder(context),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }
}
