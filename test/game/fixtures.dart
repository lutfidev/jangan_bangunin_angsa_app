import 'dart:convert';
import 'dart:io';

import 'package:jangan_bangunin_angsa_app/game/level.dart';

/// Night 3, read straight from the bundled asset.
Level night3() => Level.parse(File('assets/levels/night3.json').readAsStringSync());

/// A valid one-spot level as JSON, with any top-level key overridden.
String minimalLevel({
  List<Object?>? spots,
  List<Object?>? objects,
  List<Object?>? links,
  List<Object?>? loot,
}) => jsonEncode({
  'id': 'test',
  'name': 'Test',
  'playerStart': 0,
  'exitX': 800,
  'bedX': 400,
  'hideSpots': <double>[],
  'spots': spots ?? [{'id': 'a', 'x': 10}],
  'objects': objects ?? [{'id': 'o', 'type': 'tipper', 'spot': 'a'}],
  'links': links ?? <Object?>[],
  'loot': loot ?? <Object?>[],
});
