import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/chain.dart';
import 'package:jangan_bangunin_angsa_app/game/goose_brain.dart';
import 'package:jangan_bangunin_angsa_app/game/geom.dart';
import 'package:jangan_bangunin_angsa_app/game/hearing.dart';
import 'package:jangan_bangunin_angsa_app/game/night_sim.dart';
import 'package:jangan_bangunin_angsa_app/game/noise.dart';
import 'package:jangan_bangunin_angsa_app/game/tools.dart';
import 'package:jangan_bangunin_angsa_app/screens/night_art.dart';
import 'package:jangan_bangunin_angsa_app/state/levels.dart';
import 'package:jangan_bangunin_angsa_app/theme/palette.dart';
import 'package:jangan_bangunin_angsa_app/widgets/noise_fx.dart';

NoiseMade _link(int chainId, int link, String objectId, String spotId, int loudness) => NoiseMade(
  Noise(x: spotAnchors[spotId]!.dx, loudness: loudness),
  touchedEar: false,
  link: LinkFired(
    chainId: chainId,
    link: link,
    objectId: objectId,
    spotId: spotId,
    noise: Noise(x: spotAnchors[spotId]!.dx, loudness: loudness),
  ),
);

void main() {
  late NoiseFx fx;
  setUp(() => fx = NoiseFx(level: Levels.night3, anchors: spotAnchors));

  void take(SimEvent e) => fx.take(e, gooseX: 502);

  test('a chain link draws rings, a badge and a word', () {
    take(_link(1, 2, 'pot', 'counterPot', 2));
    expect(fx.rings.single.circles, 2);
    expect(fx.rings.single.radius, 72);
    expect(fx.rings.single.color, Palette.beakOrange);
    expect(fx.rings.single.center, spotAnchors['counterPot']);
    expect(fx.badges.single.link, 2);
    expect(fx.words.single.text, 'CLANG!');
  });

  test('a badge arcs from the previous link of its chain', () {
    take(_link(1, 1, 'glass', 'counterLeft', 1));
    take(_link(1, 2, 'pot', 'counterPot', 2));
    expect(fx.badges.first.from, isNull);
    expect(fx.badges.last.from, spotAnchors['counterLeft']);
  });

  test('chains do not join', () {
    take(_link(1, 1, 'glass', 'counterLeft', 1));
    take(_link(2, 1, 'robot', 'sideTable', 1));
    expect(fx.badges.last.from, isNull);
  });

  test("a footstep is one tiny mint ring at Milo's feet", () {
    take(const NoiseMade(Noise(x: 300, loudness: 0), touchedEar: false));
    final ring = fx.rings.single;
    expect(ring.radius, 18);
    expect(ring.circles, 1);
    expect(ring.color, Palette.calmMint);
    expect(ring.center, const Offset(300, 262));
    expect(fx.badges, isEmpty);
    expect(fx.words, isEmpty);
  });

  test('effects expire', () {
    take(_link(1, 1, 'glass', 'counterLeft', 1));
    fx.advance(1.0);
    expect(fx.rings, isEmpty);
    expect(fx.words, isEmpty);
    expect(fx.badges, hasLength(1));
    fx.advance(1.1);
    expect(fx.badges, isEmpty);
  });

  test('waking her sets off HONK', () {
    take(const GooseChanged(GooseState.suspicious, GooseState.awake));
    expect(fx.honk?.at, const Offset(502, 210));
    fx.advance(1.1);
    expect(fx.honk, isNull);
  });

  test('a sock that missed rings where it landed and flops', () {
    take(const NoiseMade(Noise(x: 250, loudness: 0), touchedEar: false, tool: Tool.socks));
    expect(fx.rings.single.center, const Offset(250, 262));
    expect(fx.words.single.text, 'flop!');
    expect(fx.words.single.color, Palette.calmMint);
  });

  test('the kazoo toots where Milo stands', () {
    take(const NoiseMade(Noise(x: 300, loudness: 3), touchedEar: true, tool: Tool.kazoo));
    expect(fx.rings.single.center, const Offset(300, 220));
    expect(fx.words.single.text, 'TOOT!');
    expect(fx.words.single.color, Palette.alarmTomato);
  });

  test("Milo's noises ring at his height, up on the furniture too", () {
    take(const NoiseMade(Noise(x: 300, y: 106, loudness: 3), touchedEar: false, tool: Tool.kazoo));
    expect(fx.rings.single.center, const Offset(300, 106 - 50));
    take(const NoiseMade(Noise(x: 150, y: 200, loudness: 0), touchedEar: false));
    expect(fx.rings.last.center, const Offset(150, 200 - 8));
    take(const NoiseMade(Noise(x: 150, y: 270, loudness: 1), touchedEar: false));
    expect(fx.rings.last.center, const Offset(150, 220));
  });

  test('a slip says so', () {
    take(const GooseSlipped(480));
    expect(fx.words.single.text, 'SLIP!');
    expect(fx.words.single.at, const Offset(480, 200));
  });

  group('in the house', () {
    setUp(() => fx = NoiseFx(level: Levels.house, anchors: const {}));

    test('a noise heard through a door adds a dashed ring at the door', () {
      final door = Levels.house.doors.first;
      take(NoiseMade(
        const Noise(x: 300, loudness: 3),
        touchedEar: false,
        heard: Heard(
          Noise(x: door.x, y: door.floorY, loudness: 2),
          through: Portal(kind: PortalKind.door, id: door.id, a: door.left, b: door.right),
          source: Vec(300, door.floorY),
        ),
        tool: Tool.kazoo,
      ));
      expect(fx.rings, hasLength(2));
      final muffled = fx.rings.last;
      expect(muffled.dashed, isTrue);
      expect(muffled.center, Offset(640, door.floorY - 50));
      expect(muffled.radius, 72);
      expect(muffled.circles, 2);
      expect(muffled.color, Palette.beakOrange);
      expect(fx.rings.first.dashed, isFalse);
      expect(fx.words.map((w) => w.text), ['TOOT!']);
    });

    test('a door creaks', () {
      take(const NoiseMade(Noise(x: 640, loudness: 1), touchedEar: false, door: 'kitchenDoor'));
      expect(fx.words.single.text, 'creak!');
      expect(fx.words.single.color, Palette.lamp);
    });
  });
}
