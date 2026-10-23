import 'package:flutter/services.dart';

import '../game/level.dart';

/// The nights bundled under `assets/levels/`, parsed once at startup.
abstract final class Levels {
  static Level? _night3;
  static Level? _house;

  static Level get night3 => _night3 ?? (throw StateError('Levels.load has not run'));

  /// The greybox house (langkah 8), reached only from a debug entry for now.
  static Level get house => _house ?? (throw StateError('Levels.load has not run'));

  /// The level a [NightSetup.night] names.
  static Level byId(String id) => switch (id) {
    'night3' => night3,
    'house' => house,
    _ => throw ArgumentError.value(id, 'id', 'no such night'),
  };

  static Future<void> load(AssetBundle bundle) async {
    _night3 = Level.parse(await bundle.loadString('assets/levels/night3.json'));
    _house = Level.parse(await bundle.loadString('assets/levels/house.json'));
  }
}
