import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/goose_brain.dart';
import 'package:jangan_bangunin_angsa_app/game/night_sim.dart';
import 'package:jangan_bangunin_angsa_app/game/tuning.dart';

import 'fixtures.dart';

const _frame = 1 / 60;

/// Walks (or sneaks) the burglar until they reach [x], a frame at a time.
void walkTo(NightSim s, double x) {
  final right = x > s.playerX;
  s.setMove(right ? 1 : -1);
  for (var i = 0; i < 60 * 30 && s.outcome == null; i++) {
    if (right ? s.playerX >= x : s.playerX <= x) break;
    s.tick(_frame);
  }
  s.setMove(0);
}

/// Ticks frames until [done], failing the test after [limit] seconds.
void tickUntil(NightSim s, bool Function() done, {double limit = 30}) {
  for (var t = 0.0; !done(); t += _frame) {
    if (t > limit) fail('condition not met within ${limit}s');
    s.tick(_frame);
  }
}

bool _wokeUp(List<SimEvent> events) =>
    events.any((e) => e is GooseChanged && e.to == GooseState.awake);

void main() {
  test('Trickster: lure her with the glass, take the egg, walk out', () {
    final s = NightSim(night3())..setSneak(true);
    s.poke('counterLeft'); // stands in for the Phase 3 sock throw
    s.tick(0.5);
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
      s.tick(_frame);
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

  test('the burglar stays on the floor line', () {
    final s = NightSim(night3(), tuning: const Tuning(worldWidth: 500))..setMove(-1);
    s.tick(10);
    expect(s.playerX, 0);
    s
      ..setSneak(true)
      ..setMove(1)
      ..tick(20);
    expect(s.playerX, 500);
  });

  test('hiding needs a hide spot in reach, and holds the burglar still', () {
    final s = NightSim(night3());
    expect(s.toggleHide(), isFalse); // 236, hide spots at 180 and 720
    walkTo(s, 185);
    expect(s.toggleHide(), isTrue);
    s.setMove(1);
    s.tick(1);
    expect(s.playerX, closeTo(185, 2));
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
    walkTo(s, 353);
    expect(s.grab('chicken'), isTrue);
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
}
