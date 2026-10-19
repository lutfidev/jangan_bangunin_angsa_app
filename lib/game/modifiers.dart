import 'tools.dart';

/// Everything the briefing decides about a night: the tool and the
/// modifiers. Retry, Replay and Restart play the same setup again.
class NightSetup {
  const NightSetup({this.tool = Tool.socks, this.lightSleeper = false, this.mirror = false, this.remixSeed});

  final Tool tool;

  /// Light Sleeper: she hears everything louder.
  final bool lightSleeper;

  /// Mirror Night: the house is drawn flipped. The simulation never knows.
  final bool mirror;

  /// Nightly Remix: the date seed the layout was shuffled with, or null for
  /// the night as designed. Kept here so a retry after midnight replays
  /// the same house.
  final int? remixSeed;

  @override
  bool operator ==(Object other) =>
      other is NightSetup &&
      other.tool == tool &&
      other.lightSleeper == lightSleeper &&
      other.mirror == mirror &&
      other.remixSeed == remixSeed;

  @override
  int get hashCode => Object.hash(tool, lightSleeper, mirror, remixSeed);
}
