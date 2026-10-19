import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/geom.dart';
import 'package:jangan_bangunin_angsa_app/game/level.dart';
import 'package:jangan_bangunin_angsa_app/game/remix.dart';
import 'package:jangan_bangunin_angsa_app/game/tuning.dart';

import 'fixtures.dart';

/// Where tonight's movable pieces are: loot position by id, then each object's
/// spot. A list, so matchers compare it deeply.
List<Map<String, Object>> layout(Level level) => [
  {for (final l in level.loot) l.id: l.at},
  {for (final o in level.objects) o.id: o.spot},
];

/// Every day of 2026, as remix seeds.
Iterable<int> year2026() sync* {
  for (var d = DateTime.utc(2026); d.year == 2026; d = d.add(const Duration(days: 1))) {
    yield remixSeed(d.year, d.month, d.day);
  }
}

void main() {
  test('seed is the date as digits', () {
    expect(remixSeed(2026, 10, 19), 20261019);
    expect(remixSeed(2027, 1, 2), 20270102);
  });

  test('same seed, same layout', () {
    final level = night3();
    expect(layout(remixed(level, 20261019)), layout(remixed(level, 20261019)));
  });

  test('never the canonical layout', () {
    final level = night3();
    final canonical = layout(level);
    for (final seed in year2026()) {
      expect(layout(remixed(level, seed)), isNot(canonical), reason: 'seed $seed');
    }
  });

  test('every alternative shows up within a year', () {
    final level = night3();
    final toaster = <Vec>{}, chicken = <Vec>{}, pot = <String>{};
    for (final seed in year2026()) {
      final [loot, objects] = layout(remixed(level, seed));
      toaster.add(loot['toaster']! as Vec);
      chicken.add(loot['chicken']! as Vec);
      pot.add(objects['pot']! as String);
    }
    expect(toaster, {const Vec(218, 200), const Vec(60, 270)});
    expect(chicken, {const Vec(353, 106), const Vec(300, 106)});
    expect(pot, {'counterPot', 'underShelf', 'underSideTable'});
  });

  test('the egg never moves', () {
    final level = night3();
    for (final seed in year2026()) {
      expect(remixed(level, seed).loot.firstWhere((l) => l.guarded).x, 561);
    }
  });

  test('a level without remix entries comes back unchanged', () {
    final level = Level.parse(minimalLevel());
    expect(layout(remixed(level, 20261019)), layout(level));
  });

  test('a remix spot in reach from the floor never shares reach with a hide spot', () {
    // Mid-chase, Interact by a hide spot must hide, not grab.
    final level = night3();
    const t = Tuning();
    for (final loot in level.loot) {
      for (final p in level.remixLoot[loot.id] ?? const <Vec>[]) {
        if (p.y < level.floorY - t.armReach) continue;
        for (final h in level.hideSpots) {
          expect((p.x - h.x).abs(), greaterThan(2 * t.reach), reason: '${loot.id} at $p, hide at $h');
        }
      }
    }
  });

  test('every loot spot, remixed or not, can be reached from something to stand on', () {
    final level = night3();
    const t = Tuning();
    final g = level.geometry;
    for (final loot in level.loot) {
      for (final p in [loot.at, ...?level.remixLoot[loot.id]]) {
        expect(g.restsOnSurface(p), isTrue, reason: '${loot.id} at $p');
        // Where he can stand under its x: the floor and every top there.
        final stands = [
          if (g.floorSurfaceAt(p.x) != null) g.floorY,
          for (final pl in g.platforms)
            if (pl.spans(p.x)) pl.y,
        ];
        expect(stands.any((feet) => p.y >= feet - t.armReach && p.y <= feet + 10), isTrue, reason: '${loot.id} at $p');
      }
    }
  });
}
