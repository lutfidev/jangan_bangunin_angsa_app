import 'package:flutter/services.dart';

import '../game/level.dart';

/// The nights bundled under `assets/levels/`, parsed once at startup.
abstract final class Levels {
  static Level? _night3;

  static Level get night3 => _night3 ?? (throw StateError('Levels.load has not run'));

  static Future<void> load(AssetBundle bundle) async {
    _night3 = Level.parse(await bundle.loadString('assets/levels/night3.json'));
  }
}
