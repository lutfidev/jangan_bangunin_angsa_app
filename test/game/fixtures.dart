import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/level.dart';
import 'package:jangan_bangunin_angsa_app/game/night_sim.dart';

/// Night 3, read straight from the bundled asset.
Level night3() => Level.parse(File('assets/levels/night3.json').readAsStringSync());

/// A valid one-spot level as JSON, with any top-level key overridden.
String minimalLevel({
  List<Object?>? spots,
  List<Object?>? objects,
  List<Object?>? links,
  List<Object?>? loot,
  List<double>? hideSpots,
  Map<String, Object?>? crawlway,
  List<Object?>? goals,
  Map<String, Object?>? remix,
}) => jsonEncode({
  'id': 'test',
  'name': 'Test',
  'playerStart': 0,
  'exitX': 800,
  'bedX': 400,
  'hideSpots': hideSpots ?? <double>[],
  'crawlway': ?crawlway,
  'spots': spots ?? [{'id': 'a', 'x': 10}],
  'objects': objects ?? [{'id': 'o', 'type': 'tipper', 'spot': 'a'}],
  'links': links ?? <Object?>[],
  'loot': loot ?? <Object?>[],
  'goals': ?goals,
  'remix': ?remix,
});

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
