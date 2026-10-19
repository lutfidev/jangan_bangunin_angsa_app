import 'package:flutter/foundation.dart';

import '../game/heist.dart';
import '../game/night_sim.dart';

/// Socks earned per night: the heist goals met on a getaway. Kept in memory
/// for now.
class HeistLog extends ChangeNotifier {
  HeistLog._();

  static final instance = HeistLog._();

  final Map<String, Set<PlayStyle>> _earned = {};

  /// The goal styles earned on [levelId] so far.
  Set<PlayStyle> earned(String levelId) => Set.unmodifiable(_earned[levelId] ?? const <PlayStyle>{});

  /// Adds the socks a finished night earned; a caught night earns none.
  void record(NightResult result) {
    final socks = _earned.putIfAbsent(result.level.id, () => {});
    final before = socks.length;
    socks.addAll(result.goalsMet);
    if (socks.length != before) notifyListeners();
  }

  @visibleForTesting
  void clear() => _earned.clear();
}
