import 'package:flutter/widgets.dart';

abstract final class Routes {
  static const menu = '/';
  static const briefing = '/briefing';
  static const gameplay = '/gameplay';
  static const planView = '/plan';
  static const chaosEscape = '/chaos';
  static const pause = '/pause';
  static const settings = '/settings';
  static const victory = '/victory';
  static const caught = '/caught';
  static const trophyRoom = '/trophies';

  /// Back to the main menu, dropping everything above it.
  static void toMenu(BuildContext context) =>
      Navigator.popUntil(context, ModalRoute.withName(menu));

  /// Start the night over from a fresh gameplay screen.
  static void restartNight(BuildContext context) =>
      Navigator.pushNamedAndRemoveUntil(
        context,
        gameplay,
        ModalRoute.withName(menu),
      );
}
