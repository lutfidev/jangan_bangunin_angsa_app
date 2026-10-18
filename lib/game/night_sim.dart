import 'chain.dart';
import 'goose_brain.dart';
import 'level.dart';
import 'noise.dart';
import 'tools.dart';
import 'tuning.dart';

/// What happened during a tick, for the scene to draw.
sealed class SimEvent {
  const SimEvent();
}

/// A noise went off. [link] is set when a chain made it, [tool] when a
/// tool made it directly (a sock that missed, the kazoo).
class NoiseMade extends SimEvent {
  const NoiseMade(this.noise, {required this.touchedEar, this.link, this.tool});

  final Noise noise;
  final bool touchedEar;
  final LinkFired? link;
  final Tool? tool;
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

/// What the Interact button would do right now.
sealed class Interaction {
  const Interaction();
}

class GrabLoot extends Interaction {
  const GrabLoot(this.loot);

  final Loot loot;
}

/// Wind up the walker at [spotId] and let it go.
class Wind extends Interaction {
  const Wind(this.spotId, this.objectId);

  final String spotId;
  final String objectId;
}

/// How a night ended, for the Caught and Victory screens.
class NightResult {
  const NightResult({
    required this.level,
    required this.outcome,
    required this.loot,
    this.wakeChain = const [],
    this.wakeCause,
    required this.time,
    this.tool = Tool.socks,
  });

  final Level level;
  final Outcome outcome;

  /// The tool picked at the briefing, so a restart keeps it.
  final Tool tool;

  /// Loot ids carried out (or held when caught), in the order grabbed.
  final List<String> loot;
  final List<LinkFired> wakeChain;
  final WakeCause? wakeCause;

  /// Seconds from the start of the night to the outcome.
  final double time;
}

/// One night in the house: the burglar, the chain kit and Gertrude, advanced
/// only by [tick].
class NightSim {
  NightSim(this.level, {this.tool = Tool.socks, this.tuning = const Tuning()})
    : chain = ChainRunner(level, tuning),
      goose = GooseBrain(bedX: level.bedX, tuning: tuning),
      _x = level.playerStart,
      _toolLeft = tool == Tool.socks ? tuning.sockCount : 1;

  final Level level;
  final Tool tool;
  final Tuning tuning;
  final ChainRunner chain;
  final GooseBrain goose;

  double _x;
  double _dir = 0;
  double _facing = 1;
  int _toolLeft;
  final List<Flight> _flights = [];
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
  double _elapsed = 0;

  double get playerX => _x;
  bool get sneaking => _sneak;

  /// +1 facing right, -1 facing left: the way the burglar last moved.
  double get facing => _facing;

  /// Uses of [tool] left tonight.
  int get toolLeft => _toolLeft;

  /// Socks in the air.
  List<Flight> get flights => List.unmodifiable(_flights);
  bool get hidden => _hidden;
  List<String> get carried => List.unmodifiable(_carried);
  Outcome? get outcome => _outcome;

  /// Seconds ticked so far; stops when the night ends.
  double get elapsed => _elapsed;

  NightResult? get result => _outcome == null
      ? null
      : NightResult(
          level: level,
          outcome: _outcome!,
          loot: carried,
          wakeChain: _wakeChain,
          wakeCause: goose.wakeCause,
          time: _elapsed,
          tool: tool,
        );

  /// The links of the chain that woke her, for the Caught recap.
  List<LinkFired> get wakeChain => _wakeChain;

  bool get _frozen => _outcome != null || _caughtLeft != null;

  /// Joystick direction, -1 (left) to 1 (right).
  void setMove(double dir) {
    _dir = dir.clamp(-1, 1);
    if (_dir != 0) _facing = _dir.sign;
  }

  void setSneak(bool on) => _sneak = on;

  /// Sets off the object at [spotId]: a bump, a thrown sock, a wound-up toy.
  void poke(String spotId) {
    if (!_frozen) chain.poke(spotId);
  }

  /// Where a sock aimed at [aimX] comes down: within [Tuning.throwRange]
  /// of the burglar, inside the room.
  double throwLanding(double aimX) => aimX
      .clamp(_x - tuning.throwRange, _x + tuning.throwRange)
      .clamp(0, tuning.worldWidth)
      .toDouble();

  /// The spot a sock landing at [landingX] would hit: the nearest one in
  /// [Tuning.throwHitRadius] holding something that can still go off.
  /// Squeakers are stepped on, not hit.
  String? throwTarget(double landingX) {
    String? best;
    var bestD = double.infinity;
    for (final spot in level.spots.values) {
      final d = (spot.x - landingX).abs();
      if (d > tuning.throwHitRadius || d >= bestD || !_live(spot.id, squeakers: false)) continue;
      best = spot.id;
      bestD = d;
    }
    return best;
  }

  /// Lobs a sock at [aimX]. False if there is none to throw.
  bool throwSock(double aimX) {
    if (tool != Tool.socks || _toolLeft == 0 || _frozen || _hidden) return false;
    _toolLeft--;
    _flights.add(Flight(fromX: _x, toX: throwLanding(aimX), duration: tuning.throwFlightTime));
    return true;
  }

  /// Whether [spotId] holds an object that can still go off.
  bool _live(String spotId, {required bool squeakers}) {
    final id = chain.objectAt(spotId);
    if (id == null || chain.isSpent(id)) return false;
    return squeakers || _typeOf(id) != ObjectType.squeaker;
  }

  ObjectType _typeOf(String objectId) => level.objects.firstWhere((o) => o.id == objectId).type;

  /// The nearest loot in reach, else a walker in reach to wind up.
  Interaction? get interaction {
    if (_frozen || _hidden) return null;
    Loot? loot;
    for (final l in level.loot) {
      if (_carried.contains(l.id) || (l.x - _x).abs() > tuning.reach) continue;
      if (loot == null || (l.x - _x).abs() < (loot.x - _x).abs()) loot = l;
    }
    if (loot != null) return GrabLoot(loot);

    Wind? wind;
    double best = double.infinity;
    for (final spot in level.spots.values) {
      final d = (spot.x - _x).abs();
      final id = chain.objectAt(spot.id);
      if (d > tuning.reach || d >= best || id == null || chain.isSpent(id)) continue;
      if (_typeOf(id) != ObjectType.walker) continue;
      wind = Wind(spot.id, id);
      best = d;
    }
    return wind;
  }

  /// Does what [interaction] offers and returns it, or null if nothing was
  /// in reach. A refused grab of the guarded loot still counts: she wakes.
  Interaction? interact() {
    final i = interaction;
    switch (i) {
      case GrabLoot(:final loot):
        grab(loot.id);
      case Wind(:final spotId):
        poke(spotId);
      case null:
    }
    return i;
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
      _elapsed += dt / steps;
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

    _landSocks(h);
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
    _x = (_x + _dir * (_sneak ? tuning.sneakSpeed : tuning.walkSpeed) * h).clamp(0, tuning.worldWidth);
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

  /// A sock that lands on something sets it off; on bare floor it flops.
  void _landSocks(double h) {
    for (final f in _flights) {
      f.advance(h);
    }
    for (final f in _flights.where((f) => f.landed).toList()) {
      _flights.remove(f);
      final target = throwTarget(f.toX);
      if (target != null) {
        chain.poke(target);
      } else {
        _hear(Noise(x: f.toX, loudness: 0), tool: Tool.socks);
      }
    }
  }

  void _hear(Noise noise, {LinkFired? link, Tool? tool}) {
    _events.add(NoiseMade(noise, touchedEar: noise.touchesEar(goose.x, tuning), link: link, tool: tool));
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
