import 'dart:math' as math;

/// The four tools of the briefing: one per night, each a portable chain
/// starter (Gameplay 2.0, "Pick one tool per night").
enum Tool { socks, mouse, marbles, kazoo }

/// A thrown sock in the air, lobbed from his hand at ([fromX], [fromY]) to
/// [toX] on the floor line [toY].
class Flight {
  Flight({required this.fromX, required this.fromY, required this.toX, required this.toY, required this.duration});

  final double fromX;

  /// Where his hand was when he threw, even if he has moved since.
  final double fromY;
  final double toX;

  /// The floor of the room he threw it in.
  final double toY;
  final double duration;
  double _t = 0;

  /// 0 when thrown, 1 once it lands.
  double get progress => math.min(_t / duration, 1);

  bool get landed => _t >= duration;

  void advance(double dt) => _t += dt;
}

/// The wind-up mouse: walks one way along the floor line [y] until it
/// bumps something or a wall.
class ToyMouse {
  ToyMouse({required this._x, required this.y, required this.dir});

  final double y;

  /// +1 walks right, -1 walks left.
  final double dir;
  double _x;
  bool _stopped = false;

  double get x => _x;
  bool get stopped => _stopped;

  /// Walks for [dt] and returns the stretch of floor covered, as (from, to).
  /// Stops at [min] and [max].
  (double, double) advance(double dt, double speed, {required double min, required double max}) {
    final from = _x;
    if (_stopped) return (from, from);
    _x = (_x + dir * speed * dt).clamp(min, max);
    if (_x == min || _x == max) _stopped = true;
    return (from, _x);
  }

  /// Bumped into something at [at] (defaults to where it is).
  void stop([double? at]) {
    _x = at ?? _x;
    _stopped = true;
  }
}
