import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'game/night_sim.dart';
import 'game/tools.dart';
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
import 'state/levels.dart';
import 'theme/palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fonts ship in assets/google_fonts/; never hit the network for them.
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(_fontLicenses);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Levels.load(rootBundle);
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

  /// Screens by route name. Caught and Victory take the night's
  /// [NightResult] as the route argument.
  static final Map<String, Widget Function(Object? arguments)> _screens = {
    Routes.menu: (_) => const MainMenuScreen(),
    Routes.briefing: (_) => const BriefingScreen(),
    Routes.gameplay: (tool) => GameplayScreen(tool: tool as Tool? ?? Tool.socks),
    Routes.planView: (_) => const PlanViewScreen(),
    Routes.chaosEscape: (_) => const ChaosEscapeScreen(),
    Routes.pause: (tool) => PauseScreen(tool: tool as Tool? ?? Tool.socks),
    Routes.settings: (_) => const SettingsScreen(),
    Routes.victory: (result) => VictoryScreen(result: result! as NightResult),
    Routes.caught: (result) => CaughtScreen(result: result! as NightResult),
    Routes.trophyRoom: (_) => const TrophyRoomScreen(),
  };

  /// Builds every named route with a 200ms fade.
  static Route<void>? route(RouteSettings settings) {
    final builder = _screens[settings.name];
    if (builder == null) return null;
    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, _, _) => builder(settings.arguments),
      transitionsBuilder: (context, animation, _, child) => FadeTransition(opacity: animation, child: child),
    );
  }

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
      onGenerateRoute: route,
    );
  }
}
