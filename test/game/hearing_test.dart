import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/doors.dart';
import 'package:jangan_bangunin_angsa_app/game/hearing.dart';
import 'package:jangan_bangunin_angsa_app/game/level.dart';
import 'package:jangan_bangunin_angsa_app/game/noise.dart';
import 'package:jangan_bangunin_angsa_app/game/tuning.dart';

import 'fixtures.dart';

const t = Tuning();

/// Rooms a | b | c with doors at 400 and 600, both closed.
Level threeRooms() => Level.parse(minimalLevel(extra: {
  'rooms': [
    {'id': 'a', 'name': 'A', 'box': [0, 0, 400, 270]},
    {'id': 'b', 'name': 'B', 'box': [400, 0, 200, 270]},
    {'id': 'c', 'name': 'C', 'box': [600, 0, 244, 270]},
  ],
  'doors': [
    {'id': 'ab', 'x': 400},
    {'id': 'bc', 'x': 600},
  ],
}));

void main() {
  late Level level;
  late Doors doors;
  late Hearing hearing;
  setUp(() {
    level = threeRooms();
    doors = Doors(level);
    hearing = Hearing(level, doors, t);
  });

  test('in her room a noise is heard as itself', () {
    const n = Noise(x: 100, loudness: 2);
    final heard = hearing.reach(n, 300)!;
    expect(heard.noise, same(n));
    expect(heard.muffled, isFalse);
    expect(heard.sourceX, 100);
  });

  test('a closed door muffles it by one, heard at the door', () {
    final heard = hearing.reach(const Noise(x: 100, y: 200, loudness: 2), 500)!;
    expect(heard.muffled, isTrue);
    expect(heard.through!.id, 'ab');
    expect(heard.noise.x, 400);
    expect(heard.noise.y, isNull);
    expect(heard.noise.loudness, 1);
    expect(heard.sourceX, 100);
  });

  test('an open door lets it through whole', () {
    doors.open('ab');
    final heard = hearing.reach(const Noise(x: 100, loudness: 2), 500)!;
    expect(heard.noise.loudness, 2);
    expect(heard.noise.x, 400);
    expect(heard.through!.id, 'ab');
  });

  test('two closed doors take two, and a noise that dies out is not heard', () {
    final heard = hearing.reach(const Noise(x: 100, loudness: 3), 700)!;
    expect(heard.noise.loudness, 1);
    expect(heard.noise.x, 600);
    expect(heard.through!.id, 'bc');
    expect(hearing.reach(const Noise(x: 100, loudness: 2), 700), isNull);
  });

  test('footsteps never leave their room', () {
    doors.open('ab');
    expect(hearing.reach(const Noise(x: 300, loudness: 0), 500), isNull);
  });

  test('a noise in a doorway is in both rooms', () {
    const n = Noise(x: 400, loudness: 1);
    for (final open in [false, true]) {
      open ? doors.open('ab') : doors.close('ab');
      expect(hearing.reach(n, 200)!.noise, same(n), reason: 'open $open, goose in a');
      expect(hearing.reach(n, 500)!.noise, same(n), reason: 'open $open, goose in b');
    }
  });

  test('a goose in a doorway hears both rooms directly', () {
    const n = Noise(x: 100, loudness: 1);
    expect(hearing.reach(n, 400)!.noise, same(n));
  });

  test('night 3 is one room: every noise is heard as itself', () {
    final n3 = night3();
    final h = Hearing(n3, Doors(n3), t);
    for (final n in const [Noise(x: 10, loudness: 0), Noise(x: 840, y: 106, loudness: 3)]) {
      expect(h.reach(n, 502)!.noise, same(n));
    }
  });
}
