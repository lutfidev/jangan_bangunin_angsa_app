import 'dart:math' as math;

import 'tuning.dart';

/// Where the screen looks in a house bigger than itself: a little ahead of
/// Milo, the way he faces, with his floor line where the screen has its
/// floor (y 270), easing over when he turns or changes storey and never
/// past the house's edges. The scene applies it as a translation; it moves
/// only through [tick].
class Camera {
  Camera({
    required this.worldWidth,
    this.worldHeight = 390,
    this.viewWidth = 844,
    this.viewHeight = 390,
    this.tuning = const Tuning(),
  });

  final double worldWidth;
  final double worldHeight;
  final double viewWidth;
  final double viewHeight;
  final Tuning tuning;

  /// Where the screen's floor line sits, from its top.
  static const floorLine = 270.0;

  double _x = 0;
  double _y = 0;

  /// The world x at the screen's left edge.
  double get x => _x;

  /// The world y at the screen's top edge.
  double get y => _y;

  /// Jumps straight to Milo at [playerX], facing [facing] (+1 or -1), on
  /// the floor line [floorY].
  void snap(double playerX, double facing, {required double floorY}) {
    _x = _goalX(playerX, facing);
    _y = _goalY(floorY);
  }

  /// Eases toward Milo for [dt] seconds. Exponential, so one long tick goes
  /// as far as many short ones.
  void tick(double dt, double playerX, double facing, {required double floorY}) {
    final keep = math.exp(-tuning.cameraFollow * dt);
    final gx = _goalX(playerX, facing);
    final gy = _goalY(floorY);
    _x = _clampX(gx + (_x - gx) * keep);
    _y = _clampY(gy + (_y - gy) * keep);
  }

  /// Whether any of world x [left]..[right] (and, given, y [top]..[bottom])
  /// is on screen.
  bool sees(double left, double right, {double? top, double? bottom}) =>
      right >= _x &&
      left <= _x + viewWidth &&
      (bottom == null || bottom >= _y) &&
      (top == null || top <= _y + viewHeight);

  double _goalX(double playerX, double facing) => _clampX(playerX + facing * tuning.cameraLookAhead - viewWidth / 2);

  double _goalY(double floorY) => _clampY(floorY - floorLine);

  double _clampX(double x) => x.clamp(0, math.max(0, worldWidth - viewWidth)).toDouble();

  double _clampY(double y) => y.clamp(0, math.max(0, worldHeight - viewHeight)).toDouble();
}
