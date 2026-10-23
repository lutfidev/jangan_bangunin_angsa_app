import 'dart:math' as math;

import 'body.dart';
import 'chain.dart';
import 'doors.dart';
import 'geom.dart';
import 'goose_brain.dart';
import 'hearing.dart';
import 'heist.dart';
import 'level.dart';
import 'modifiers.dart';
import 'nav.dart';
import 'noise.dart';
import 'tools.dart';
import 'tuning.dart';

/// What happened during a tick, for the scene to draw.
sealed class SimEvent {
  const SimEvent();
}

/// A noise went off. [link] is set when a chain made it, [tool] when a
/// tool made it directly (a sock that missed, the kazoo), [door] when it
/// is a door creaking.
class NoiseMade extends SimEvent {
  const NoiseMade(this.noise, {required this.touchedEar, this.heard, this.link, this.tool, this.door});

  final Noise noise;
  final bool touchedEar;

  /// How it reached her, maybe muffled through a door; null if it didn't.
  final Heard? heard;
  final LinkFired? link;
  final Tool? tool;
  final String? door;
}

/// A door opened or shut, by Milo or by her pushing it.
class DoorMoved extends SimEvent {
  const DoorMoved(this.doorId, {required this.open, required this.byGoose});

  final String doorId;
  final bool open;
  final bool byGoose;
}

class GooseChanged extends SimEvent {
  const GooseChanged(this.from, this.to);

  final GooseState from;
  final GooseState to;
}

/// She ran onto the spilled marbles [at] her feet and went down.
class GooseSlipped extends SimEvent {
  const GooseSlipped(this.at);

  final Vec at;
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

/// Crawl into [vent]: from its `from` mouth when [forward], else from `to`.
class UseVent extends Interaction {
  const UseVent(this.vent, {required this.forward});

  final Vent vent;
  final bool forward;
}

/// Open or shut [door]; [open] is what pressing it does.
class UseDoor extends Interaction {
  const UseDoor(this.door, {required this.open});

  final Door door;
  final bool open;
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
    this.seen = false,
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

  /// She turned suspicious, or worse, at some point.
  final bool seen;
}

/// One night in the house: the burglar, the chain kit and Gertrude, advanced
/// only by [tick].
class NightSim {
  NightSim(Level level, {NightSetup setup = const NightSetup(), Tuning tuning = const Tuning()})
    : this._(level, Doors(level), Nav(level, tuning), setup, tuning);

  NightSim._(this.level, this.doors, this.nav, this.setup, this.tuning)
    : chain = ChainRunner(level, tuning),
      goose = GooseBrain(
        nav: nav,
        bed: level.bed,
        tuning: tuning,
        meterGain: setup.lightSleeper ? tuning.lightSleeperGain : 1,
        doors: doors,
      ),
      _hearing = Hearing(level, doors, tuning),
      _combo = Combo(tuning),
      _body = Body(level.geometry, level.playerStart, tuning, doors: doors, stairs: level.stairs),
      _toolLeft = setup.tool == Tool.socks ? tuning.sockCount : 1 {
    _gooseSeen = goose.state;
  }

  final Level level;

  /// Where she can walk.
  final Nav nav;

  /// The briefing's tool and modifiers.
  final NightSetup setup;
  final Tuning tuning;

  Tool get tool => setup.tool;
  final ChainRunner chain;
  final GooseBrain goose;

  /// Which doors stand open; Milo and she both change them.
  final Doors doors;
  final Hearing _hearing;

  /// How sound carries between rooms, for the debug overlay.
  Hearing get hearing => _hearing;

  final Combo _combo;

  /// Tonight's chaos combo, to read; only fired links feed it.
  ComboView get combo => _combo;

  final Body _body;
  double _dir = 0;
  double _facing = 1;
  int _vertical = 0;
  int _toolLeft;
  final List<Flight> _flights = [];
  ToyMouse? _mouse;
  Vec? _spill;
  bool _sneak = false;
  bool _hidden = false;

  /// Crawling through a vent: which, which way, and how far along (0..1).
  ({Vent vent, bool forward, double t})? _vent;
  String? _held;
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

  double get playerX => _vent == null ? _body.feet.x : ventAt.x;

  /// Where his feet are up the room: 270 on Night 3's floor.
  double get playerY => _vent == null ? _body.feet.y : ventAt.y;
  bool get grounded => _vent == null && _body.grounded;

  /// Standing on the floor, not on furniture or in the air.
  bool get onFloor => _vent == null && _body.onFloor;

  bool get onStairs => _body.onStairs;
  bool get inVent => _vent != null;

  /// Where he is in the vent he crawls through.
  Vec get ventAt {
    final v = _vent!;
    return v.vent.at(v.forward ? v.t : 1 - v.t);
  }

  /// The floor line the camera frames: his room's, his feet on a stair,
  /// and in a vent the mouths' floors as far along as he is.
  double get viewFloorY {
    final v = _vent;
    if (v != null) {
      final from = level.floorOf(v.forward ? v.vent.from : v.vent.to);
      final to = level.floorOf(v.forward ? v.vent.to : v.vent.from);
      return from + (to - from) * v.t;
    }
    return onStairs ? playerY : level.floorOf(_body.feet);
  }

  /// The furniture top he stands on, if any.
  Platform? get standingOn => _body.standingOn;

  /// On a crawl top: slow, silent, no jumping.
  bool get crawling => _body.crawling;
  bool get mantling => _body.mantling;

  /// Up on the stick would climb onto something, or step onto a stair, now.
  bool get canMantle =>
      !_frozen && !_hidden && _vent == null && (_body.canClimbStairs || (_held == null && _body.canMantle));

  /// Down on the stick would drop through what he stands on, or step down
  /// a stair.
  bool get canDrop => !_frozen && !_hidden && _vent == null && (_body.canDrop || _body.canDescendStairs);

  /// Whether the Jump button does anything right now. In the air it does:
  /// the press waits for the landing.
  bool get jumpReady =>
      !_frozen &&
      !_hidden &&
      _vent == null &&
      _held == null &&
      !_body.mantling &&
      !_body.crawling &&
      !_body.onStairs;

  /// Out of her reach: higher than her neck stretches.
  /// She sees him: he isn't tucked away, and they share a room (a stair is
  /// in both rooms it joins, a doorway in both rooms either side).
  bool get sees {
    if (_hidden || _vent != null) return false;
    final hers = level.roomsAround(goose.at);
    return level.roomsAround(Vec(playerX, playerY)).any(hers.contains);
  }
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
  Vec? get spill => _spill;
  double? get spillX => _spill?.x;

  /// Whether the Tool button does anything right now. Marbles only work
  /// once she is up and after someone.
  bool get toolReady =>
      _toolLeft > 0 &&
      !_frozen &&
      !_hidden &&
      _vent == null &&
      _held == null &&
      (tool != Tool.marbles || goose.isAwake) &&
      // The mouse and the marbles go on the floor.
      ((tool != Tool.mouse && tool != Tool.marbles) || onFloor);

  /// Uses a tap tool: sets the mouse down, spills the marbles behind the
  /// burglar, or toots the kazoo. Socks are thrown with [throwSock].
  bool useTool() {
    if (tool == Tool.socks || !toolReady) return false;
    _toolLeft--;
    switch (tool) {
      case Tool.mouse:
        _mouse = ToyMouse(x: playerX, y: floorY, dir: facing);
      case Tool.marbles:
        _spill = Vec((playerX - facing * tuning.spillBehind).clamp(0, level.width).toDouble(), floorY);
      case Tool.kazoo:
        _hear(Noise(x: playerX, y: playerY, loudness: 3), tool: Tool.kazoo);
      case Tool.socks:
    }
    return true;
  }
  bool get hidden => _hidden;

  /// The portable object the burglar is carrying; his hands are full.
  String? get held => _held;

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
      seen: _seen,
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

  /// Joystick y, -1 (up) to 1 (down). It counts only past
  /// [Tuning.verticalThreshold], so walking on a slant never climbs; one
  /// climb or drop per push.
  void setVertical(double dir) =>
      _vertical = dir < -tuning.verticalThreshold ? -1 : (dir > tuning.verticalThreshold ? 1 : 0);

  /// The Jump button: jumps now, or on landing if pressed just before.
  void jump() {
    if (jumpReady) _body.pressJump();
  }

  void setSneak(bool on) => _sneak = on;

  /// Sets off the object at [spotId]: a bump, a thrown sock, a wound-up toy.
  void poke(String spotId) {
    if (!_frozen) chain.poke(spotId);
  }

  /// Where a sock aimed at [aimX] comes down: within [Tuning.throwRange]
  /// of the burglar, inside the room (or rooms, in a doorway) he is in, and
  /// short of a closed door.
  double throwLanding(double aimX) {
    final rooms = level.roomsAt(Vec(playerX, playerY));
    final free = doors.freeSpan(playerX, floorY: floorY);
    final left = math.max(free.min, rooms.isEmpty ? 0.0 : rooms.map((r) => r.box.left).reduce(math.min));
    final right = math.min(free.max, rooms.isEmpty ? level.width : rooms.map((r) => r.box.right).reduce(math.max));
    return aimX.clamp(playerX - tuning.throwRange, playerX + tuning.throwRange).clamp(left, right).toDouble();
  }

  /// The floor line of the room he is in.
  double get floorY => level.floorOf(Vec(playerX, playerY));

  /// The spot a sock landing at [landingX] on the floor line [floorY] would
  /// hit: the nearest one on that storey in [Tuning.throwHitRadius] holding
  /// something that can still go off, on this side of any closed door.
  /// Squeakers are stepped on, not hit.
  String? throwTarget(double landingX, double floorY) {
    String? best;
    var bestD = double.infinity;
    final free = doors.freeSpan(landingX, floorY: floorY);
    for (final spot in level.spots.values) {
      final d = (spot.x - landingX).abs();
      if (d > tuning.throwHitRadius || d >= bestD || !_live(spot.id, squeakers: false)) continue;
      if (level.floorOf(spot.at) != floorY) continue;
      if (spot.x < free.min || spot.x > free.max) continue;
      best = spot.id;
      bestD = d;
    }
    return best;
  }

  /// Lobs a sock at [aimX]. False if there is none to throw.
  bool throwSock(double aimX) {
    if (tool != Tool.socks || _toolLeft == 0 || _frozen || _hidden || _vent != null || _held != null) return false;
    _toolLeft--;
    _flights.add(Flight(
      fromX: playerX,
      fromY: playerY - tuning.handHeight,
      toX: throwLanding(aimX),
      toY: floorY,
      duration: tuning.throwFlightTime,
    ));
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
  /// puts down. Otherwise the nearest loot in reach, else a walker to wind,
  /// else a portable object to pick up, else a door, else a vent, else a
  /// hide spot. On a stair or in a vent, nothing.
  Interaction? get interaction {
    if (_frozen || _vent != null || onStairs) return null;
    if (_hidden) return const Unhide();
    if (_held != null) {
      final spot = _nearestSpot((s) => s.snap && chain.objectAt(s.id) == null);
      return spot == null ? null : PlaceObject(spot.id);
    }

    Loot? loot;
    for (final l in level.loot) {
      if (_carried.contains(l.id) || !_reaches(l.at)) continue;
      if (loot == null || (l.x - playerX).abs() < (loot.x - playerX).abs()) loot = l;
    }
    if (loot != null) return GrabLoot(loot);

    final walker = _nearestSpot((s) => _live(s.id, squeakers: false) && _typeOf(chain.objectAt(s.id)!) == ObjectType.walker);
    if (walker != null) return Wind(walker.id, chain.objectAt(walker.id)!);

    final portable = _nearestSpot((s) {
      final id = chain.objectAt(s.id);
      return id != null && chain.canLift(id);
    });
    if (portable != null) return MoveObject(portable.id, chain.objectAt(portable.id)!);

    final door = _doorInReach();
    if (door != null) return UseDoor(door, open: !doors.isOpen(door.id));

    final vent = _ventInReach();
    if (vent != null) return vent;

    final hide = _hideInReach();
    return hide == null ? null : Hide(hide);
  }

  /// Whether [p] is within his arm's reach: [Tuning.reach] either side, and
  /// from a little below his feet up to [Tuning.armReach] above them.
  bool _reaches(Vec p) =>
      (p.x - playerX).abs() <= tuning.reach && p.y >= playerY - tuning.armReach && p.y <= playerY + 10;

  /// The nearest spot in reach that passes [test].
  Spot? _nearestSpot(bool Function(Spot) test) {
    Spot? best;
    for (final spot in level.spots.values) {
      final d = (spot.x - playerX).abs();
      if (!_reaches(spot.at) || (best != null && d >= (best.x - playerX).abs()) || !test(spot)) continue;
      best = spot;
    }
    return best;
  }

  /// The nearest door in reach that he could open or shut right now.
  Door? _doorInReach() {
    if (!_body.grounded) return null;
    Door? best;
    for (final d in doors.all) {
      if (!_reaches(d.handle) || !_canToggle(d)) continue;
      if (best == null || (d.x - playerX).abs() < (best.x - playerX).abs()) best = d;
    }
    return best;
  }

  /// Opening always works; shutting doesn't with him, her or the mouse in
  /// the doorway.
  bool _canToggle(Door d) {
    if (!doors.isOpen(d.id)) return true;
    final inDoorway = (playerX - d.x).abs() < tuning.bodyWidth / 2 + Door.thickness / 2;
    final gooseThere = (goose.x - d.x).abs() < tuning.doorStandOff && (goose.y - d.floorY).abs() <= 2;
    final m = _mouse;
    final mouseThere = m != null && m.y == d.floorY && (m.x - d.x).abs() < Door.thickness / 2 + 15;
    return !inDoorway && !gooseThere && !mouseThere;
  }

  /// The nearest vent mouth in reach, while he stands on something.
  UseVent? _ventInReach() {
    if (!_body.grounded) return null;
    UseVent? best;
    double? bestD;
    for (final v in level.vents) {
      for (final (mouth, forward) in [(v.from, true), (v.to, false)]) {
        final d = (mouth.x - playerX).abs();
        if (!_reaches(mouth) || (bestD != null && d >= bestD)) continue;
        best = UseVent(v, forward: forward);
        bestD = d;
      }
    }
    return best;
  }

  /// Crawls into [ventId] at the mouth in reach. Hands must be empty.
  bool enterVent(String ventId) {
    if (_frozen || _hidden || _vent != null || _held != null || onStairs) return false;
    final use = _ventInReach();
    if (use == null || use.vent.id != ventId) return false;
    _vent = (vent: use.vent, forward: use.forward, t: 0);
    return true;
  }

  double? _hideInReach() {
    double? best;
    if (!_body.grounded) return null;
    for (final h in level.hideSpots) {
      if (!_reaches(h)) continue;
      if (best == null || (h.x - playerX).abs() < (best - playerX).abs()) best = h.x;
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
      case UseDoor(:final door):
        useDoor(door.id);
      case UseVent(:final vent):
        enterVent(vent.id);
      case null:
    }
    return i;
  }

  /// Picks up the portable object [objectId] if it stands within reach.
  bool lift(String objectId) {
    if (_frozen || _hidden || _held != null) return false;
    final spotId = chain.spotOf(objectId);
    if (spotId == null || !_reaches(level.spots[spotId]!.at)) return false;
    if (!chain.lift(objectId)) return false;
    _held = objectId;
    return true;
  }

  /// Puts the carried object down on [spotId]: a free snap spot in reach.
  bool place(String spotId) {
    final held = _held;
    final spot = level.spots[spotId];
    if (_frozen || held == null || spot == null || !spot.snap) return false;
    if (chain.objectAt(spotId) != null || !_reaches(spot.at)) return false;
    chain.move(held, spotId);
    _held = null;
    return true;
  }

  bool grab(String lootId) {
    if (_frozen || _hidden || _held != null || _carried.contains(lootId)) return false;
    final loot = level.loot.where((l) => l.id == lootId).firstOrNull;
    if (loot == null || !_reaches(loot.at)) return false;
    // She guards it from her bed, including while she stands there patrolling.
    final guarding = goose.inBed || (goose.state == GooseState.lostYou && goose.at == level.bed);
    if (loot.guarded && guarding && !goose.rollingOver) {
      goose.wake(WakeCause.grabbedGuarded);
      _noteGoose();
      return false;
    }
    _carried.add(lootId);
    _events.add(LootGrabbed(lootId));
    return true;
  }

  /// Opens or shuts the door [doorId] if its handle is in reach. It creaks
  /// unless he sneaks.
  bool useDoor(String doorId) {
    final door = doors.all.where((d) => d.id == doorId).firstOrNull;
    if (_frozen || _hidden || door == null || !_body.grounded || !_reaches(door.handle) || !_canToggle(door)) {
      return false;
    }
    doors.isOpen(doorId) ? doors.close(doorId) : doors.open(doorId);
    _noteDoors();
    if (!_sneak) _hear(Noise(x: door.x, y: door.floorY, loudness: tuning.doorCreak), door: doorId);
    return true;
  }

  void _noteDoors() {
    for (final m in doors.takeMoves()) {
      _events.add(DoorMoved(m.doorId, open: m.open, byGoose: m.byGoose));
    }
  }

  /// Ducks into (or out of) a hide spot within reach.
  bool toggleHide() {
    if (_frozen) return false;
    if (_hidden) {
      _hidden = false;
      return true;
    }
    if (_held != null || _hideInReach() == null) return false;
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
      // Caught mid-jump, he still comes down; nothing he does counts now.
      if (!_hidden) _body.step(h, move: 0, vertical: 0, sneak: _sneak, canClimb: false);
      _caughtLeft = _caughtLeft! - h;
      if (_caughtLeft! <= 0) _outcome = Outcome.caught;
      return;
    }

    _crawlVent(h);
    _movePlayer(h);
    if (onFloor && playerX >= level.exitX && (playerY - level.exit.y).abs() <= 2) {
      _outcome = Outcome.escaped;
      _events.add(Escaped(carried));
      return;
    }

    _landSocks(h);
    _walkMouse(h);
    chain.tick(h);
    for (final fired in chain.takeFired()) {
      (_chains[fired.chainId] ??= []).add(fired);
      _combo.link(_elapsed);
      _hear(fired.noise, link: fired);
    }

    final player = Vec(playerX, playerY);
    final sees = this.sees;
    goose.tick(h, player: player, sees: sees, hidden: _hidden || _vent != null);
    _noteDoors();
    _noteGoose();

    final spill = _spill;
    final running = goose.state == GooseState.chase || goose.state == GooseState.distracted;
    if (spill != null && running && (goose.x - spill.x).abs() <= tuning.slipRadius && (goose.y - spill.y).abs() <= 2) {
      goose.slip();
      _spill = null;
      _events.add(GooseSlipped(goose.at));
    }

    // Up out of her reach he is as safe as in a hide spot.
    if (goose.state == GooseState.chase && sees && !goose.flapping && nav.catches(goose.at, player)) {
      _caughtLeft = tuning.caughtAnim;
      _events.add(const CaughtStarted());
    }
  }

  /// Silent and unseen, mouth to mouth at [Tuning.ventSpeed]; then he
  /// stands at the far mouth, facing the way he went.
  void _crawlVent(double h) {
    final v = _vent;
    if (v == null) return;
    final t = v.t + h * tuning.ventSpeed / v.vent.length;
    if (t < 1) {
      _vent = (vent: v.vent, forward: v.forward, t: t);
      return;
    }
    final from = v.forward ? v.vent.from : v.vent.to;
    final to = v.forward ? v.vent.to : v.vent.from;
    _vent = null;
    _body.placeAt(to);
    if (to.x != from.x) _facing = (to.x - from.x).sign;
  }

  void _movePlayer(double h) {
    if (_hidden || _vent != null) return;
    final from = playerX;
    final wasOnFloor = onFloor;
    final landing = _body.step(h, move: _dir, vertical: _vertical, sneak: _sneak, canClimb: _held == null);
    if (landing != null) {
      final loudness = landingLoudness(landing, sneak: _sneak, t: tuning);
      if (loudness != null) _hear(Noise(x: landing.at.x, y: landing.at.y, loudness: loudness));
    }
    final to = playerX;
    // Only walking makes steps: not in the air, not crawling (always
    // silent), not mantling, not sneaking.
    if (to == from || !(_body.grounded || _body.onStairs) || crawling || _sneak) return;

    // Squeakers on the floor go off underfoot; Sneak steps over them.
    if (wasOnFloor && onFloor) {
      for (final spot in level.spots.values) {
        final crossed = from < to ? from < spot.x && spot.x <= to : to <= spot.x && spot.x < from;
        if (!crossed || spot.at.y != playerY) continue;
        final id = chain.objectAt(spot.id);
        if (id != null && level.objects.any((o) => o.id == id && o.type == ObjectType.squeaker)) {
          chain.poke(spot.id);
        }
      }
    }

    _footClock += h;
    if (_footClock >= tuning.footstepEvery) {
      _footClock -= tuning.footstepEvery;
      _hear(Noise(x: to, y: playerY, loudness: 0));
    }
    if (_carried.any((id) => level.loot.any((l) => l.id == id && l.squeaks))) {
      _squeakClock += h;
      if (_squeakClock >= tuning.squeakCarryEvery) {
        _squeakClock -= tuning.squeakCarryEvery;
        _hear(Noise(x: to, y: playerY, loudness: 1));
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
      final target = throwTarget(f.toX, f.toY);
      if (target != null) {
        chain.poke(target);
      } else {
        _hear(Noise(x: f.toX, y: f.toY, loudness: 0), tool: Tool.socks);
      }
    }
  }

  /// The mouse bumps the first live object ahead of it, squeakers too.
  void _walkMouse(double h) {
    final m = _mouse;
    if (m == null || m.stopped) return;
    final span = doors.freeSpan(m.x, floorY: m.y);
    final (from, to) = m.advance(h, tuning.mouseSpeed, min: span.min, max: span.max);
    Spot? hit;
    for (final spot in level.spots.values) {
      final ahead = m.dir > 0 ? from < spot.x && spot.x <= to : to <= spot.x && spot.x < from;
      if (!ahead || level.floorOf(spot.at) != m.y || !_live(spot.id, squeakers: true)) continue;
      if (hit == null || (spot.x - from).abs() < (hit.x - from).abs()) hit = spot;
    }
    if (hit != null) {
      m.stop(hit.x);
      chain.poke(hit.id);
    }
  }

  void _hear(Noise noise, {LinkFired? link, Tool? tool, String? door}) {
    final ear = goose.at;
    final heard = _hearing.reach(noise, ear);
    _events.add(NoiseMade(
      noise,
      touchedEar: heard != null && heard.noise.touchesEar(ear, tuning),
      heard: heard,
      link: link,
      tool: tool,
      door: door,
    ));
    if (heard == null) return;
    final wasAwake = goose.isAwake;
    goose.hear(heard.noise, chainLinks: link?.link ?? 0, fromTool: tool != null, source: heard.source);
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
