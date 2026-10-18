import 'noise.dart';
import 'noise_meter.dart';
import 'tuning.dart';

/// Goose brain v2: five states on the asleep side, four on the awake side.
enum GooseState { asleep, stirring, suspicious, sleepwalk, drowsy, awake, chase, distracted, lostYou }

enum WakeCause { noise, footsteps, grabbedGuarded }

enum _Walk { out, sniff, back }

/// Gertrude. She lives on the floor line; [x] is where she is now.
class GooseBrain {
  GooseBrain({required this.bedX, required this.tuning}) : _x = bedX, meter = NoiseMeter(tuning);

  final double bedX;
  final Tuning tuning;
  final NoiseMeter meter;

  double _x;
  GooseState _state = GooseState.asleep;
  WakeCause? _wakeCause;

  _Walk _walk = _Walk.out;
  double _target = 0;
  double? _lastNoiseX;

  /// Seconds left in the current timed phase: sniff, awake freeze, distraction.
  double _timer = 0;
  double _rollClock = 0;
  double _chaseLeft = 0;
  double _hiddenFor = 0;
  double _patrolFor = 0;
  double _slipLeft = 0;

  double get x => _x;
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

  /// Down on spilled marbles: she stands still while the chase clock runs.
  bool get slipping => _slipLeft > 0 && (_state == GooseState.chase || _state == GooseState.distracted);

  /// She runs onto spilled marbles. Ignored unless she is after someone.
  void slip() {
    if (_state == GooseState.chase || _state == GooseState.distracted) _slipLeft = tuning.slipTime;
  }

  /// A noise went off. [chainLinks] is its link number when a chain made it.
  void hear(Noise n, {int chainLinks = 0}) {
    _lastNoiseX = n.x;
    final touches = n.touchesEar(_x, tuning);
    if (inBed) {
      if (touches) {
        _raise(n.loudness);
      } else if (n.loudness >= 2) {
        // A loud noise far from her bed doesn't wake her — it moves her.
        _state = GooseState.sleepwalk;
        _walk = _Walk.out;
        _target = n.x;
      }
    } else if (_state == GooseState.sleepwalk) {
      if (n.loudness >= 2 && (touches || sniffing)) {
        wake(WakeCause.noise);
      } else if (touches) {
        _raise(n.loudness);
      }
    } else if (chainLinks >= 2 && (_state == GooseState.chase || _state == GooseState.distracted)) {
      _state = GooseState.distracted;
      _target = n.x;
      _timer = tuning.distractTime;
    }
  }

  /// HONK. Ignored if she is already up.
  void wake(WakeCause cause) {
    if (isAwake) return;
    _state = GooseState.awake;
    _wakeCause = cause;
    _timer = tuning.awakeFreeze;
    meter.reset(value: 100);
  }

  void tick(double dt, {required double playerX, required bool playerHidden}) {
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
            if (_moveTo(bedX, tuning.sleepwalkSpeed, dt)) {
              meter.drowsyLeft = tuning.drowsyTime;
              _settleInBed();
            }
        }
      case GooseState.awake:
        _timer -= dt;
        if (_timer <= 0) {
          _state = GooseState.chase;
          _chaseLeft = tuning.chaseTime;
          _hiddenFor = 0;
        }
      case GooseState.chase:
        _chaseLeft -= dt;
        if (!_slipped(dt)) _moveTo(playerHidden ? (_lastNoiseX ?? _x) : playerX, tuning.chaseSpeed, dt);
        _trackHiding(dt, playerHidden);
        if (_chaseLeft <= 0) _loseThem();
      case GooseState.distracted:
        if (!_slipped(dt)) _moveTo(_target, tuning.chaseSpeed, dt);
        _timer -= dt;
        _trackHiding(dt, playerHidden);
        if (_state == GooseState.distracted && _timer <= 0) _state = GooseState.chase;
      case GooseState.lostYou:
        // Grumpy, not blind: walk into her and the chase is back on.
        if (!playerHidden && (playerX - _x).abs() <= tuning.caughtDistance) {
          _state = GooseState.chase;
          _chaseLeft = tuning.chaseTime;
          _hiddenFor = 0;
          return;
        }
        _patrolFor += dt;
        if (_moveTo(bedX, tuning.patrolSpeed, dt) && _patrolFor >= tuning.patrolTime) {
          meter.reset();
          meter.drowsyLeft = tuning.drowsyTime;
          _wakeCause = null;
          _settleInBed();
        }
    }
  }

  void _raise(int loudness) {
    meter.hear(loudness);
    if (meter.value >= 100) {
      wake(loudness == 0 ? WakeCause.footsteps : WakeCause.noise);
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

  void _trackHiding(double dt, bool hidden) {
    _hiddenFor = hidden ? _hiddenFor + dt : 0;
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

  /// Steps toward [target]; true once she is standing on it.
  bool _moveTo(double target, double speed, double dt) {
    final step = speed * dt;
    if ((target - _x).abs() <= step) {
      _x = target;
      return true;
    }
    _x += target > _x ? step : -step;
    return false;
  }
}
