import 'chain.dart';
import 'goose_brain.dart';
import 'heist.dart';
import 'level.dart';
import 'modifiers.dart';
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

/// She ran onto the spilled marbles at [x] and went down.
class GooseSlipped extends SimEvent {
  const GooseSlipped(this.x);

  final double x;
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

/// Pick up the portable object at [spotId] (Rearrange).
class MoveObject extends Interaction {
  const MoveObject(this.spotId, this.objectId);

  final String spotId;
  final String objectId;
}

/// Put the carried object down on the free snap spot [spotId].
class PlaceObject extends Interaction {
  const PlaceObject(this.spotId);

  final String spotId;
}

/// Duck into the hide spot at [x].
class Hide extends Interaction {
  const Hide(this.x);

  final double x;
}

/// Come out of the hide spot.
class Unhide extends Interaction {
  const Unhide();
}

/// Climb onto the crawlway from the floor by its end at [x].
class Climb extends Interaction {
  const Climb(this.x);

  final double x;
}

/// Climb down off the crawlway by its end at [x].
class ClimbDown extends Interaction {
  const ClimbDown(this.x);

  final double x;
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
    this.setup = const NightSetup(),
    this.score = 0,
    this.bestChain = 0,
    this.lures = 0,
    this.style = PlayStyle.ghost,
    this.goalsMet = const {},
  });

  final Level level;
  final Outcome outcome;

  /// The briefing's tool and modifiers, so a restart keeps them.
  final NightSetup setup;

  Tool get tool => setup.tool;

  /// Loot ids carried out (or held when caught), in the order grabbed.
  final List<String> loot;
  final List<LinkFired> wakeChain;
  final WakeCause? wakeCause;

  /// Seconds from the start of the night to the outcome.
  final double time;

  /// Link points, plus loot and goals on a getaway.
  final int score;

  /// The longest chaos combo.
  final int bestChain;

  /// Times she sleepwalked out of bed.
  final int lures;

  /// The badge: how the night went.
  final PlayStyle style;

  /// Heist goals met; only a getaway with loot meets any.
  final Set<PlayStyle> goalsMet;
}

/// One night in the house: the burglar, the chain kit and Gertrude, advanced
/// only by [tick].
class NightSim {
  NightSim(this.level, {this.setup = const NightSetup(), this.tuning = const Tuning()})
    : chain = ChainRunner(level, tuning),
      goose = GooseBrain(
        bedX: level.bedX,
        tuning: tuning,
        meterGain: setup.lightSleeper ? tuning.lightSleeperGain : 1,
      ),
      combo = Combo(tuning),
      _x = level.playerStart,
      _toolLeft = setup.tool == Tool.socks ? tuning.sockCount : 1 {
    _gooseSeen = goose.state;
  }

  final Level level;

  /// The briefing's tool and modifiers.
  final NightSetup setup;
  final Tuning tuning;

  Tool get tool => setup.tool;
  final ChainRunner chain;
  final GooseBrain goose;

  /// Tonight's chaos combo.
  final Combo combo;

  double _x;
  double _dir = 0;
  double _facing = 1;
  int _toolLeft;
  final List<Flight> _flights = [];
  ToyMouse? _mouse;
  double? _spillX;
  bool _sneak = false;
  bool _hidden = false;
  String? _held;
  bool _up = false;
  final List<String> _carried = [];
  final List<SimEvent> _events = [];
  final Map<int, List<LinkFired>> _chains = {};
  List<LinkFired> _wakeChain = const [];
  List<LinkFired>? _wakingChain;
  /// Her state as last reported; set at the start, not on first read, so
  /// a change before the first report still counts.
  late GooseState _gooseSeen;
  double _footClock = 0;
  double _squeakClock = 0;
  double? _caughtLeft;
  Outcome? _outcome;
  double _elapsed = 0;
  int _lures = 0;
  bool _seen = false;
  bool _woke = false;

  double get playerX => _x;
  bool get sneaking => _sneak;

  /// +1 facing right, -1 facing left: the way the burglar last moved.
  double get facing => _facing;

  /// Uses of [tool] left tonight.
  int get toolLeft => _toolLeft;

  /// Socks in the air.
  List<Flight> get flights => List.unmodifiable(_flights);

  /// The wind-up mouse, once it is set down.
  ToyMouse? get mouse => _mouse;

  /// Where the marbles lie, until she slips on them.
  double? get spillX => _spillX;

  /// Whether the Tool button does anything right now. Marbles only work
  /// once she is up and after someone.
  bool get toolReady =>
      _toolLeft > 0 &&
      !_frozen &&
      !_hidden &&
      _held == null &&
      (tool != Tool.marbles || goose.isAwake) &&
      (tool != Tool.mouse || !_up);

  /// Uses a tap tool: sets the mouse down, spills the marbles behind the
  /// burglar, or toots the kazoo. Socks are thrown with [throwSock].
  bool useTool() {
    if (tool == Tool.socks || !toolReady) return false;
    _toolLeft--;
    switch (tool) {
      case Tool.mouse:
        _mouse = ToyMouse(x: _x, dir: _facing);
      case Tool.marbles:
        _spillX = (_x - _facing * tuning.spillBehind).clamp(0, tuning.worldWidth).toDouble();
      case Tool.kazoo:
        _hear(Noise(x: _x, loudness: 3), tool: Tool.kazoo);
      case Tool.socks:
    }
    return true;
  }
  bool get hidden => _hidden;

  /// The portable object the burglar is carrying; his hands are full.
  String? get held => _held;

  /// Up on the crawlway: silent, out of her reach, only high loot in reach.
  bool get up => _up;
  List<String> get carried => List.unmodifiable(_carried);
  Outcome? get outcome => _outcome;

  /// Seconds ticked so far; stops when the night ends.
  double get elapsed => _elapsed;

  /// Seconds until the current combo runs out.
  double get comboLeft => combo.leftAt(_elapsed);

  /// Times she has sleepwalked out of bed.
  int get lures => _lures;

  /// Whether she has turned suspicious, or worse, tonight.
  bool get seen => _seen;

  /// Whether she has woken up tonight.
  bool get woke => _woke;

  /// Whether tonight so far does what [goal] asks, getaway or not.
  bool met(HeistGoal goal) => switch (goal.kind) {
    GoalKind.neverSuspicious => !_seen,
    GoalKind.lure => _lures >= goal.count,
    GoalKind.chain => combo.best >= goal.count,
  };

  /// The badge: Chaos if she woke, Trickster if she was lured, else Ghost.
  PlayStyle get style => _woke
      ? PlayStyle.chaos
      : _lures > 0
      ? PlayStyle.trickster
      : PlayStyle.ghost;

  NightResult? get result {
    final outcome = _outcome;
    if (outcome == null) return null;
    final escaped = outcome == Outcome.escaped;
    // A heist needs a haul: walking out empty-handed earns no sock.
    final goalsMet = {
      if (escaped && _carried.isNotEmpty)
        for (final g in level.goals)
          if (met(g)) g.style,
    };
    var score = combo.total;
    if (escaped) {
      for (final l in level.loot) {
        if (_carried.contains(l.id)) score += l.guarded ? tuning.guardedLootScore : tuning.lootScore;
      }
      score += tuning.goalScore * goalsMet.length;
    }
    return NightResult(
      level: level,
      outcome: outcome,
      loot: carried,
      wakeChain: _wakeChain,
      wakeCause: goose.wakeCause,
      time: _elapsed,
      setup: setup,
      score: score,
      bestChain: combo.best,
      lures: _lures,
      style: style,
      goalsMet: goalsMet,
    );
  }

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
    if (tool != Tool.socks || _toolLeft == 0 || _frozen || _hidden || _held != null) return false;
    _toolLeft--;
    _flights.add(Flight(fromX: _x, toX: throwLanding(aimX), duration: tuning.throwFlightTime, high: _up));
    return true;
  }

  /// Whether [spotId] holds an object that can still go off.
  bool _live(String spotId, {required bool squeakers}) {
    final id = chain.objectAt(spotId);
    if (id == null || chain.isSpent(id)) return false;
    return squeakers || _typeOf(id) != ObjectType.squeaker;
  }

  ObjectType _typeOf(String objectId) => level.objects.firstWhere((o) => o.id == objectId).type;

  /// What Interact does here. Hidden, it only comes out; carrying, it only
  /// puts down; up on the crawlway, high loot else climbing down. On the
  /// floor: the nearest loot, else a walker to wind, else a portable object
  /// to pick up, else a hide spot, else climbing up.
  Interaction? get interaction {
    if (_frozen) return null;
    if (_hidden) return const Unhide();
    if (_held != null) {
      final spot = _nearestSpot((s) => s.snap && chain.objectAt(s.id) == null);
      return spot == null ? null : PlaceObject(spot.id);
    }

    Loot? loot;
    for (final l in level.loot) {
      if (_carried.contains(l.id) || l.high != _up || (l.x - _x).abs() > tuning.reach) continue;
      if (loot == null || (l.x - _x).abs() < (loot.x - _x).abs()) loot = l;
    }
    if (loot != null) return GrabLoot(loot);
    final end = _crawlEndInReach();
    if (_up) return end == null ? null : ClimbDown(end);

    final walker = _nearestSpot((s) => _live(s.id, squeakers: false) && _typeOf(chain.objectAt(s.id)!) == ObjectType.walker);
    if (walker != null) return Wind(walker.id, chain.objectAt(walker.id)!);

    final portable = _nearestSpot((s) {
      final id = chain.objectAt(s.id);
      return id != null && chain.canLift(id);
    });
    if (portable != null) return MoveObject(portable.id, chain.objectAt(portable.id)!);

    final hide = _hideInReach();
    if (hide != null) return Hide(hide);
    return end == null ? null : Climb(end);
  }

  /// The end of the crawlway in reach, where he can get on or off.
  double? _crawlEndInReach() {
    final c = level.crawlway;
    if (c == null) return null;
    final end = (c.from - _x).abs() <= (c.to - _x).abs() ? c.from : c.to;
    return (end - _x).abs() <= tuning.reach ? end : null;
  }

  /// Climbs onto the crawlway, or back down, by an end in reach.
  bool toggleClimb() {
    if (_frozen || _hidden || _held != null || _crawlEndInReach() == null) return false;
    _up = !_up;
    if (_up) _x = _x.clamp(level.crawlway!.from, level.crawlway!.to);
    return true;
  }

  /// The nearest spot in reach that passes [test].
  Spot? _nearestSpot(bool Function(Spot) test) {
    Spot? best;
    for (final spot in level.spots.values) {
      final d = (spot.x - _x).abs();
      if (d > tuning.reach || (best != null && d >= (best.x - _x).abs()) || !test(spot)) continue;
      best = spot;
    }
    return best;
  }

  double? _hideInReach() {
    double? best;
    for (final h in level.hideSpots) {
      if ((h - _x).abs() <= tuning.reach && (best == null || (h - _x).abs() < (best - _x).abs())) best = h;
    }
    return best;
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
      case MoveObject(:final objectId):
        lift(objectId);
      case PlaceObject(:final spotId):
        place(spotId);
      case Hide() || Unhide():
        toggleHide();
      case Climb() || ClimbDown():
        toggleClimb();
      case null:
    }
    return i;
  }

  /// Picks up the portable object [objectId] if it stands within reach.
  bool lift(String objectId) {
    if (_frozen || _hidden || _held != null || _up) return false;
    final spotId = chain.spotOf(objectId);
    if (spotId == null || (level.spots[spotId]!.x - _x).abs() > tuning.reach) return false;
    if (!chain.lift(objectId)) return false;
    _held = objectId;
    return true;
  }

  /// Puts the carried object down on [spotId]: a free snap spot in reach.
  bool place(String spotId) {
    final held = _held;
    final spot = level.spots[spotId];
    if (_frozen || held == null || spot == null || !spot.snap) return false;
    if (chain.objectAt(spotId) != null || (spot.x - _x).abs() > tuning.reach) return false;
    chain.move(held, spotId);
    _held = null;
    return true;
  }

  bool grab(String lootId) {
    if (_frozen || _hidden || _held != null || _carried.contains(lootId)) return false;
    final loot = level.loot.where((l) => l.id == lootId).firstOrNull;
    if (loot == null || loot.high != _up || (loot.x - _x).abs() > tuning.reach) return false;
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
    if (_held != null || _up || _hideInReach() == null) return false;
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
    _walkMouse(h);
    chain.tick(h);
    for (final fired in chain.takeFired()) {
      (_chains[fired.chainId] ??= []).add(fired);
      combo.link(_elapsed);
      _hear(fired.noise, link: fired);
    }

    // Up on the crawlway he is as out of reach as in a hide spot.
    goose.tick(h, playerX: _x, playerHidden: _hidden || _up);
    _noteGoose();

    final spill = _spillX;
    final running = goose.state == GooseState.chase || goose.state == GooseState.distracted;
    if (spill != null && running && (goose.x - spill).abs() <= tuning.slipRadius) {
      goose.slip();
      _spillX = null;
      _events.add(GooseSlipped(goose.x));
    }

    if (goose.state == GooseState.chase && !_hidden && !_up && (goose.x - _x).abs() <= tuning.caughtDistance) {
      _caughtLeft = tuning.caughtAnim;
      _events.add(const CaughtStarted());
    }
  }

  void _movePlayer(double h) {
    if (_hidden || _dir == 0) return;
    final crawl = level.crawlway;
    if (_up && crawl != null) {
      // Crawling makes no sound at all.
      _x = (_x + _dir * tuning.crawlSpeed * h).clamp(crawl.from, crawl.to);
      return;
    }
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

  /// The mouse bumps the first live object ahead of it, squeakers too.
  void _walkMouse(double h) {
    final m = _mouse;
    if (m == null || m.stopped) return;
    final (from, to) = m.advance(h, tuning.mouseSpeed, min: 0, max: tuning.worldWidth);
    Spot? hit;
    for (final spot in level.spots.values) {
      final ahead = m.dir > 0 ? from < spot.x && spot.x <= to : to <= spot.x && spot.x < from;
      if (!ahead || !_live(spot.id, squeakers: true)) continue;
      if (hit == null || (spot.x - from).abs() < (hit.x - from).abs()) hit = spot;
    }
    if (hit != null) {
      m.stop(hit.x);
      chain.poke(hit.id);
    }
  }

  void _hear(Noise noise, {LinkFired? link, Tool? tool}) {
    _events.add(NoiseMade(noise, touchedEar: noise.touchesEar(goose.x, tuning), link: link, tool: tool));
    final wasAwake = goose.isAwake;
    goose.hear(noise, chainLinks: link?.link ?? 0, fromTool: tool != null);
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
      switch (goose.state) {
        case GooseState.sleepwalk:
          _lures++;
        case GooseState.awake:
          _woke = true;
          _seen = true;
        case GooseState.suspicious || GooseState.chase || GooseState.distracted || GooseState.lostYou:
          _seen = true;
        case _:
      }
      _events.add(GooseChanged(_gooseSeen, goose.state));
      _gooseSeen = goose.state;
    }
  }
}
