import 'chain.dart';
import 'goose_brain.dart';
import 'level.dart';
import 'noise.dart';
import 'tuning.dart';

/// What happened during a tick, for the scene to draw.
sealed class SimEvent {
  const SimEvent();
}

/// A noise went off. [link] is set when a chain made it.
class NoiseMade extends SimEvent {
  const NoiseMade(this.noise, {required this.touchedEar, this.link});

  final Noise noise;
  final bool touchedEar;
  final LinkFired? link;
}

class GooseChanged extends SimEvent {
  const GooseChanged(this.from, this.to);

  final GooseState from;
  final GooseState to;
}

class LootGrabbed extends SimEvent {
  const LootGrabbed(this.id);

  final String id;
}

/// The goose has landed on Milo; the night ends after the caught animation.
class CaughtStarted extends SimEvent {
  const CaughtStarted();
}

class Escaped extends SimEvent {
  const Escaped(this.loot);

  final List<String> loot;
}

enum Outcome { escaped, caught }

/// One night in the house: the burglar, the chain kit and Gertrude, advanced
/// only by [tick].
class NightSim {
  NightSim(this.level, {this.tuning = const Tuning()})
    : chain = ChainRunner(level, tuning),
      goose = GooseBrain(bedX: level.bedX, tuning: tuning),
      _x = level.playerStart;

  final Level level;
  final Tuning tuning;
  final ChainRunner chain;
  final GooseBrain goose;

  double _x;
  double _dir = 0;
  bool _sneak = false;
  bool _hidden = false;
  final List<String> _carried = [];
  final List<SimEvent> _events = [];
  final Map<int, List<LinkFired>> _chains = {};
  List<LinkFired> _wakeChain = const [];
  List<LinkFired>? _wakingChain;
  late GooseState _gooseSeen = goose.state;
  double _footClock = 0;
  double _squeakClock = 0;
  double? _caughtLeft;
  Outcome? _outcome;

  double get playerX => _x;
  bool get sneaking => _sneak;
  bool get hidden => _hidden;
  List<String> get carried => List.unmodifiable(_carried);
  Outcome? get outcome => _outcome;

  /// The links of the chain that woke her, for the Caught recap.
  List<LinkFired> get wakeChain => _wakeChain;

  bool get _frozen => _outcome != null || _caughtLeft != null;

  /// Joystick direction, -1 (left) to 1 (right).
  void setMove(double dir) => _dir = dir.clamp(-1, 1);

  void setSneak(bool on) => _sneak = on;

  /// Sets off the object at [spotId]: a bump, a thrown sock, a wound-up toy.
  void poke(String spotId) {
    if (!_frozen) chain.poke(spotId);
  }

  bool grab(String lootId) {
    if (_frozen || _hidden || _carried.contains(lootId)) return false;
    final loot = level.loot.where((l) => l.id == lootId).firstOrNull;
    if (loot == null || (loot.x - _x).abs() > tuning.reach) return false;
    // She guards it from her bed, including while she stands there patrolling.
    final guarding = goose.inBed || (goose.state == GooseState.lostYou && goose.x == level.bedX);
    if (loot.guarded && guarding && !goose.rollingOver) {
      goose.wake(WakeCause.grabbedGuarded);
      _noteGoose();
      return false;
    }
    _carried.add(lootId);
    _events.add(LootGrabbed(lootId));
    return true;
  }

  /// Ducks into (or out of) a hide spot within reach.
  bool toggleHide() {
    if (_frozen) return false;
    if (_hidden) {
      _hidden = false;
      return true;
    }
    if (!level.hideSpots.any((h) => (h - _x).abs() <= tuning.reach)) return false;
    _hidden = true;
    return true;
  }

  void tick(double dt) {
    if (_outcome != null || dt <= 0) return;
    final steps = (dt / tuning.maxStep).ceil();
    for (var i = 0; i < steps && _outcome == null; i++) {
      _step(dt / steps);
    }
  }

  List<SimEvent> takeEvents() {
    final events = List.of(_events);
    _events.clear();
    return events;
  }

  void _step(double h) {
    if (_caughtLeft != null) {
      _caughtLeft = _caughtLeft! - h;
      if (_caughtLeft! <= 0) _outcome = Outcome.caught;
      return;
    }

    _movePlayer(h);
    if (_x >= level.exitX) {
      _outcome = Outcome.escaped;
      _events.add(Escaped(carried));
      return;
    }

    chain.tick(h);
    for (final fired in chain.takeFired()) {
      (_chains[fired.chainId] ??= []).add(fired);
      _hear(fired.noise, link: fired);
    }

    goose.tick(h, playerX: _x, playerHidden: _hidden);
    _noteGoose();

    if (goose.state == GooseState.chase && !_hidden && (goose.x - _x).abs() <= tuning.caughtDistance) {
      _caughtLeft = tuning.caughtAnim;
      _events.add(const CaughtStarted());
    }
  }

  void _movePlayer(double h) {
    if (_hidden || _dir == 0) return;
    final from = _x;
    _x = (_x + _dir * (_sneak ? tuning.sneakSpeed : tuning.walkSpeed) * h).clamp(0, 844);
    if (_x == from || _sneak) return;

    // Squeakers go off underfoot; Sneak steps over them.
    for (final spot in level.spots.values) {
      final crossed = from < _x ? from < spot.x && spot.x <= _x : _x <= spot.x && spot.x < from;
      final id = chain.objectAt(spot.id);
      if (crossed && id != null && level.objects.any((o) => o.id == id && o.type == ObjectType.squeaker)) {
        chain.poke(spot.id);
      }
    }

    _footClock += h;
    if (_footClock >= tuning.footstepEvery) {
      _footClock -= tuning.footstepEvery;
      _hear(Noise(x: _x, loudness: 0));
    }
    if (_carried.any((id) => level.loot.any((l) => l.id == id && l.squeaks))) {
      _squeakClock += h;
      if (_squeakClock >= tuning.squeakCarryEvery) {
        _squeakClock -= tuning.squeakCarryEvery;
        _hear(Noise(x: _x, loudness: 1));
      }
    }
  }

  void _hear(Noise noise, {LinkFired? link}) {
    _events.add(NoiseMade(noise, touchedEar: noise.touchesEar(goose.x, tuning), link: link));
    final wasAwake = goose.isAwake;
    goose.hear(noise, chainLinks: link?.link ?? 0);
    if (!wasAwake && goose.isAwake && link != null) {
      _wakingChain = List.unmodifiable(_chains[link.chainId]!);
    }
    _noteGoose();
  }

  void _noteGoose() {
    if (goose.state == GooseState.awake && _gooseSeen != GooseState.awake) {
      // A wake no chain caused (footsteps, grabbing the egg) has no chain to recap.
      _wakeChain = _wakingChain ?? const [];
      _wakingChain = null;
    }
    if (goose.state != _gooseSeen) {
      _events.add(GooseChanged(_gooseSeen, goose.state));
      _gooseSeen = goose.state;
    }
  }
}
