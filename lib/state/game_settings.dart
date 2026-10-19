import 'package:flutter/foundation.dart';

import 'json_fields.dart';

/// Player preferences. Changes apply instantly; [SaveGame] keeps them.
class GameSettings extends ChangeNotifier {
  GameSettings._();

  static final instance = GameSettings._();

  int _sfx = 80;
  int _music = 60;
  bool _haptics = true;
  bool _reduceShake = false;
  bool _leftHanded = false;

  int get sfx => _sfx;
  int get music => _music;
  bool get haptics => _haptics;
  bool get reduceShake => _reduceShake;
  bool get leftHanded => _leftHanded;

  set sfx(int v) => _update(() => _sfx = v);
  set music(int v) => _update(() => _music = v);
  set haptics(bool v) => _update(() => _haptics = v);
  set reduceShake(bool v) => _update(() => _reduceShake = v);
  set leftHanded(bool v) => _update(() => _leftHanded = v);

  Map<String, Object?> toJson() => {
    'sfx': _sfx,
    'music': _music,
    'haptics': _haptics,
    'reduceShake': _reduceShake,
    'leftHanded': _leftHanded,
  };

  /// Takes the settings of a save blob; a missing or odd field keeps its
  /// value, volumes clamp to 0..100.
  void restore(Map<String, Object?> json) {
    _sfx = jsonInt(json, 'sfx', min: 0, max: 100) ?? _sfx;
    _music = jsonInt(json, 'music', min: 0, max: 100) ?? _music;
    _haptics = jsonBool(json, 'haptics') ?? _haptics;
    _reduceShake = jsonBool(json, 'reduceShake') ?? _reduceShake;
    _leftHanded = jsonBool(json, 'leftHanded') ?? _leftHanded;
    notifyListeners();
  }

  @visibleForTesting
  void reset() {
    _sfx = 80;
    _music = 60;
    _haptics = true;
    _reduceShake = false;
    _leftHanded = false;
  }

  void _update(VoidCallback change) {
    change();
    notifyListeners();
  }
}
