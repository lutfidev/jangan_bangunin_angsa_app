import 'package:flutter/foundation.dart';

import '../game/heist.dart';
import '../game/night_sim.dart';
import 'json_fields.dart';

/// Per night: the socks earned (heist goals met on a getaway) and the loot
/// ever carried out. [SaveGame] keeps it on disk.
class HeistLog extends ChangeNotifier {
  HeistLog._();

  static final instance = HeistLog._();

  final Map<String, Set<PlayStyle>> _earned = {};
  final Map<String, Set<String>> _pilfered = {};

  /// The goal styles earned on [levelId] so far.
  Set<PlayStyle> earned(String levelId) => Set.unmodifiable(_earned[levelId] ?? const <PlayStyle>{});

  /// Loot ids ever carried out of [levelId].
  Set<String> pilfered(String levelId) => Set.unmodifiable(_pilfered[levelId] ?? const <String>{});

  /// Socks earned over every night.
  int get totalSocks => _earned.values.fold(0, (n, socks) => n + socks.length);

  /// Adds the socks a finished night earned; a caught night earns none.
  /// The loot of a getaway counts as pilfered.
  void record(NightResult result) {
    final socks = _earned.putIfAbsent(result.level.id, () => {});
    final loot = _pilfered.putIfAbsent(result.level.id, () => {});
    final before = socks.length + loot.length;
    socks.addAll(result.goalsMet);
    if (result.outcome == Outcome.escaped) loot.addAll(result.loot);
    if (socks.length + loot.length != before) notifyListeners();
  }

  /// The save blob's `socks` and `pilfered` entries.
  Map<String, Object?> toJson() => {
    'socks': {
      for (final MapEntry(key: id, value: styles) in _earned.entries)
        if (styles.isNotEmpty) id: [for (final s in PlayStyle.values) if (styles.contains(s)) s.name],
    },
    'pilfered': {
      for (final MapEntry(key: id, value: loot) in _pilfered.entries)
        if (loot.isNotEmpty) id: [...loot],
    },
  };

  /// Takes the `socks` and `pilfered` entries of a save blob [json],
  /// skipping anything that isn't a known style or a loot id string.
  void restore(Map<String, Object?> json) {
    _earned.clear();
    _pilfered.clear();
    for (final MapEntry(key: id, value: names) in jsonMap(json['socks']).entries) {
      _earned[id] = {
        for (final name in jsonStrings(names)) ?jsonEnum(PlayStyle.values, name),
      };
    }
    for (final MapEntry(key: id, value: ids) in jsonMap(json['pilfered']).entries) {
      _pilfered[id] = jsonStrings(ids).toSet();
    }
    notifyListeners();
  }

  @visibleForTesting
  void clear() {
    _earned.clear();
    _pilfered.clear();
  }
}
