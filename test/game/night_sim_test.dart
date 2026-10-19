import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/goose_brain.dart';
import 'package:jangan_bangunin_angsa_app/game/heist.dart';
import 'package:jangan_bangunin_angsa_app/game/level.dart';
import 'package:jangan_bangunin_angsa_app/game/modifiers.dart';
import 'package:jangan_bangunin_angsa_app/game/night_sim.dart';
import 'package:jangan_bangunin_angsa_app/game/noise.dart';
import 'package:jangan_bangunin_angsa_app/game/tools.dart';
import 'package:jangan_bangunin_angsa_app/game/tuning.dart';

import 'fixtures.dart';

const _night3Goals = [
  {'style': 'ghost', 'kind': 'neverSuspicious'},
  {'style': 'trickster', 'kind': 'lure', 'count': 2},
  {'style': 'chaos', 'kind': 'chain', 'count': 5},
];

/// A chimer far out of her ear zone: every ring lures her out of bed.
Level _lureLevel() => Level.parse(minimalLevel(
  spots: [{'id': 'a', 'x': 10}],
  objects: [{'id': 'clock', 'type': 'chimer', 'spot': 'a'}],
  goals: _night3Goals,
));

/// Rings the chimer and waits until she is out of bed.
void _lure(NightSim s) {
  s.poke('a');
  tickUntil(s, () => s.goose.state == GooseState.sleepwalk);
}

bool _wokeUp(List<SimEvent> events) =>
    events.any((e) => e is GooseChanged && e.to == GooseState.awake);

void main() {
  test('Trickster: lure her with the glass, take the egg, walk out', () {
    final s = NightSim(night3())..setSneak(true);
    expect(s.throwSock(62), isTrue);
    s.tick(1);
    expect(s.goose.state, GooseState.sleepwalk);
    walkTo(s, 561);
    expect(s.grab('egg'), isTrue);
    walkTo(s, 770);
    expect(s.outcome, Outcome.escaped);
    expect(s.carried, contains('egg'));
    expect(_wokeUp(s.takeEvents()), isFalse);
  });

  test('Ghost: grab the egg during the roll-over window, never wake her', () {
    final s = NightSim(night3())..setSneak(true);
    walkTo(s, 561);
    expect(s.goose.rollingOver, isFalse);
    tickUntil(s, () => s.goose.rollingOver);
    expect(s.grab('egg'), isTrue);
    walkTo(s, 770);
    expect(s.outcome, Outcome.escaped);
    final events = s.takeEvents();
    expect(_wokeUp(events), isFalse);
    expect(events.whereType<NoiseMade>(), isEmpty);
  });

  test('Chaos: robot into the clock wakes her, grab the egg, run out over the plank', () {
    final s = NightSim(night3())..setSneak(true);
    walkTo(s, 614);
    s.poke('sideTable'); // wind the robot
    walkTo(s, 561);
    tickUntil(s, () => s.goose.state == GooseState.awake);
    expect(s.grab('egg'), isTrue);
    s.setSneak(false);
    walkTo(s, 770);
    expect(s.outcome, Outcome.escaped);
    expect(s.carried, contains('egg'));
    final noises = s.takeEvents().whereType<NoiseMade>();
    expect(noises.where((n) => n.link?.objectId == 'plank'), isNotEmpty);
  });

  test('grabbing the egg while she sleeps wakes her', () {
    final s = NightSim(night3())..setSneak(true);
    walkTo(s, 561);
    expect(s.goose.rollingOver, isFalse);
    expect(s.grab('egg'), isFalse);
    expect(s.carried, isEmpty);
    expect(s.goose.state, GooseState.awake);
    expect(s.goose.wakeCause, WakeCause.grabbedGuarded);
  });

  test('grab needs the burglar within reach of the loot', () {
    final s = NightSim(night3());
    expect(s.grab('chicken'), isFalse); // 236 → 353
    expect(s.grab('toaster'), isTrue); // 236 → 218
    expect(s.grab('toaster'), isFalse); // already carried
  });

  test('caught: chase reaches the burglar, outcome after 1.2s', () {
    final s = NightSim(night3());
    s.poke('sideTable');
    tickUntil(s, () => s.takeEvents().any((e) => e is CaughtStarted));
    s.tick(1.1);
    expect(s.outcome, isNull);
    s.tick(0.15);
    expect(s.outcome, Outcome.caught);
    expect(s.wakeChain.map((f) => f.objectId), ['robot', 'clock']);
  });

  test('a hidden burglar is not caught', () {
    final s = NightSim(night3())..setSneak(true);
    walkTo(s, 720);
    expect(s.toggleHide(), isTrue);
    expect(s.hidden, isTrue);
    s.poke('sideTable');
    s.tick(6);
    expect(s.outcome, isNull);
    expect(s.goose.state, GooseState.lostYou);
  });

  test('a hidden burglar is not caught even when she walks right up to them', () {
    final s = NightSim(night3())..setSneak(true);
    walkTo(s, 660); // sneak past the plank
    s.setSneak(false);
    walkTo(s, 720); // at a walk: the last noise she heard is a footstep by the coat rack
    expect(s.toggleHide(), isTrue);
    s.goose.wake(WakeCause.noise);
    var closest = double.infinity;
    for (var i = 0; i < 60 * 4; i++) {
      s.tick(frame);
      final d = (s.goose.x - s.playerX).abs();
      if (d < closest) closest = d;
    }
    expect(closest, lessThanOrEqualTo(const Tuning().caughtDistance));
    expect(s.takeEvents().whereType<CaughtStarted>(), isEmpty);
    expect(s.outcome, isNull);
  });

  test('a later wake that no chain caused clears the old wake chain', () {
    final s = NightSim(night3())..setSneak(true);
    walkTo(s, 720);
    s.toggleHide();
    s.poke('sideTable');
    tickUntil(s, () => s.goose.state == GooseState.lostYou);
    tickUntil(s, () => s.goose.inBed);
    expect(s.wakeChain, isNotEmpty);
    s.toggleHide();
    walkTo(s, 561);
    tickUntil(s, () => !s.goose.rollingOver);
    expect(s.grab('egg'), isFalse);
    expect(s.goose.wakeCause, WakeCause.grabbedGuarded);
    expect(s.wakeChain, isEmpty);
  });

  test('a patrolling goose that runs into the burglar chases again', () {
    final s = NightSim(night3())..setSneak(true);
    walkTo(s, 720);
    s.toggleHide();
    s.poke('sideTable');
    tickUntil(s, () => s.goose.state == GooseState.lostYou);
    s
      ..toggleHide()
      ..setSneak(false)
      ..setMove(-1); // straight into her as she walks back to bed
    tickUntil(s, () => s.outcome != null, limit: 10);
    expect(s.outcome, Outcome.caught);
  });

  test('the egg stays guarded while she patrols at her bed', () {
    final s = NightSim(night3())..setSneak(true);
    walkTo(s, 720);
    s.toggleHide();
    s.poke('sideTable');
    tickUntil(s, () => s.goose.state == GooseState.lostYou);
    s.toggleHide();
    walkTo(s, 561);
    tickUntil(s, () => s.goose.x == 502);
    expect(s.goose.state, GooseState.lostYou);
    expect(s.grab('egg'), isFalse);
    expect(s.goose.isAwake, isTrue);
  });

  test('the walls stop the burglar', () {
    final s = NightSim(night3())..setMove(-1);
    s.tick(10);
    expect(s.playerX, const Tuning().bodyWidth / 2);
    expect(s.playerY, 270);
    s
      ..setSneak(true)
      ..setMove(1)
      ..tick(20);
    expect(s.outcome, Outcome.escaped);
  });

  test('caught mid-jump, he still comes down', () {
    final s = NightSim(night3())..setSneak(true);
    walkTo(s, 300);
    s.goose.wake(WakeCause.noise);
    tickUntil(s, () => (s.goose.x - s.playerX).abs() <= 30, limit: 15);
    s.jump();
    tickUntil(s, () => s.takeEvents().whereType<CaughtStarted>().isNotEmpty, limit: 2);
    expect(s.grounded, isFalse);
    s.tick(1);
    expect(s.playerY, 270);
  });

  test('hiding needs a hide spot in reach, and holds the burglar still', () {
    final s = NightSim(night3());
    expect(s.toggleHide(), isFalse); // 236, hide spots at 148 and 703
    walkTo(s, 170);
    expect(s.toggleHide(), isTrue);
    s.setMove(1);
    s.tick(1);
    expect(s.playerX, closeTo(170, 2));
    expect(s.toggleHide(), isTrue); // step out
    expect(s.hidden, isFalse);
  });

  test('one big tick equals many small ticks', () {
    final a = NightSim(night3())..poke('sideTable');
    a.tick(3.0);
    final b = NightSim(night3())..poke('sideTable');
    for (var i = 0; i < 300; i++) {
      b.tick(0.01);
    }
    expect(a.goose.state, b.goose.state);
    expect(a.goose.state, GooseState.chase);
    expect(a.takeEvents().map((e) => e.runtimeType), b.takeEvents().map((e) => e.runtimeType));
  });

  test('walking makes footsteps, sneaking does not', () {
    final walker = NightSim(night3())..setMove(1);
    walker.tick(1);
    expect(walker.goose.meter.value, greaterThan(0));

    final sneaker = NightSim(night3())
      ..setSneak(true)
      ..setMove(1);
    sneaker.tick(2);
    expect(sneaker.goose.meter.value, 0);
    expect(sneaker.takeEvents().whereType<NoiseMade>(), isEmpty);
  });

  test('walking over the plank sets it off; sneaking skips it', () {
    final sneaker = NightSim(night3())..setSneak(true);
    walkTo(sneaker, 660);
    expect(sneaker.takeEvents().whereType<NoiseMade>(), isEmpty);

    final walker = NightSim(night3())..setSneak(true);
    walkTo(walker, 630);
    walker.setSneak(false);
    walkTo(walker, 650);
    final plank = walker.takeEvents().whereType<NoiseMade>().where((n) => n.link != null);
    expect(plank.single.link!.objectId, 'plank');
  });

  test('carrying the squeaky chicken at a walk squeaks', () {
    final s = NightSim(night3())..setSneak(true);
    climbTo(s, 'crawlPlank', viaShelves: true);
    walkTo(s, 353);
    expect(s.grab('chicken'), isTrue);
    walkTo(s, 350);
    pushDown(s);
    pushDown(s);
    pushDown(s);
    expect(s.onFloor, isTrue);
    s.takeEvents();
    s
      ..setSneak(false)
      ..setMove(-1);
    s.tick(1);
    final squeaks = s.takeEvents().whereType<NoiseMade>().where((n) => n.noise.loudness == 1);
    expect(squeaks, isNotEmpty);
  });

  test('nothing moves once the night is over', () {
    final s = NightSim(night3())..setSneak(true);
    walkTo(s, 770);
    expect(s.outcome, Outcome.escaped);
    final x = s.playerX;
    s
      ..setMove(-1)
      ..tick(1);
    expect(s.playerX, x);
    expect(s.grab('egg'), isFalse);
  });

  group('interaction', () {
    test('offers the toaster at the start', () {
      final i = NightSim(night3()).interaction;
      expect(i, isA<GrabLoot>().having((g) => g.loot.id, 'loot', 'toaster'));
    });

    test('winds the robot in reach', () {
      final s = NightSim(night3())..setSneak(true);
      walkTo(s, 614);
      expect(
        s.interaction,
        isA<Wind>().having((w) => w.spotId, 'spot', 'sideTable').having((w) => w.objectId, 'object', 'robot'),
      );
    });

    test('a glass in reach offers nothing: throw at it instead', () {
      final s = NightSim(night3());
      walkTo(s, 62);
      expect(s.interaction, isNull);
    });

    test('a spent robot is no longer offered', () {
      final s = NightSim(night3())..setSneak(true);
      walkTo(s, 614);
      expect(s.interact(), isA<Wind>());
      s.tick(0.1);
      expect(s.chain.isSpent('robot'), isTrue);
      expect(s.interaction, isNull);
    });

    test('only coming out while hidden', () {
      final s = NightSim(night3());
      walkTo(s, 170);
      expect(s.toggleHide(), isTrue);
      expect(s.interaction, isA<Unhide>());
      expect(s.interact(), isA<Unhide>());
      expect(s.hidden, isFalse);
    });

    test('interact grabs and returns what it did', () {
      final s = NightSim(night3());
      expect(s.interact(), isA<GrabLoot>());
      expect(s.carried, ['toaster']);
    });
  });

  group('throw', () {
    List<NoiseMade> flops(List<SimEvent> events) =>
        events.whereType<NoiseMade>().where((n) => n.tool == Tool.socks).toList();

    test('a sock leaves from his hand, up on the plank too', () {
      final s = NightSim(night3())..setSneak(true);
      climbTo(s, 'crawlPlank');
      expect(s.throwSock(500), isTrue);
      expect(s.flights.single.fromY, 106 - 58);
      pushDown(s); // down again mid-flight
      expect(s.flights.single.fromY, 106 - 58);
    });

    test('a sock thrown from the floor leaves at hand height', () {
      final s = NightSim(night3());
      expect(s.throwSock(62), isTrue);
      expect(s.flights.single.fromY, 212);
    });

    test('a sock at the glass starts a chain when it lands', () {
      final s = NightSim(night3());
      expect(s.throwSock(62), isTrue);
      expect(s.toolLeft, 2);
      expect(s.flights, hasLength(1));
      s.tick(0.49);
      expect(s.chain.isSpent('glass'), isFalse);
      s.tick(0.02);
      expect(s.chain.isSpent('glass'), isTrue);
      expect(s.flights, isEmpty);
      expect(flops(s.takeEvents()), isEmpty);
    });

    test('the landing is clamped to the throw range and the room', () {
      final s = NightSim(night3())..setSneak(true);
      walkTo(s, 600);
      expect(s.throwLanding(0), 240);
      expect(s.throwLanding(2000), 844);
      expect(NightSim(night3()).throwLanding(-500), 0);
    });

    test('targets the nearest live object within 24px', () {
      final s = NightSim(night3());
      expect(s.throwTarget(70), 'counterLeft');
      expect(s.throwTarget(100), 'counterPot');
      expect(s.throwTarget(250), isNull);
      expect(s.throwTarget(640), isNull); // the plank is stepped on, not hit
    });

    test('a miss flops softly where it lands', () {
      final s = NightSim(night3());
      s.throwSock(250);
      s.tick(0.6);
      final flop = flops(s.takeEvents()).single;
      expect(flop.noise.x, 250);
      expect(flop.noise.loudness, 0);
      expect(flop.link, isNull);
    });

    test('a target knocked down mid-flight makes the sock flop', () {
      final s = NightSim(night3());
      s.throwSock(62);
      s.poke('counterLeft');
      s.tick(0.6);
      final events = s.takeEvents();
      expect(events.whereType<NoiseMade>().where((n) => n.link?.objectId == 'glass'), hasLength(1));
      expect(flops(events).single.noise.x, 62);
    });

    test('three socks, then none', () {
      final s = NightSim(night3());
      for (var i = 0; i < 3; i++) {
        expect(s.throwSock(62), isTrue);
      }
      expect(s.throwSock(62), isFalse);
      expect(s.toolLeft, 0);
    });

    test('no throwing while hidden', () {
      final s = NightSim(night3());
      walkTo(s, 170);
      s.toggleHide();
      expect(s.throwSock(62), isFalse);
      expect(s.toolLeft, 3);
    });

    test('no throwing once caught', () {
      final s = NightSim(night3());
      s.poke('sideTable');
      tickUntil(s, () => s.takeEvents().any((e) => e is CaughtStarted));
      expect(s.throwSock(62), isFalse);
    });

    test('only with socks', () {
      final s = NightSim(night3(), setup: const NightSetup(tool: Tool.mouse));
      expect(s.toolLeft, 1);
      expect(s.throwSock(62), isFalse);
    });
  });

  group('mouse', () {
    NightSim mouseAt(double x, {double facing = 1}) {
      final s = NightSim(night3(), setup: const NightSetup(tool: Tool.mouse))..setSneak(true);
      walkTo(s, x);
      s
        ..setMove(facing)
        ..setMove(0);
      return s;
    }

    test('facing left it walks into the pot: CLANG lures her', () {
      final s = mouseAt(236, facing: -1);
      expect(s.useTool(), isTrue);
      expect(s.toolLeft, 0);
      tickUntil(s, () => s.goose.state == GooseState.sleepwalk);
      expect(s.mouse!.stopped, isTrue);
      expect(s.mouse!.x, 113);
    });

    test('facing right it knocks the books off', () {
      final s = mouseAt(236);
      s.useTool();
      tickUntil(s, () => s.chain.isSpent('books'));
      expect(s.mouse!.x, 340);
    });

    test('it leaves alone what it was set down on', () {
      final s = NightSim(
        Level.parse(minimalLevel(
          spots: [{'id': 'a', 'x': 0}, {'id': 'b', 'x': 100}],
          objects: [{'id': 'o', 'type': 'tipper', 'spot': 'a'}, {'id': 'o2', 'type': 'tipper', 'spot': 'b'}],
        )),
        setup: const NightSetup(tool: Tool.mouse),
      );
      s.useTool();
      tickUntil(s, () => s.chain.isSpent('o2'));
      expect(s.chain.isSpent('o'), isFalse);
    });

    test('it steps on the plank', () {
      final s = mouseAt(625);
      s.useTool();
      tickUntil(s, () => s.mouse!.stopped);
      expect(s.mouse!.x, 640);
      expect(s.takeEvents().whereType<NoiseMade>().any((n) => n.link?.objectId == 'plank'), isTrue);
    });

    test('it stops at the wall', () {
      final s = NightSim(Level.parse(minimalLevel(spots: [{'id': 'a', 'x': 0}])), setup: const NightSetup(tool: Tool.mouse));
      s.useTool();
      tickUntil(s, () => s.mouse!.stopped, limit: 15);
      expect(s.mouse!.x, 844);
    });

    test('one mouse per night', () {
      final s = NightSim(night3(), setup: const NightSetup(tool: Tool.mouse));
      expect(s.useTool(), isTrue);
      expect(s.useTool(), isFalse);
      expect(s.toolReady, isFalse);
    });
  });

  group('marbles', () {
    test('not while she sleeps', () {
      final s = NightSim(night3(), setup: const NightSetup(tool: Tool.marbles));
      expect(s.toolReady, isFalse);
      expect(s.useTool(), isFalse);
      expect(s.toolLeft, 1);
    });

    test('spilled behind Milo, she slips on them', () {
      final s = NightSim(night3(), setup: const NightSetup(tool: Tool.marbles))..setSneak(true);
      walkTo(s, 561);
      tickUntil(s, () => !s.goose.rollingOver);
      s.grab('egg');
      expect(s.goose.isAwake, isTrue);
      s.setSneak(false);
      walkTo(s, 621);
      expect(s.toolReady, isTrue);
      expect(s.useTool(), isTrue);
      expect(s.spillX, closeTo(s.playerX - 24, 0.01));
      tickUntil(s, () => s.goose.slipping, limit: 3);
      expect(s.takeEvents().whereType<GooseSlipped>(), hasLength(1));
      expect(s.spillX, isNull);
      expect(s.outcome, isNull);
    });
  });

  test('a distracted goose slips on the marbles too', () {
    // She wakes at 400 with Milo at 500; a two-link chain at 700–760 pulls
    // her right across the marbles he spilled behind him at 476.
    final level = Level.fromJson({
      ...jsonDecode(minimalLevel(
        spots: [{'id': 'a', 'x': 700}, {'id': 'b', 'x': 760}],
        objects: [{'id': 'o', 'type': 'tipper', 'spot': 'a'}, {'id': 'o2', 'type': 'tipper', 'spot': 'b'}],
        links: [{'from': 'a', 'to': 'b'}],
      )) as Map<String, Object?>,
      'playerStart': [500, 270],
    });
    final s = NightSim(level, setup: const NightSetup(tool: Tool.marbles));
    s.goose.wake(WakeCause.noise);
    expect(s.useTool(), isTrue);
    expect(s.spillX, 476);
    s.poke('a');
    tickUntil(s, () => s.goose.state == GooseState.distracted, limit: 1);
    tickUntil(s, () => s.goose.slipping, limit: 2);
    expect(s.spillX, isNull);
  });

  group('kazoo', () {
    test('a far toot moves her', () {
      final s = NightSim(night3(), setup: const NightSetup(tool: Tool.kazoo))..setSneak(true);
      walkTo(s, 62);
      s.takeEvents();
      expect(s.useTool(), isTrue);
      final toot = s.takeEvents().whereType<NoiseMade>().single;
      expect(toot.tool, Tool.kazoo);
      expect(toot.noise.loudness, 3);
      expect(toot.noise.x, 62);
      expect(s.goose.state, GooseState.sleepwalk);
    });

    test('a close toot wakes her', () {
      final s = NightSim(night3(), setup: const NightSetup(tool: Tool.kazoo));
      s.useTool();
      expect(s.goose.isAwake, isTrue);
    });

    test("a toot that wakes her is the tool's fault", () {
      final s = NightSim(night3(), setup: const NightSetup(tool: Tool.kazoo));
      s.useTool();
      expect(s.goose.wakeCause, WakeCause.tool);
      tickUntil(s, () => s.outcome != null);
      expect(s.result!.wakeCause, WakeCause.tool);
      expect(s.result!.wakeChain, isEmpty);
    });

    test('one toot per night', () {
      final s = NightSim(night3(), setup: const NightSetup(tool: Tool.kazoo));
      s.useTool();
      expect(s.useTool(), isFalse);
    });
  });

  test('socks are thrown, not used with a tap', () {
    expect(NightSim(night3()).useTool(), isFalse);
  });

  test('facing follows the last move', () {
    final s = NightSim(night3());
    expect(s.facing, 1);
    s.setMove(-0.5);
    expect(s.facing, -1);
    s.setMove(0);
    expect(s.facing, -1);
  });

  group('result', () {
    test('null until the night ends', () {
      final s = NightSim(night3());
      s.tick(1);
      expect(s.result, isNull);
    });

    test('escape carries loot and time', () {
      final s = NightSim(night3())..setSneak(true);
      s.interact();
      walkTo(s, 770);
      final r = s.result!;
      expect(r.outcome, Outcome.escaped);
      expect(r.loot, ['toaster']);
      expect(r.time, s.elapsed);
      expect(r.time, greaterThan(0));
      expect(r.level.id, 'night3');
      expect(r.tool, Tool.socks);
    });

    test('carries the tool', () {
      final s = NightSim(night3(), setup: const NightSetup(tool: Tool.mouse))..setSneak(true);
      walkTo(s, 770);
      expect(s.result!.tool, Tool.mouse);
    });

    test('caught carries the wake chain and cause', () {
      final s = NightSim(night3());
      s.poke('sideTable');
      tickUntil(s, () => s.outcome != null);
      final r = s.result!;
      expect(r.outcome, Outcome.caught);
      expect(r.wakeChain.map((f) => f.objectId), ['robot', 'clock']);
      expect(r.wakeCause, WakeCause.noise);
    });

    test('elapsed stops at the outcome', () {
      final s = NightSim(night3())..setSneak(true);
      walkTo(s, 770);
      final t = s.elapsed;
      s.tick(5);
      expect(s.elapsed, t);
    });
  });

  group('rearrange', () {
    NightSim holdingPot() {
      final s = NightSim(night3())..setSneak(true);
      walkTo(s, 113);
      s.interact();
      return s;
    }

    test('Interact lifts the pot', () {
      final s = NightSim(night3())..setSneak(true);
      walkTo(s, 113);
      final i = s.interaction;
      expect(i, isA<MoveObject>());
      expect((i as MoveObject).spotId, 'counterPot');
      expect(i.objectId, 'pot');
      s.interact();
      expect(s.held, 'pot');
      expect(s.chain.objectAt('counterPot'), isNull);
    });

    test('holding the pot, Interact puts it on a free snap spot in reach', () {
      final s = holdingPot();
      walkTo(s, 250);
      expect(s.interaction, isNull);
      walkTo(s, 372);
      final i = s.interaction;
      expect(i, isA<PlaceObject>());
      expect((i as PlaceObject).spotId, 'underShelf');
      s.interact();
      expect(s.held, isNull);
      expect(s.chain.spotOf('pot'), 'underShelf');
    });

    test('the pot back on the counter is a snap spot too', () {
      final s = holdingPot();
      expect((s.interaction as PlaceObject).spotId, 'counterPot');
      expect(s.place('counterPot'), isTrue);
      expect(s.chain.spotOf('pot'), 'counterPot');
    });

    test('the pot under the shelf makes a new chain', () {
      final s = holdingPot();
      walkTo(s, 372);
      s.interact();
      s.takeEvents();
      expect(s.throwSock(340), isTrue);
      s.tick(2);
      final links = s.takeEvents().whereType<NoiseMade>().map((n) => n.link?.objectId).nonNulls;
      expect(links, ['books', 'pot']);
    });

    test('hands full: no grab, no tool, no hiding', () {
      final s = holdingPot();
      walkTo(s, 218);
      expect(s.interaction, isNull);
      expect(s.grab('toaster'), isFalse);
      expect(s.toolReady, isFalse);
      expect(s.throwSock(62), isFalse);
      walkTo(s, 148);
      expect(s.toggleHide(), isFalse);
      expect(s.hidden, isFalse);
    });

    test('escaping while holding', () {
      final s = holdingPot();
      walkTo(s, 770);
      expect(s.outcome, Outcome.escaped);
      expect(s.result, isNotNull);
    });

    test('caught while holding', () {
      final s = holdingPot();
      s.goose.wake(WakeCause.noise);
      tickUntil(s, () => s.outcome != null, limit: 20);
      expect(s.outcome, Outcome.caught);
      expect(s.result, isNotNull);
    });
  });

  group('hide through Interact', () {
    test('Interact hides and comes out', () {
      final s = NightSim(night3())..setSneak(true);
      walkTo(s, 148);
      expect(s.interaction, isA<Hide>());
      s.interact();
      expect(s.hidden, isTrue);
      expect(s.interaction, isA<Unhide>());
      s.interact();
      expect(s.hidden, isFalse);
    });

    test('moving beats hiding', () {
      final s = NightSim(night3())..setSneak(true);
      walkTo(s, 135); // pot 22 away, the cabinet only 13
      expect(s.interaction, isA<MoveObject>());
    });
  });

  group('body', () {
    NightSim plankAt(double x, {Tool tool = Tool.socks}) {
      final s = NightSim(night3(), setup: NightSetup(tool: tool))..setSneak(true);
      climbTo(s, 'crawlPlank');
      walkTo(s, x);
      return s;
    }

    Iterable<NoiseMade> heard(NightSim s) => s.takeEvents().whereType<NoiseMade>().where((n) => n.touchedEar);

    test('up by the counter onto the crawl plank, crawling', () {
      final s = plankAt(300);
      expect(s.crawling, isTrue);
      expect(s.playerY, 106);
      final from = s.playerX;
      s.setMove(1);
      s.tick(1);
      expect(s.playerX, closeTo(from + const Tuning().crawlSpeed, 2));
    });

    test('up the shelves with Sneak, unheard', () {
      final s = NightSim(night3())..setSneak(true);
      walkTo(s, 350);
      s.takeEvents();
      climbTo(s, 'crawlPlank', viaShelves: true);
      expect(s.crawling, isTrue);
      expect(heard(s), isEmpty);
    });

    test('down the shelves with Sneak, unheard', () {
      final s = NightSim(night3())..setSneak(true);
      climbTo(s, 'crawlPlank', viaShelves: true);
      s.takeEvents();
      pushDown(s);
      expect(s.standingOn?.id, 'shelfHigh');
      pushDown(s);
      expect(s.standingOn?.id, 'shelfLow');
      pushDown(s);
      expect(s.onFloor, isTrue);
      expect(heard(s), isEmpty);
    });

    test('dropping off the bare end of the plank thumps in her ears', () {
      final s = plankAt(410)..setSneak(false);
      s.takeEvents();
      pushDown(s);
      expect(s.onFloor, isTrue);
      final thump = heard(s).single;
      expect(thump.noise.loudness, 2);
      expect(thump.noise.y, 270);
    });

    test('crawling is silent', () {
      final s = plankAt(300)
        ..setSneak(false)
        ..takeEvents()
        ..setMove(1);
      s.tick(1);
      expect(s.takeEvents().whereType<NoiseMade>(), isEmpty);
    });

    test('the chicken is reachable from the plank and the top shelf, not lower', () {
      final floor = NightSim(night3())..setSneak(true);
      walkTo(floor, 353);
      expect(floor.interaction, isNot(isA<GrabLoot>()));
      expect(floor.grab('chicken'), isFalse);
      final counter = NightSim(night3())..setSneak(true);
      climbTo(counter, 'counter');
      walkTo(counter, 278);
      expect(counter.grab('chicken'), isFalse);
      final shelf = NightSim(night3())..setSneak(true);
      climbTo(shelf, 'shelfHigh');
      expect((shelf.interaction as GrabLoot).loot.id, 'chicken');
      final s = plankAt(353);
      expect((s.interaction as GrabLoot).loot.id, 'chicken');
      expect(s.grab('chicken'), isTrue);
    });

    test('floor loot is out of reach from a high top', () {
      final s = NightSim(Level.parse(minimalLevel(
        platforms: [{'id': 'shelf', 'x': [0, 100], 'y': 106, 'surface': 'wood'}],
        loot: [{'id': 'cup', 'x': 20}],
        extra: {'playerStart': [20, 106]},
      )));
      expect(s.interaction, isNull);
      expect(s.grab('cup'), isFalse);
    });

    test('she cannot catch him on the plank', () {
      final s = plankAt(380);
      s.goose.wake(WakeCause.noise);
      s.tick(6);
      expect(s.outcome, isNull);
      expect(s.goose.state, GooseState.lostYou);
    });

    test('on the counter he is in her reach', () {
      final s = NightSim(night3())..setSneak(true);
      climbTo(s, 'counter');
      walkTo(s, 270);
      s.goose.hear(const Noise(x: 270, loudness: 3));
      tickUntil(s, () => s.outcome != null, limit: 15);
      expect(s.outcome, Outcome.caught);
    });

    test('her neck reaches 80 px up', () {
      NightSim standingAt(double y) {
        final s = NightSim(Level.parse(minimalLevel(
          platforms: [{'id': 'top', 'x': [300, 500], 'y': y, 'surface': 'wood'}],
          extra: {'playerStart': [420, y]},
        )));
        s.goose.wake(WakeCause.noise);
        tickUntil(s, () => s.outcome != null || s.goose.state == GooseState.lostYou, limit: 15);
        return s;
      }

      expect(standingAt(270 - 75).outcome, Outcome.caught);
      expect(standingAt(270 - 85).outcome, isNull);
    });

    test('dropping down next to her gets you caught', () {
      final s = plankAt(410);
      s.goose.hear(const Noise(x: 410, loudness: 3));
      tickUntil(s, () => (s.goose.x - s.playerX).abs() <= 30, limit: 10);
      pushDown(s);
      tickUntil(s, () => s.outcome != null, limit: 5);
      expect(s.outcome, Outcome.caught);
    });

    test('tools on the plank: no mouse, no marbles, socks fly', () {
      expect(plankAt(300, tool: Tool.mouse).toolReady, isFalse);
      final marbles = plankAt(300, tool: Tool.marbles);
      marbles.goose.wake(WakeCause.noise);
      expect(marbles.toolReady, isFalse);
      expect(plankAt(300).throwSock(62), isTrue);
    });

    test('no jumping or climbing with the pot, but he can still fall with it', () {
      final s = NightSim(night3())..setSneak(true);
      walkTo(s, 113);
      expect(s.interact(), isA<MoveObject>());
      expect(s.jumpReady, isFalse);
      expect(s.canMantle, isFalse);
      s.jump();
      s.setVertical(-1);
      s.tick(1);
      expect(s.playerY, 270);

      final c = NightSim(night3())..setSneak(true);
      climbTo(c, 'counter');
      walkTo(c, 113);
      expect(c.lift('pot'), isTrue);
      c.takeEvents();
      walkTo(c, 279);
      c.setMove(1);
      tickUntil(c, () => c.onFloor, limit: 2);
      expect(c.held, 'pot');
      expect(c.takeEvents().whereType<NoiseMade>().where((n) => n.noise.loudness >= 1), isNotEmpty);
    });

    test('a jump on the wood floor lands with a small noise; with Sneak, none', () {
      NightSim jumpAt700({required bool sneak}) {
        final s = NightSim(night3())..setSneak(true);
        walkTo(s, 700);
        s
          ..setSneak(sneak)
          ..takeEvents()
          ..jump();
        tickUntil(s, () => s.playerY < 270, limit: 1);
        tickUntil(s, () => s.grounded, limit: 2);
        return s;
      }

      final loud = jumpAt700(sneak: false).takeEvents().whereType<NoiseMade>().single;
      expect(loud.noise.loudness, 1);
      expect(jumpAt700(sneak: true).takeEvents().whereType<NoiseMade>(), isEmpty);
    });

    test('jumping over the loose plank does not step on it', () {
      final s = NightSim(night3())..setSneak(true);
      walkTo(s, 600);
      s
        ..setSneak(false)
        ..takeEvents()
        ..setMove(1)
        ..jump();
      tickUntil(s, () => s.playerY < 270, limit: 1);
      tickUntil(s, () => s.grounded, limit: 2);
      s.setMove(0);
      expect(s.playerX, greaterThan(640));
      expect(s.takeEvents().whereType<NoiseMade>().where((n) => n.link?.objectId == 'plank'), isEmpty);
    });

    test('hiding is only from the floor', () {
      final s = NightSim(night3())..setSneak(true);
      climbTo(s, 'counter');
      walkTo(s, 148);
      expect(s.interaction, isNot(isA<Hide>()));
      expect(s.toggleHide(), isFalse);
    });

    test('no hiding halfway up a mantle', () {
      final s = NightSim(night3())..setSneak(true);
      walkTo(s, 148);
      s
        ..setVertical(-1)
        ..tick(frame);
      expect(s.mantling, isTrue);
      expect(s.interaction, isNull);
      expect(s.toggleHide(), isFalse);
    });

    test('up and down do nothing while hidden', () {
      final s = NightSim(night3())..setSneak(true);
      walkTo(s, 148);
      expect(s.toggleHide(), isTrue);
      expect(s.canMantle, isFalse);
      s.setVertical(-1);
      s.tick(1);
      expect(s.playerY, 270);
    });
  });

  group('heist', () {
    test('the first stir of the night counts as seen', () {
      final s = NightSim(night3());
      s.goose
        ..hear(const Noise(x: 480, loudness: 1))
        ..hear(const Noise(x: 480, loudness: 1));
      s.tick(frame);
      expect(s.seen, isTrue);
      expect(s.takeEvents().whereType<GooseChanged>().single.to, GooseState.suspicious);
    });

    test('the result says whether she was seen', () {
      final quiet = NightSim(night3())..setSneak(true);
      walkTo(quiet, night3().exitX);
      tickUntil(quiet, () => quiet.result != null);
      expect(quiet.result!.seen, isFalse);

      final seen = NightSim(night3())..setSneak(true);
      seen.goose
        ..hear(const Noise(x: 480, loudness: 1))
        ..hear(const Noise(x: 480, loudness: 1));
      walkTo(seen, night3().exitX);
      tickUntil(seen, () => seen.result != null);
      expect(seen.result!.seen, isTrue);
    });

    test('fired links feed the combo', () {
      final s = NightSim(Level.parse(minimalLevel(
        spots: [{'id': 'a', 'x': 10}, {'id': 'b', 'x': 20}],
        objects: [{'id': 'o', 'type': 'tipper', 'spot': 'a'}, {'id': 'p', 'type': 'tipper', 'spot': 'b'}],
        links: [{'from': 'a', 'to': 'b'}],
      )));
      s.poke('a');
      s.tick(1);
      expect(s.combo.count, 2);
      expect(s.combo.best, 2);
      expect(s.comboLeft, closeTo(2.4, 0.05));
    });

    test('Night 3 can reach a 5-link combo', () {
      final s = NightSim(night3())..setSneak(true);
      walkTo(s, 600);
      s.setSneak(false);
      // Each crossing of the loose plank sets off plank → clock.
      walkTo(s, 650);
      walkTo(s, 630);
      walkTo(s, 650);
      walkTo(s, 703);
      expect(s.toggleHide(), isTrue);
      tickUntil(s, () => s.combo.best >= 5, limit: 6);
      expect(s.outcome, isNull);
    });

    test('luring counts sleepwalks', () {
      final s = NightSim(_lureLevel());
      _lure(s);
      expect(s.lures, 1);
      tickUntil(s, () => s.goose.inBed);
      _lure(s);
      expect(s.lures, 2);
      expect(s.met(const HeistGoal(style: PlayStyle.trickster, kind: GoalKind.lure, count: 2)), isTrue);
      expect(s.seen, isFalse);
      expect(s.woke, isFalse);
      expect(s.style, PlayStyle.trickster);
    });

    test('waking from a sleepwalk fails Ghost', () {
      final s = NightSim(_lureLevel());
      _lure(s);
      tickUntil(s, () => s.goose.sniffing);
      s.poke('a');
      tickUntil(s, () => s.goose.isAwake);
      expect(s.woke, isTrue);
      expect(s.seen, isTrue);
      expect(s.style, PlayStyle.chaos);
      expect(s.met(const HeistGoal(style: PlayStyle.ghost, kind: GoalKind.neverSuspicious)), isFalse);
    });

    test('caught nights meet no goals', () {
      final s = NightSim(_lureLevel());
      _lure(s);
      tickUntil(s, () => s.goose.inBed);
      _lure(s);
      tickUntil(s, () => s.goose.sniffing);
      s.poke('a');
      tickUntil(s, () => s.outcome != null);
      expect(s.outcome, Outcome.caught);
      expect(s.result!.goalsMet, isEmpty);
      expect(s.result!.lures, 2);
      expect(s.result!.score, s.combo.total);
    });

    test('walking out empty-handed meets no goals', () {
      final s = NightSim(night3())..setSneak(true);
      walkTo(s, 770);
      expect(s.outcome, Outcome.escaped);
      expect(s.result!.goalsMet, isEmpty);
      expect(s.result!.score, 0);
    });

    test('an escape scores loot, links and goals', () {
      final s = NightSim(Level.fromJson({
        ...jsonDecode(minimalLevel(loot: [{'id': 'cup', 'x': 20}], goals: _night3Goals)) as Map<String, Object?>,
        'exit': [50, 270],
      }));
      walkTo(s, 20);
      expect(s.grab('cup'), isTrue);
      walkTo(s, 50);
      final r = s.result!;
      expect(r.outcome, Outcome.escaped);
      expect(r.goalsMet, {PlayStyle.ghost});
      expect(r.style, PlayStyle.ghost);
      expect(r.score, 1000 + 1000);
      expect(r.bestChain, 0);
    });
  });

  test('a portable chimer waiting to ring is not offered to move', () {
    final s = NightSim(Level.parse(minimalLevel(
      spots: [{'id': 'a', 'x': 10, 'snap': true}],
      objects: [{'id': 'clock', 'type': 'chimer', 'spot': 'a', 'portable': true}],
    )));
    expect(s.interaction, isA<MoveObject>());
    s.poke('a');
    s.tick(0.1);
    expect(s.interaction, isNot(isA<MoveObject>()));
  });

  test('light sleeper hears everything louder', () {
    final light = NightSim(night3(), setup: const NightSetup(lightSleeper: true));
    light.goose.meter.hear(1);
    expect(light.goose.meter.value, 25 * const Tuning().lightSleeperGain);
    final normal = NightSim(night3())..goose.meter.hear(1);
    expect(normal.goose.meter.value, 25);
  });

  test('the result keeps the setup', () {
    const setup = NightSetup(tool: Tool.mouse, mirror: true, remixSeed: 7);
    final s = NightSim(night3(), setup: setup);
    s.setSneak(true);
    walkTo(s, night3().exitX);
    tickUntil(s, () => s.result != null);
    expect(s.result!.setup, setup);
    expect(s.result!.tool, Tool.mouse);
  });
}
