import 'level.dart';

/// Nightly Remix (Gameplay 2.0): "Offline, seeded by the date: loot and
/// portable objects shuffle between preset spots."

/// The seed for a local date: 2026-10-19 is 20261019.
int remixSeed(int year, int month, int day) => year * 10000 + month * 100 + day;

/// [level] with its loot and portable objects moved to the preset spots
/// [seed] picks. Never the level's own layout, unless it has no presets.
Level remixed(Level level, int seed) {
  // One choice per entry: index 0 is where it already is.
  final loot = [
    for (final l in level.loot)
      if (level.remixLoot[l.id] case final points?) (l.id, [l.at, ...points]),
  ];
  final objects = [
    for (final o in level.objects)
      if (level.remixSpots[o.id] case final ids?) (o.id, [o.spot, ...ids]),
  ];
  final radices = [for (final (_, points) in loot) points.length, for (final (_, ids) in objects) ids.length];
  final layouts = radices.fold(1, (n, r) => n * r);
  if (layouts <= 1) return level;

  // Layout 0 is the canonical one; skip it. Mixed radix, first entry first.
  var pick = 1 + _mulberry32(seed) % (layouts - 1);
  final digits = <int>[];
  for (final r in radices) {
    digits.add(pick % r);
    pick ~/= r;
  }

  return level.rearranged(
    lootAt: {for (final (i, (id, points)) in loot.indexed) id: points[digits[i]]},
    objectSpots: {for (final (i, (id, ids)) in objects.indexed) id: ids[digits[loot.length + i]]},
  );
}

/// One draw of mulberry32, as an unsigned 32-bit int. Written out so a
/// seed gives the same night on every platform.
int _mulberry32(int seed) {
  var t = (seed + 0x6D2B79F5) & 0xFFFFFFFF;
  t = _imul(t ^ (t >> 15), t | 1);
  t ^= (t + _imul(t ^ (t >> 7), t | 61)) & 0xFFFFFFFF;
  return (t ^ (t >> 14)) & 0xFFFFFFFF;
}

/// 32-bit multiply, like JavaScript's Math.imul, kept unsigned.
int _imul(int a, int b) {
  final lo = (a & 0xFFFF) * b;
  final hi = ((a >> 16) & 0xFFFF) * b;
  return (lo + ((hi & 0xFFFF) << 16)) & 0xFFFFFFFF;
}
