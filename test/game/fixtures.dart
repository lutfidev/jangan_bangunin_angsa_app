import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/level.dart';
import 'package:jangan_bangunin_angsa_app/game/night_sim.dart';

/// Night 3, read straight from the bundled asset.
Level night3() => Level.parse(File('assets/levels/night3.json').readAsStringSync());

/// A valid one-spot level as JSON (format v2), with any top-level key
/// overridden. One wood floor at y 270, no furniture unless [platforms].
/// Spots, loot, hide spots and remix loot may give a bare `x`: they are put
/// on the floor.
String minimalLevel({
  List<Object?>? spots,
  List<Object?>? objects,
  List<Object?>? links,
  List<Object?>? loot,
  List<double>? hideSpots,
  List<Object?>? platforms,
  List<Object?>? goals,
  Map<String, Object?>? remix,
  Map<String, Object?> extra = const {},
}) => jsonEncode({
  'version': 2,
  'id': 'test',
  'name': 'Test',
  'width': 844,
  'floorY': 270,
  'solids': [
    {'box': [0, 270, 844, 120], 'surface': 'wood'},
  ],
  'platforms': platforms ?? <Object?>[],
  'playerStart': [0, 270],
  'exit': [800, 270],
  'bed': [400, 270],
  'hideSpots': [for (final x in hideSpots ?? const <double>[]) [x, 270]],
  'spots': [for (final s in spots ?? [{'id': 'a', 'x': 10}]) _onFloor(s)],
  'objects': objects ?? [{'id': 'o', 'type': 'tipper', 'spot': 'a'}],
  'links': links ?? <Object?>[],
  'loot': [for (final l in loot ?? const <Object?>[]) _onFloor(l)],
  'goals': ?goals,
  'remix': ?_remixOnFloor(remix),
  ...extra,
});

/// [item] with a bare `x` moved to `at: [x, 270]`.
Object? _onFloor(Object? item) {
  final m = Map.of(item! as Map<String, Object?>);
  if (m.containsKey('x') && !m.containsKey('at')) m['at'] = [m.remove('x'), 270];
  return m;
}

Map<String, Object?>? _remixOnFloor(Map<String, Object?>? remix) {
  if (remix == null) return null;
  final loot = remix['loot'] as Map<String, Object?>?;
  return {
    ...remix,
    if (loot != null)
      'loot': {
        for (final MapEntry(:key, :value) in loot.entries)
          key: [for (final p in value! as List) p is num ? [p, 270] : p],
      },
  };
}

const frame = 1 / 60;

/// Walks (or sneaks) the burglar until they reach [x], a frame at a time.
void walkTo(NightSim s, double x) {
  final right = x > s.playerX;
  s.setMove(right ? 1 : -1);
  for (var i = 0; i < 60 * 30 && s.outcome == null; i++) {
    if (right ? s.playerX >= x : s.playerX <= x) break;
    s.tick(frame);
  }
  s.setMove(0);
}

/// Ticks frames until [done], failing the test after [limit] seconds.
void tickUntil(NightSim s, bool Function() done, {double limit = 30}) {
  for (var t = 0.0; !done(); t += frame) {
    if (t > limit) fail('condition not met within ${limit}s');
    s.tick(frame);
  }
}

/// Pushes the stick up once and waits for the mantle to finish.
void pushUp(NightSim s) {
  s
    ..setVertical(-1)
    ..tick(frame);
  tickUntil(s, () => !s.mantling, limit: 2);
  s
    ..setVertical(0)
    ..tick(frame);
}

/// Pushes the stick down once and waits to land.
void pushDown(NightSim s) {
  s
    ..setVertical(1)
    ..tick(frame);
  tickUntil(s, () => s.grounded, limit: 2);
  s
    ..setVertical(0)
    ..tick(frame);
}

/// Climbs Night 3's furniture onto [platformId]: from the floor at x 260
/// by the counter (then up to the crawl plank), or at x 350 up the shelves.
void climbTo(NightSim s, String platformId, {bool viaShelves = false}) {
  walkTo(s, viaShelves || platformId.startsWith('shelf') ? 350 : 260);
  while (s.standingOn?.id != platformId) {
    final before = s.playerY;
    pushUp(s);
    if (s.playerY == before) fail('stuck below $platformId at ${s.playerX}, ${s.playerY}');
  }
}
