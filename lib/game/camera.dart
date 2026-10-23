import 'dart:math' as math;

import 'tuning.dart';

/// Where the screen looks along a house wider than itself: a little ahead
/// of Milo, the way he faces, easing over when he turns and never past the
/// house's ends. The scene applies it as a translation; it moves only
/// through [tick].
class Camera {
  Camera({required this.worldWidth, this.viewWidth = 844, this.tuning = const Tuning()});

  final double worldWidth;
  final double viewWidth;
  final Tuning tuning;

  double _x = 0;

  /// The world x at the screen's left edge.
  double get x => _x;

  /// Jumps straight to Milo at [playerX], facing [facing] (+1 or -1).
  void snap(double playerX, double facing) => _x = _goal(playerX, facing);

  /// Eases toward Milo for [dt] seconds. Exponential, so one long tick goes
  /// as far as many short ones.
  void tick(double dt, double playerX, double facing) {
    final goal = _goal(playerX, facing);
    _x = _clamp(goal + (_x - goal) * math.exp(-tuning.cameraFollow * dt));
  }

  /// Whether any of world x [left]..[right] is on screen.
  bool sees(double left, double right) => right >= _x && left <= _x + viewWidth;

  double _goal(double playerX, double facing) =>
      _clamp(playerX + facing * tuning.cameraLookAhead - viewWidth / 2);

  double _clamp(double x) => x.clamp(0, math.max(0, worldWidth - viewWidth)).toDouble();
}
