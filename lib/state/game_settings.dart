import 'package:flutter/foundation.dart';

/// Player preferences. Changes apply instantly; kept in memory for now.
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

  void _update(VoidCallback change) {
    change();
    notifyListeners();
  }
}
