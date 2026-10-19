import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/chain.dart';
import 'package:jangan_bangunin_angsa_app/game/level.dart';
import 'package:jangan_bangunin_angsa_app/game/tuning.dart';

import 'fixtures.dart';

void main() {
  late ChainRunner c;
  setUp(() => c = ChainRunner(night3(), const Tuning()));

  test('glass into pot: CLANG ×2 at 0.4s', () {
    c.poke('counterLeft');
    c.tick(0.01);
    final glass = c.takeFired().single;
    expect([glass.objectId, glass.link, glass.noise.loudness, glass.noise.x], ['glass', 1, 1, 62]);
    c.tick(0.38);
    expect(c.takeFired(), isEmpty);
    c.tick(0.03);
    final pot = c.takeFired().single;
    expect([pot.objectId, pot.link, pot.noise.loudness, pot.noise.x], ['pot', 2, 2, 113]);
    expect(pot.chainId, glass.chainId);
  });

  test('robot marches into the clock when no pot is under the table', () {
    c.poke('sideTable');
    c.tick(0.01);
    expect(c.takeFired().single.objectId, 'robot');
    c.tick(1.2);
    expect(c.takeFired(), isEmpty); // the clock is waiting its 1s
    c.tick(1.0);
    final clock = c.takeFired().single;
    expect([clock.objectId, clock.link, clock.noise.loudness], ['clock', 2, 3]);
  });

  test('robot drops into the pot once the pot is moved under the table', () {
    c.move('pot', 'underSideTable');
    expect(c.objectAt('underSideTable'), 'pot');
    expect(c.objectAt('counterPot'), isNull);
    c.poke('sideTable');
    c.tick(0.01);
    c.takeFired();
    c.tick(0.8);
    final pot = c.takeFired().single;
    expect([pot.objectId, pot.noise.x, pot.noise.loudness], ['pot', 596, 2]);
  });

  test('the glass falls on the floor once the pot is gone', () {
    c.move('pot', 'underShelf');
    c.poke('counterLeft');
    c.tick(5);
    expect(c.takeFired().map((f) => f.objectId), ['glass']);
  });

  test('move refuses fixed objects, plain spots and taken spots', () {
    expect(() => c.move('clock', 'underShelf'), throwsStateError);
    expect(() => c.move('pot', 'plank'), throwsStateError);
    c.move('pot', 'underShelf');
    expect(() => c.move('pot', 'underShelf'), returnsNormally);
  });

  test('a spent tipper ignores pokes', () {
    c.poke('counterLeft');
    c.tick(1);
    c.takeFired();
    expect(c.isSpent('glass'), isTrue);
    c.poke('counterLeft');
    c.tick(1);
    expect(c.takeFired(), isEmpty);
  });

  test('reusable objects fire again in a new chain', () {
    c.poke('plank');
    c.tick(3);
    c.takeFired();
    c.poke('plank');
    c.tick(3);
    expect(c.takeFired().map((f) => f.objectId), ['plank', 'clock']);
    expect(c.isSpent('plank'), isFalse);
  });

  test('poking an empty spot does nothing', () {
    c.poke('underShelf');
    c.tick(1);
    expect(c.takeFired(), isEmpty);
  });

  test('a cycle ends: each spot fires once per chain', () {
    final r = ChainRunner(Level.parse(_cycle), const Tuning())..poke('plank');
    for (var i = 0; i < 100; i++) {
      r.tick(0.1);
    }
    expect(r.takeFired().map((f) => f.spotId), ['plank', 'clockStand']);
  });

  test('two chains get separate ids, each starting at link 1', () {
    c.poke('counterLeft');
    c.poke('plank');
    c.tick(0.01);
    final fired = c.takeFired();
    expect(fired.map((f) => f.link), [1, 1]);
    expect(fired[0].chainId, isNot(fired[1].chainId));
  });

  test('one big tick fires links in time order', () {
    c.poke('sideTable');
    c.poke('counterLeft');
    c.tick(5);
    expect(c.takeFired().map((f) => f.objectId), ['robot', 'glass', 'pot', 'clock']);
  });

  test('a clock carried off while it waits still rings', () {
    final r = ChainRunner(Level.parse(_portableClock), const Tuning())..poke('plank');
    r.tick(0.9);
    r.move('clock', 'shelf');
    r.tick(2);
    expect(r.takeFired().map((f) => f.spotId), ['plank', 'shelf', 'tray']);
  });

  test('a clock moved while it waits rings where it now stands', () {
    final r = ChainRunner(Level.parse(_portableClock), const Tuning())..poke('plank');
    r.tick(0.9); // plank squeaked, the clock was hit at 0.4s and is waiting
    r
      ..move('clock', 'shelf')
      ..move('pot', 'stand');
    r.tick(2);
    expect(
      r.takeFired().map((f) => '${f.link} ${f.objectId}@${f.spotId}'),
      ['1 plank@plank', '2 clock@shelf', '3 tray@tray'],
    );
  });

  test('lift takes the pot off its spot', () {
    expect(c.lift('pot'), isTrue);
    expect(c.objectAt('counterPot'), isNull);
    expect(c.spotOf('pot'), isNull);
    expect(c.isHeld('pot'), isTrue);
    expect(c.lift('pot'), isFalse);
  });

  test('lift refuses what is not portable', () {
    expect(c.lift('glass'), isFalse);
    expect(c.objectAt('counterLeft'), 'glass');
  });

  test('a held object goes down on a snap spot and makes a new chain', () {
    c
      ..lift('pot')
      ..move('pot', 'underShelf');
    expect(c.spotOf('pot'), 'underShelf');
    expect(c.isHeld('pot'), isFalse);
    c.poke('shelfBooks');
    c.tick(1);
    final fired = c.takeFired();
    expect(fired.map((f) => f.objectId), ['books', 'pot']);
    expect(fired.last.noise.loudness, 2);
  });

  test('a hit on an emptied spot fizzles', () {
    c.poke('counterLeft');
    c.tick(0.1); // the glass fell; the pot is hit at 0.4s
    c.lift('pot');
    c.tick(1);
    expect(c.takeFired().map((f) => f.objectId), ['glass']);
  });

  test('a chimer waiting to ring cannot be lifted', () {
    final r = ChainRunner(Level.parse(_portableClock), const Tuning())..poke('plank');
    r.tick(0.9);
    expect(r.lift('clock'), isFalse);
    expect(r.isHeld('clock'), isFalse);
  });

  test('canLift refuses a chimer waiting to ring, then allows it', () {
    final level = Level.parse(minimalLevel(
      spots: [{'id': 'a', 'x': 10, 'snap': true}],
      objects: [{'id': 'clock', 'type': 'chimer', 'spot': 'a', 'portable': true}],
    ));
    final r = ChainRunner(level, const Tuning());
    expect(r.canLift('clock'), isTrue);
    r.poke('a');
    r.tick(0.1);
    expect(r.canLift('clock'), isFalse);
    r.tick(1);
    expect(r.canLift('clock'), isTrue);
    expect(r.isHeld('clock'), isFalse);
  });

}

final _portableClock = minimalLevel(
  spots: [
    {'id': 'plank', 'x': 640},
    {'id': 'stand', 'x': 667, 'snap': true},
    {'id': 'shelf', 'x': 100, 'snap': true},
    {'id': 'potHome', 'x': 300, 'snap': true},
    {'id': 'tray', 'x': 110},
  ],
  objects: [
    {'id': 'plank', 'type': 'squeaker', 'spot': 'plank'},
    {'id': 'clock', 'type': 'chimer', 'spot': 'stand', 'portable': true},
    {'id': 'pot', 'type': 'amplifier', 'spot': 'potHome', 'portable': true},
    {'id': 'tray', 'type': 'tipper', 'spot': 'tray'},
  ],
  links: [
    {'from': 'plank', 'to': 'stand'},
    {'from': 'stand', 'to': 'plank'},
    {'from': 'shelf', 'to': 'tray'},
  ],
);

final _cycle = minimalLevel(
  spots: [{'id': 'plank', 'x': 640}, {'id': 'clockStand', 'x': 667}],
  objects: [
    {'id': 'plank', 'type': 'squeaker', 'spot': 'plank'},
    {'id': 'clock', 'type': 'chimer', 'spot': 'clockStand'},
  ],
  links: [
    {'from': 'plank', 'to': 'clockStand'},
    {'from': 'clockStand', 'to': 'plank'},
  ],
);
