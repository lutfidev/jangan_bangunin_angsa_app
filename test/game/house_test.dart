import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/goose_brain.dart';
import 'package:jangan_bangunin_angsa_app/game/heist.dart';
import 'package:jangan_bangunin_angsa_app/game/level.dart';
import 'package:jangan_bangunin_angsa_app/game/modifiers.dart';
import 'package:jangan_bangunin_angsa_app/game/night_sim.dart';
import 'package:jangan_bangunin_angsa_app/game/remix.dart';

import 'fixtures.dart';

/// The house filled for a long night (langkah 10): its chains, its remix,
/// and a route that proves every loot and the exit can be reached.
void main() {
  NightSim inHouse({Level? level}) => NightSim(level ?? house(), setup: const NightSetup(night: 'house'))..setSneak(true);

  /// Every link fired until the chain goes quiet, as (object, floor line).
  List<(String, double)> chainFrom(NightSim s, String spotId) {
    s.poke(spotId);
    final fired = <(String, double)>[];
    for (var t = 0.0; t < 8; t += frame) {
      s.tick(frame);
      for (final e in s.takeEvents().whereType<NoiseMade>()) {
        if (e.link case final f?) fired.add((f.objectId, f.noise.y!));
      }
    }
    return fired;
  }

  group('chains between storeys', () {
    test('a plank on the landing sends the ball down the stair into the coal scuttle', () {
      expect(chainFrom(inHouse(), 'landingPlank'), [
        ('landingPlank', 270),
        ('ball', 270),
        ('scuttle', 660),
      ]);
    });

    test('a toilet flushed upstairs bangs the boiler in the basement', () {
      expect(chainFrom(inHouse(), 'tubEdge'), [('shampoo', 270), ('toilet', 270), ('boiler', 1050)]);
    });

    test('the scuttle clanging at the foot of the stair lures her out of bed, not awake', () {
      final s = inHouse();
      s.poke('landingPlank');
      tickUntil(s, () => s.goose.state == GooseState.sleepwalk, limit: 6);
      expect(s.goose.isAwake, isFalse);
    });

    test('in the bedroom, the perfume knocks the alarm clock off', () {
      expect(chainFrom(inHouse(), 'wardrobeTop').map((f) => f.$1), ['perfume', 'alarm']);
    });

    test('in the cellar and the hall the hammer and the umbrella fall into what is under them', () {
      expect(chainFrom(inHouse(), 'workbenchTop').map((f) => f.$1), ['hammer', 'bucket']);
      expect(chainFrom(inHouse(), 'umbrellaStand').map((f) => f.$1), ['umbrella', 'bin']);
    });
  });

  test('every remix of the house is a different, valid house', () {
    final level = house();
    final layouts = <String>{};
    for (var seed = 20261101; seed < 20261161; seed++) {
      final r = remixed(level, seed);
      final spots = [for (final o in r.objects) o.spot];
      expect(spots.toSet().length, spots.length, reason: 'two objects on one spot, seed $seed');
      for (final loot in r.loot) {
        expect(r.geometry.restsOnSurface(loot.at), isTrue, reason: '${loot.id}, seed $seed');
      }
      final layout = [for (final l in r.loot) '${l.id}@${l.at}', ...spots].join(' ');
      expect(layout, isNot([for (final l in level.loot) '${l.id}@${l.at}', for (final o in level.objects) o.spot].join(' ')));
      layouts.add(layout);
    }
    expect(layouts.length, greaterThan(30), reason: 'two months of nights should rarely repeat');
  });

  group('reachability', () {
    /// Down the flight whose head he stands at, moving [dir] along it.
    void downStairs(NightSim s, double dir) {
      s
        ..setVertical(1)
        ..tick(frame)
        ..setVertical(0);
      expect(s.onStairs, isTrue, reason: 'no stair head at ${s.playerX}, ${s.playerY}');
      s.setMove(dir);
      tickUntil(s, () => !s.onStairs, limit: 10);
      s.setMove(0);
    }

    /// Up the flight whose foot he stands at, moving [dir] along it.
    void upStairs(NightSim s, double dir) {
      s
        ..setVertical(-1)
        ..tick(frame)
        ..setVertical(0);
      expect(s.onStairs, isTrue, reason: 'no stair foot at ${s.playerX}, ${s.playerY}');
      s.setMove(dir);
      tickUntil(s, () => !s.onStairs, limit: 10);
      s.setMove(0);
    }

    void grab(NightSim s, String lootId) {
      expect(s.grab(lootId), isTrue, reason: '$lootId out of reach at ${s.playerX}, ${s.playerY}');
    }

    test('sneaking, he can take every loot she does not sleep on, reach the egg, and get out', () {
      final s = inHouse();
      final seen = <GooseState>{};
      void watch() => seen.add(s.goose.state);

      // Kitchen, up the duct to the bedroom: the toaster on the bed.
      walkTo(s, 300);
      expect(s.enterVent('bedroomDuct'), isTrue);
      tickUntil(s, () => !s.inVent);
      expect((s.playerX, s.playerY), (80, 270));
      walkTo(s, 300);
      grab(s, 'toaster');

      // Through the bedroom door and over the landing into the bathroom: the duck on the tub.
      walkTo(s, 1100);
      expect(s.useDoor('bedroomDoor'), isTrue);
      walkTo(s, 1600);
      expect(s.useDoor('bathroomDoor'), isTrue);
      walkTo(s, 1840);
      grab(s, 'duck');
      watch();

      // Down the living-room stair, past her bed, into the hall: the gnome on the table.
      walkTo(s, 1460);
      downStairs(s, -1);
      expect(s.playerY, 660);
      walkTo(s, 1722);
      grab(s, 'gnome');
      watch();

      // Down the hall stair to the boiler room, up the tank: the chicken on the pipe shelf.
      walkTo(s, 1620);
      downStairs(s, 1);
      expect(s.playerY, 1050);
      walkTo(s, 1480);
      pushUp(s);
      expect(s.standingOn?.id, 'boilerTank');
      walkTo(s, 1510);
      pushUp(s);
      expect(s.standingOn?.id, 'pipeShelf');
      walkTo(s, 1550);
      grab(s, 'chicken');
      walkTo(s, 1510);
      pushDown(s);
      expect(s.standingOn?.id, 'boilerTank');
      pushDown(s);
      expect(s.onFloor, isTrue);
      watch();

      // Back up, to the egg in her nest, and out.
      walkTo(s, 1880);
      upStairs(s, -1);
      expect(s.playerY, 660);
      walkTo(s, 1030);
      expect(s.interaction, isA<GrabLoot>().having((g) => g.loot.id, 'loot', 'egg'));
      walkTo(s, 1926);
      tickUntil(s, () => s.outcome != null, limit: 2);
      watch();

      expect(s.outcome, Outcome.escaped);
      expect(s.carried, unorderedEquals(['toaster', 'duck', 'gnome', 'chicken']));
      expect(seen, {GooseState.asleep}, reason: 'a sneaking route never wakes her');
      expect(s.met(s.level.goals.firstWhere((g) => g.style == PlayStyle.ghost)), isTrue);
    });
  });
}
