import 'dart:math' as math;

/// The four tools of the briefing: one per night, each a portable chain
/// starter (Gameplay 2.0, "Pick one tool per night").
enum Tool { socks, mouse, marbles, kazoo }

/// A thrown sock in the air, lobbed from [fromX] to [toX].
class Flight {
  Flight({required this.fromX, required this.toX, required this.duration, this.high = false});

  final double fromX;
  final double toX;
  final double duration;

  /// Thrown from the crawlway: it leaves from up there even if he climbs down.
  final bool high;
  double _t = 0;

  /// 0 when thrown, 1 once it lands.
  double get progress => math.min(_t / duration, 1);

  bool get landed => _t >= duration;

  void advance(double dt) => _t += dt;
}

/// The wind-up mouse: walks one way along the floor until it bumps
/// something or a wall.
class ToyMouse {
  ToyMouse({required this._x, required this.dir});

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
