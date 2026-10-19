import 'package:flutter/foundation.dart';

import '../game/modifiers.dart';
import '../game/remix.dart';
import '../game/tools.dart';
import '../game/unlocks.dart';
import 'heist_log.dart';

/// What the briefing was last set to: the tool and the modifier switches.
class BriefingPrefs extends ChangeNotifier {
  BriefingPrefs._();

  static final instance = BriefingPrefs._();

  Tool _tool = Tool.socks;
  // The Briefing board starts with Nightly Remix on.
  bool _remix = true;
  bool _lightSleeper = false;
  bool _mirror = false;

  Tool get tool => _tool;
  bool get remix => _remix;
  bool get lightSleeper => _lightSleeper;
  bool get mirror => _mirror;

  set tool(Tool v) => _update(() => _tool = v);
  set remix(bool v) => _update(() => _remix = v);
  set lightSleeper(bool v) => _update(() => _lightSleeper = v);
  set mirror(bool v) => _update(() => _mirror = v);

  /// Tonight's setup with [socks] earned, remixed for [today]. A pick the
  /// socks don't pay for stays behind: the tool falls back to socks, a
  /// modifier switches off.
  NightSetup setup({required int socks, required DateTime today}) => NightSetup(
    tool: _tool == Tool.kazoo && !Unlock.kazoo.openWith(socks) ? Tool.socks : _tool,
    lightSleeper: _lightSleeper && Unlock.lightSleeper.openWith(socks),
    mirror: _mirror && Unlock.mirror.openWith(socks),
    remixSeed: _remix ? remixSeed(today.year, today.month, today.day) : null,
  );

  /// The setup "Sneak in" plays right now.
  NightSetup tonight() => setup(socks: HeistLog.instance.totalSocks, today: DateTime.now());

  void _update(VoidCallback change) {
    change();
    notifyListeners();
  }

  @visibleForTesting
  void reset() {
    _tool = Tool.socks;
    _remix = true;
    _lightSleeper = false;
    _mirror = false;
  }
}
