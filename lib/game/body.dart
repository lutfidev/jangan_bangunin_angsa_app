import 'dart:math' as math;

import 'geom.dart';
import 'tuning.dart';

/// Feet touching down after a fall of [fall] px onto [surface] at [at].
class Landing {
  const Landing({required this.fall, required this.surface, required this.at});

  final double fall;
  final Surface surface;
  final Vec at;

  @override
  String toString() => 'Landing(fall: $fall, $surface, at: $at)';
}

/// Milo's body: a box with its feet at the bottom centre, walked, dropped
/// and jumped through [geometry]. Advanced only by [step].
class Body {
  Body(this.geometry, Vec feet, this.tuning) : _x = feet.x, _y = feet.y, _highest = feet.y {
    _standingOn = geometry.platformAt(feet, tolerance: 0);
    _grounded = _standingOn != null || _solidTopAt(_x, _y) != null;
  }

  final Geometry geometry;
  final Tuning tuning;

  double _x;
  double _y;
  double _vy = 0;
  double _facing = 1;
  bool _grounded = false;
  Platform? _standingOn;
  double _highest;
  double _coyote = 0;
  double _buffer = 0;

  /// The top being mantled onto, where from, and for how long so far.
  ({Platform onto, Vec from, double t})? _mantle;

  /// A drop-through ignores this top until his feet are below it.
  Platform? _dropping;

  /// One push of the stick does one climb or drop; it has to come back to
  /// the middle before the next.
  bool _verticalSpent = false;

  Vec get feet => Vec(_x, _y);
  bool get grounded => _grounded;

  /// The furniture top he stands on; null on the floor or in the air.
  Platform? get standingOn => _grounded ? _standingOn : null;
  bool get onFloor => _grounded && _standingOn == null;

  /// +1 facing right, -1 facing left: the way he last moved.
  double get facing => _facing;

  /// On a crawl top: too low to stand, so slow, silent and no jumping.
  bool get crawling => standingOn?.crawl ?? false;

  bool get mantling => _mantle != null;

  /// Up on the stick would climb onto a top right now.
  bool get canMantle => _grounded && !mantling && !crawling && _mantleTarget() != null;

  /// Down on the stick would drop through the top he stands on.
  bool get canDrop => standingOn != null && !mantling;

  /// The nearest top above his feet that he can reach from here.
  Platform? _mantleTarget() {
    Platform? best;
    for (final p in geometry.platforms) {
      final up = _y - p.y;
      if (!p.spans(_x) || up <= 0 || up > tuning.mantleReach) continue;
      if (best == null || p.y > best.y) best = p;
    }
    return best;
  }

  void pressJump() => _buffer = tuning.jumpBuffer;

  /// Advances [h] seconds with the stick at [move] (-1..1) and [vertical]
  /// (-1 up, +1 down). Returns the landing this step made, if any.
  Landing? step(double h, {required double move, required int vertical, required bool sneak, bool canClimb = true}) {
    if (vertical == 0) _verticalSpent = false;
    final mantle = _mantle;
    if (mantle != null) {
      _stepMantle(mantle, h);
      return null;
    }

    _buffer = math.max(0, _buffer - h);
    if (!_grounded) _coyote = math.max(0, _coyote - h);

    if (_grounded && !_verticalSpent && vertical != 0) {
      final onto = vertical < 0 && canClimb && !crawling ? _mantleTarget() : null;
      if (onto != null) {
        _verticalSpent = true;
        _buffer = 0;
        _mantle = (onto: onto, from: feet, t: 0);
        return null;
      }
      final under = vertical > 0 ? standingOn : null;
      if (under != null) {
        _verticalSpent = true;
        _dropping = under;
        _leaveGround(coyote: 0);
      }
    }

    if (_buffer > 0 && canClimb && !crawling && (_grounded || _coyote > 0)) _jump();

    if (move != 0) _facing = move.sign;
    final speed = crawling ? tuning.crawlSpeed : (sneak ? tuning.sneakSpeed : tuning.walkSpeed);
    final wasCrawling = crawling;
    _moveX(move * speed * h);

    // Off a crawl top there was no room to jump from.
    if (_grounded && !_supported()) _leaveGround(coyote: wasCrawling ? 0 : tuning.coyoteTime);
    if (_grounded) return null;
    return _fall(h);
  }

  void _stepMantle(({Platform onto, Vec from, double t}) m, double h) {
    final t = m.t + h;
    if (t >= tuning.mantleTime) {
      _mantle = null;
      _y = m.onto.y;
      _vy = 0;
      _grounded = true;
      _standingOn = m.onto;
      return;
    }
    _mantle = (onto: m.onto, from: m.from, t: t);
    _y = m.from.y + (m.onto.y - m.from.y) * t / tuning.mantleTime;
  }

  void _leaveGround({required double coyote}) {
    _grounded = false;
    _standingOn = null;
    _coyote = coyote;
    _highest = _y;
    _vy = 0;
  }

  void _jump() {
    _vy = -tuning.jumpSpeed;
    _grounded = false;
    _standingOn = null;
    _coyote = 0;
    _buffer = 0;
    _highest = _y;
  }

  Box _boxAt(double x, double y) =>
      Box(x - tuning.bodyWidth / 2, y - tuning.bodyHeight, x + tuning.bodyWidth / 2, y);

  void _moveX(double dx) {
    if (dx == 0) return;
    var nx = _x + dx;
    final half = tuning.bodyWidth / 2;
    for (final s in geometry.solids) {
      if (!_boxAt(nx, _y).overlaps(s.box)) continue;
      nx = dx > 0 ? math.min(nx, s.box.left - half) : math.max(nx, s.box.right + half);
    }
    _x = nx;
  }

  bool _supported() {
    final on = _standingOn;
    if (on != null) return on.spans(_x);
    return _solidTopAt(_x, _y) != null;
  }

  /// A solid whose top is at [y] under [x].
  Solid? _solidTopAt(double x, double y) {
    for (final s in geometry.solids) {
      if (s.box.top == y && s.box.left <= x && x <= s.box.right) return s;
    }
    return null;
  }

  Landing? _fall(double h) {
    // Average of the speeds at both ends: exact under constant gravity, so
    // the jump height doesn't depend on the frame rate.
    final vy = math.min(_vy + tuning.gravity * h, tuning.maxFallSpeed);
    final from = _y;
    var to = _y + (_vy + vy) / 2 * h;
    _vy = vy;
    final half = tuning.bodyWidth / 2;

    if (_vy < 0) {
      // Head into a ceiling.
      for (final s in geometry.solids) {
        final hitsHead = s.box.bottom <= from - tuning.bodyHeight && s.box.bottom > to - tuning.bodyHeight;
        if (hitsHead && s.box.left < _x + half && _x - half < s.box.right) {
          to = s.box.bottom + tuning.bodyHeight;
          _vy = 0;
        }
      }
      _y = to;
      _highest = math.min(_highest, _y);
      return null;
    }

    // Falling: the first top crossed between from and to catches him.
    double? landY;
    Surface? surface;
    Platform? platform;
    for (final s in geometry.solids) {
      final top = s.box.top;
      if (top >= from && top <= to && s.box.left < _x + half && _x - half < s.box.right) {
        if (landY == null || top < landY) {
          landY = top;
          surface = s.surface;
          platform = null;
        }
      }
    }
    if (_dropping case final d? when from > d.y) _dropping = null;
    for (final p in geometry.platforms) {
      if (p == _dropping) continue;
      if (p.y >= from && p.y <= to && p.spans(_x) && (landY == null || p.y < landY)) {
        landY = p.y;
        surface = p.surface;
        platform = p;
      }
    }
    if (landY == null) {
      _y = to;
      // The step over the top of a jump can still rise a little.
      _highest = math.min(_highest, _y);
      return null;
    }
    _y = landY;
    _vy = 0;
    _grounded = true;
    _standingOn = platform;
    return Landing(fall: landY - _highest, surface: surface!, at: Vec(_x, landY));
  }
}
