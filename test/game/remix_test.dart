import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/level.dart';
import 'package:jangan_bangunin_angsa_app/game/remix.dart';
import 'package:jangan_bangunin_angsa_app/game/tuning.dart';

import 'fixtures.dart';

/// Where tonight's movable pieces are: loot x by id, then each object's
/// spot. A list, so matchers compare it deeply.
List<Map<String, Object>> layout(Level level) => [
  {for (final l in level.loot) l.id: l.x},
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
    final toaster = <double>{}, chicken = <double>{}, pot = <String>{};
    for (final seed in year2026()) {
      final [loot, objects] = layout(remixed(level, seed));
      toaster.add(loot['toaster']! as double);
      chicken.add(loot['chicken']! as double);
      pot.add(objects['pot']! as String);
    }
    expect(toaster, {218, 60});
    expect(chicken, {353, 300});
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

  test('a floor remix spot never shares reach with a hide spot', () {
    // Mid-chase, Interact by a hide spot must hide, not grab.
    final level = night3();
    final reach = const Tuning().reach;
    for (final loot in level.loot.where((l) => !l.high)) {
      for (final x in level.remixLoot[loot.id] ?? const <double>[]) {
        for (final h in level.hideSpots) {
          expect((x - h).abs(), greaterThan(2 * reach), reason: '${loot.id} at $x, hide at $h');
        }
      }
    }
  });

  test('a high remix spot leaves both crawlway ends free to climb down', () {
    final level = night3();
    final reach = const Tuning().reach;
    final crawl = level.crawlway!;
    for (final loot in level.loot.where((l) => l.high)) {
      for (final x in level.remixLoot[loot.id] ?? const <double>[]) {
        for (final end in [crawl.from, crawl.to]) {
          expect((x - end).abs(), greaterThan(reach), reason: '${loot.id} at $x, end at $end');
        }
      }
    }
  });
}
