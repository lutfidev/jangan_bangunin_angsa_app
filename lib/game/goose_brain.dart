import 'doors.dart';
import 'geom.dart';
import 'nav.dart';
import 'noise.dart';
import 'noise_meter.dart';
import 'tuning.dart';

/// Goose brain v2: five states on the asleep side, four on the awake side.
enum GooseState { asleep, stirring, suspicious, sleepwalk, drowsy, awake, chase, distracted, lostYou }

/// What woke her. [tool]: a noise a tool made itself (a sock that missed,
/// the kazoo), not a chain it started.
enum WakeCause { noise, footsteps, grabbedGuarded, tool }

enum _Walk { out, sniff, back }

/// Gertrude. She walks the house on [nav]: floors, stairs and the low tops
/// she flaps onto. [at] is where her feet are now.
class GooseBrain {
  GooseBrain({required this.nav, required this.bed, required this.tuning, double meterGain = 1, this.doors})
    : _seg = nav.segAt(bed),
      _x = bed.x,
      _target = bed,
      meter = NoiseMeter(tuning, gain: meterGain);

  final Nav nav;

  /// Her nest, on the floor.
  final Vec bed;
  final Tuning tuning;
  final NoiseMeter meter;

  /// Closed doors stop her until she pushes them open.
  final Doors? doors;

  Seg _seg;
  double _x;

  /// Mid-flap: where to, from where, onto what, and how far along (0..1).
  ({Seg to, Vec from, Vec land, double t})? _flap;
  Route? _route;

  GooseState _state = GooseState.asleep;
  WakeCause? _wakeCause;

  _Walk _walk = _Walk.out;
  Vec _target;
  Vec? _lastNoise;

  /// Where she last saw Milo while chasing him: where he went out of
  /// sight, the first step she didn't see.
  Vec? _lastSeen;
  bool _sawHim = false;

  /// Seconds left in the current timed phase: sniff, awake freeze, distraction.
  double _timer = 0;
  double _rollClock = 0;
  double _chaseLeft = 0;
  double _hiddenFor = 0;
  double _patrolFor = 0;
  double _slipLeft = 0;
  double _pushFor = 0;

  /// Whether she leaned on a door this tick; a push left off starts over.
  bool _pushed = false;

  double get bedX => bed.x;

  Vec get at {
    final f = _flap;
    if (f == null) return _seg.at(_x);
    return Vec(f.from.x + (f.land.x - f.from.x) * f.t, f.from.y + (f.land.y - f.from.y) * f.t);
  }

  double get x => at.x;
  double get y => at.y;

  /// Flying up onto a top, or down off it.
  bool get flapping => _flap != null;

  /// The way she last planned to go, for the debug overlay.
  Route? get route => _route;

  GooseState get state => _state;
  WakeCause? get wakeCause => _wakeCause;

  bool get inBed => switch (_state) {
    GooseState.asleep || GooseState.stirring || GooseState.suspicious || GooseState.drowsy => true,
    _ => false,
  };

  bool get isAwake => switch (_state) {
    GooseState.awake || GooseState.chase || GooseState.distracted => true,
    _ => false,
  };

  /// The 2s roll-over window, every 8s she is fully asleep.
  bool get rollingOver =>
      _state == GooseState.asleep &&
      _rollClock >= tuning.rollOverEvery &&
      _rollClock % tuning.rollOverEvery < tuning.rollOverWindow;

  bool get sniffing => _state == GooseState.sleepwalk && _walk == _Walk.sniff;

  /// Seconds of chase left; 0 when she isn't after anyone.
  double get chaseLeft => _state == GooseState.chase || _state == GooseState.distracted ? _chaseLeft : 0;

  /// Seconds left of a distraction; 0 when she isn't distracted.
  double get distractLeft => _state == GooseState.distracted ? _timer : 0;

  /// Leaning on a closed door until it gives.
  bool get pushingDoor => _pushFor > 0;

  /// Down on spilled marbles: she stands still while the chase clock runs.
  bool get slipping => _slipLeft > 0 && (_state == GooseState.chase || _state == GooseState.distracted);

  /// She runs onto spilled marbles. Ignored unless she is after someone.
  void slip() {
    if (_state == GooseState.chase || _state == GooseState.distracted) _slipLeft = tuning.slipTime;
  }

  /// A noise went off. [chainLinks] is its link number when a chain made it;
  /// [fromTool] when a tool made it directly. [source] is where it really
  /// went off, when she hears it muffled on its way: she goes there.
  void hear(Noise n, {int chainLinks = 0, bool fromTool = false, Vec? source}) {
    final here = at;
    final from = source ?? Vec(n.x, n.y ?? here.y);
    _lastNoise = from;
    final touches = n.touchesEar(here, tuning);
    if (inBed) {
      if (touches) {
        _raise(n.loudness, fromTool: fromTool);
      } else if (n.loudness >= 2) {
        // A loud noise far from her bed doesn't wake her — it moves her.
        _state = GooseState.sleepwalk;
        _walk = _Walk.out;
        _target = from;
      }
    } else if (_state == GooseState.sleepwalk) {
      if (n.loudness >= 2 && (touches || sniffing)) {
        wake(fromTool ? WakeCause.tool : WakeCause.noise);
      } else if (touches) {
        _raise(n.loudness, fromTool: fromTool);
      }
    } else if (chainLinks >= 2 && (_state == GooseState.chase || _state == GooseState.distracted)) {
      _state = GooseState.distracted;
      _target = from;
      _timer = tuning.distractTime;
    }
  }

  /// HONK. Ignored if she is already up.
  void wake(WakeCause cause) {
    if (isAwake) return;
    _state = GooseState.awake;
    _lastSeen = null;
    _sawHim = false;
    _wakeCause = cause;
    _timer = tuning.awakeFreeze;
    meter.reset(value: 100);
  }

  /// Advances [dt] seconds with Milo's feet at [player]. She [sees] him
  /// when he shares her room and isn't tucked away; [hidden] is a hide
  /// spot or a vent.
  void tick(double dt, {required Vec player, required bool sees, bool hidden = false}) {
    _pushed = false;
    _tick(dt, player: player, sees: sees, hidden: hidden);
    if (!_pushed) _pushFor = 0;
  }

  void _tick(double dt, {required Vec player, required bool sees, required bool hidden}) {
    switch (_state) {
      case GooseState.asleep || GooseState.stirring || GooseState.suspicious || GooseState.drowsy:
        meter.tick(dt);
        if (_state == GooseState.asleep) _rollClock += dt;
        _settleInBed();
      case GooseState.sleepwalk:
        meter.tick(dt);
        switch (_walk) {
          case _Walk.out:
            if (_moveTo(_target, tuning.sleepwalkSpeed, dt)) {
              _walk = _Walk.sniff;
              _timer = tuning.sniffTime;
            }
          case _Walk.sniff:
            _timer -= dt;
            if (_timer <= 0) _walk = _Walk.back;
          case _Walk.back:
            if (_moveTo(bed, tuning.sleepwalkSpeed, dt)) {
              meter.drowsyLeft = tuning.drowsyTime;
              _settleInBed();
            }
        }
      case GooseState.awake:
        // Up on her feet, she takes a look round before she runs.
        if (sees || _sawHim) _lastSeen = player;
        _sawHim = sees;
        _timer -= dt;
        if (_timer <= 0) {
          _state = GooseState.chase;
          _chaseLeft = tuning.chaseTime;
          _hiddenFor = 0;
        }
      case GooseState.chase:
        _chaseLeft -= dt;
        // She saw where he went: through a door she follows, pushing it if
        // it was shut in her face.
        if (sees || _sawHim) _lastSeen = player;
        _sawHim = sees;
        final target = sees ? player : (_lastSeen ?? _lastNoise ?? at);
        final arrived = !_slipped(dt) && _moveTo(target, tuning.chaseSpeed, dt);
        final catchable = sees && (_route?.catches ?? false);
        // She loses him hidden, seen but out of her reach, or gone from
        // where she last saw him.
        _trackHiding(dt, hidden || (sees && !catchable) || (!sees && arrived));
        if (_chaseLeft <= 0) _loseThem();
      case GooseState.distracted:
        if (!_slipped(dt)) _moveTo(_target, tuning.chaseSpeed, dt);
        _timer -= dt;
        _trackHiding(dt, hidden);
        if (_state == GooseState.distracted && _timer <= 0) _state = GooseState.chase;
      case GooseState.lostYou:
        // Grumpy, not blind: walk into her and the chase is back on.
        if (sees && !flapping && nav.catches(at, player)) {
          _state = GooseState.chase;
          _chaseLeft = tuning.chaseTime;
          _hiddenFor = 0;
          return;
        }
        _patrolFor += dt;
        if (_moveTo(bed, tuning.patrolSpeed, dt) && _patrolFor >= tuning.patrolTime) {
          meter.reset();
          meter.drowsyLeft = tuning.drowsyTime;
          _wakeCause = null;
          _settleInBed();
        }
    }
  }

  void _raise(int loudness, {bool fromTool = false}) {
    meter.hear(loudness);
    if (meter.value >= 100) {
      wake(fromTool ? WakeCause.tool : loudness == 0 ? WakeCause.footsteps : WakeCause.noise);
    } else if (inBed) {
      _settleInBed();
    }
  }

  /// In bed, her state follows the meter.
  void _settleInBed() {
    final next = meter.value >= 50
        ? GooseState.suspicious
        : meter.value >= 25
        ? GooseState.stirring
        : meter.drowsyLeft > 0
        ? GooseState.drowsy
        : GooseState.asleep;
    if (next == GooseState.asleep && _state != GooseState.asleep) _rollClock = 0;
    _state = next;
  }

  void _trackHiding(double dt, bool lost) {
    _hiddenFor = lost ? _hiddenFor + dt : 0;
    if (_hiddenFor >= tuning.hideToLose) _loseThem();
  }

  void _loseThem() {
    _state = GooseState.lostYou;
    _slipLeft = 0;
    _patrolFor = 0;
  }

  /// Runs down a slip; true while she is still on the floor.
  bool _slipped(double dt) {
    if (_slipLeft <= 0) return false;
    _slipLeft -= dt;
    return true;
  }

  /// Goes [dt] seconds along her route to [target]; true once she stands
  /// where the route ends. A flap, once begun, finishes first. A closed
  /// door on the way stops her short of it, pushing, until it gives.
  bool _moveTo(Vec target, double speed, double dt) {
    final flap = _flap;
    if (flap != null) {
      final t = flap.t + dt / tuning.flapTime;
      if (t < 1) {
        _flap = (to: flap.to, from: flap.from, land: flap.land, t: t);
      } else {
        _flap = null;
        _seg = flap.to;
        _x = flap.land.x;
      }
      return false;
    }

    final route = _route = nav.route(_seg, _x, target, speed: speed, doors: doors);
    var budget = speed * dt;
    for (final (i, m) in route.moves.indexed) {
      switch (m) {
        case Cross(:final to):
          _seg = to;
        case Flap(:final to, :final from, :final land):
          _flap = (to: to, from: from, land: land, t: 0);
          return false;
        case WalkTo(:final x):
          final dx = x - _x;
          final next = dx.abs() <= budget ? x : _x + (dx > 0 ? budget : -budget);
          final door = _seg.kind == SegKind.floor
              ? doors?.closedAhead(_x, next, tuning.doorStandOff, floorY: _seg.yLeft)
              : null;
          if (door != null) {
            final right = next > _x;
            final stop = right ? door.x - tuning.doorStandOff : door.x + tuning.doorStandOff;
            // Never backwards, even if a door shut right in front of her.
            if (right ? stop > _x : stop < _x) _x = stop;
            // Going no further than the door: as close as she gets is there.
            final last = i == route.moves.length - 1;
            if (last && (right ? x <= door.x : x >= door.x)) return true;
            _pushed = true;
            _pushFor += dt;
            if (_pushFor >= tuning.doorPushTime) {
              doors!.open(door.id, byGoose: true);
              _pushFor = 0;
            }
            return false;
          }
          budget -= (next - _x).abs();
          _x = next;
          if (_x != x) return false;
      }
    }
    return true;
  }
}
