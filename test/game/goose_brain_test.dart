import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/doors.dart';
import 'package:jangan_bangunin_angsa_app/game/geom.dart';
import 'package:jangan_bangunin_angsa_app/game/goose_brain.dart';
import 'package:jangan_bangunin_angsa_app/game/level.dart';
import 'package:jangan_bangunin_angsa_app/game/nav.dart';
import 'package:jangan_bangunin_angsa_app/game/noise.dart';
import 'package:jangan_bangunin_angsa_app/game/tuning.dart';

import 'fixtures.dart';

/// A bare floor 0..844 at 270, her bed at 502.
Nav _flat() => Nav(Level.parse(minimalLevel(extra: {'bed': [502, 270]})));

GooseBrain _goose() => GooseBrain(nav: _flat(), bed: const Vec(502, 270), tuning: const Tuning());

/// Ticks in 0.05s steps, like a frame loop would. She sees Milo at
/// [playerX] on the floor unless he is [hidden] or [unseen].
void run(GooseBrain g, double seconds, {double playerX = 236, double playerY = 270, bool hidden = false, bool unseen = false}) {
  for (var t = 0.0; t < seconds - 1e-9; t += 0.05) {
    g.tick(0.05, player: Vec(playerX, playerY), sees: !hidden && !unseen, hidden: hidden);
  }
}

const _walkThere = (502 - 113) / 50;

void main() {
  test('far loud noise makes her sleepwalk, sniff 4s and come back drowsy', () {
    final g = _goose()..hear(const Noise(x: 113, loudness: 2));
    expect(g.state, GooseState.sleepwalk);
    expect(g.inBed, isFalse);
    run(g, _walkThere + 0.1);
    expect(g.sniffing, isTrue);
    expect(g.x, 113);
    run(g, 4 + _walkThere + 0.1);
    expect(g.state, GooseState.drowsy);
    expect(g.x, 502);
    expect(g.meter.drowsyLeft, greaterThan(5));
  });

  test('a second loud noise while sniffing wakes her', () {
    final g = _goose()..hear(const Noise(x: 113, loudness: 2));
    run(g, _walkThere + 0.1);
    g.hear(const Noise(x: 62, loudness: 2));
    expect(g.state, GooseState.awake);
    expect(g.wakeCause, WakeCause.noise);
  });

  test('a loud noise close to her while she sleepwalks wakes her', () {
    final g = _goose()..hear(const Noise(x: 113, loudness: 2));
    run(g, 2); // still walking out, around x = 402
    expect(g.sniffing, isFalse);
    g.hear(const Noise(x: 340, loudness: 2));
    expect(g.state, GooseState.awake);
  });

  test('a small noise far away does nothing', () {
    final g = _goose()..hear(const Noise(x: 62, loudness: 1));
    expect(g.state, GooseState.asleep);
    expect(g.meter.value, 0);
  });

  test('a small noise in the ear zone stirs her', () {
    final g = _goose()..hear(const Noise(x: 614, loudness: 1));
    expect(g.state, GooseState.stirring);
  });

  test('loud noise in the ear zone wakes, then chase after 0.3s', () {
    final g = _goose()..hear(const Noise(x: 667, loudness: 3));
    expect(g.state, GooseState.awake);
    expect(g.wakeCause, WakeCause.noise);
    run(g, 0.2);
    expect(g.state, GooseState.awake);
    run(g, 0.15);
    expect(g.state, GooseState.chase);
  });

  test('loud footsteps wake her with the footsteps cause', () {
    final g = _goose()..meter.reset(value: 98);
    g.hear(const Noise(x: 502, loudness: 0));
    expect(g.state, GooseState.awake);
    expect(g.wakeCause, WakeCause.footsteps);
  });

  test('rolls over every 8s for 2s', () {
    final g = _goose();
    run(g, 7.9);
    expect(g.rollingOver, isFalse);
    run(g, 0.2);
    expect(g.rollingOver, isTrue);
    run(g, 2);
    expect(g.rollingOver, isFalse);
  });

  test('chases the burglar', () {
    final g = _goose()..wake(WakeCause.grabbedGuarded);
    run(g, 0.3 + 1, playerX: 236);
    expect(g.state, GooseState.chase);
    expect(g.x, closeTo(502 - 110, 6));
  });

  test('a 2+ link chain mid-chase distracts her for 4s', () {
    final g = _goose()..wake(WakeCause.noise);
    run(g, 0.35);
    g.hear(const Noise(x: 640, loudness: 1), chainLinks: 1);
    expect(g.state, GooseState.chase);
    g.hear(const Noise(x: 640, loudness: 1), chainLinks: 2);
    expect(g.state, GooseState.distracted);
    run(g, 3.9);
    expect(g.state, GooseState.distracted);
    expect(g.x, 640);
    run(g, 0.2);
    expect(g.state, GooseState.chase);
  });

  test('hiding 3s loses her; patrol, then drowsy in bed', () {
    final g = _goose()..wake(WakeCause.noise);
    run(g, 0.35);
    run(g, 2.9, hidden: true);
    expect(g.state, GooseState.chase);
    run(g, 0.2, hidden: true);
    expect(g.state, GooseState.lostYou);
    run(g, 6, hidden: true);
    expect(g.state, GooseState.drowsy);
    expect(g.inBed, isTrue);
    expect(g.meter.value, 0);
  });

  test('chase gives up after 12s', () {
    // The burglar keeps 100px ahead; she never gets close enough to catch them.
    final wide = Level.parse(minimalLevel(extra: {
      'width': 2000,
      'solids': [{'box': [0, 270, 2000, 120], 'surface': 'wood'}],
      'bed': [1900, 270],
    }));
    final g = GooseBrain(nav: Nav(wide), bed: wide.bed, tuning: const Tuning())..wake(WakeCause.noise);
    void outrun(double seconds) {
      for (var t = 0.0; t < seconds - 1e-9; t += 0.05) {
        g.tick(0.05, player: Vec(g.x - 100, 270), sees: true);
      }
    }

    outrun(0.35 + 11.9);
    expect(g.state, GooseState.chase);
    outrun(0.2);
    expect(g.state, GooseState.lostYou);
  });

  test('suspicious settles: hold still and it drains back to asleep', () {
    final g = _goose()..hear(const Noise(x: 502, loudness: 2));
    expect(g.state, GooseState.suspicious);
    run(g, 4); // 2s quiet, then 20 drained → 30
    expect(g.state, GooseState.stirring);
    run(g, 2.5);
    expect(g.state, GooseState.asleep);
  });

  test('chaseLeft counts down from 12', () {
    final g = _goose();
    expect(g.chaseLeft, 0);
    g.wake(WakeCause.noise);
    run(g, 0.3 + 2);
    expect(g.state, GooseState.chase);
    expect(g.chaseLeft, closeTo(10, 0.06));
  });

  test('distractLeft counts down from 4', () {
    final g = _goose();
    expect(g.distractLeft, 0);
    g.wake(WakeCause.noise);
    run(g, 0.5);
    g.hear(const Noise(x: 113, loudness: 2), chainLinks: 2);
    run(g, 1);
    expect(g.state, GooseState.distracted);
    expect(g.distractLeft, closeTo(3, 0.02));
  });

  group('slip', () {
    test('only while she runs after someone', () {
      final g = _goose()..slip();
      expect(g.slipping, isFalse);
    });

    test('holds her still for 2s while the chase clock runs', () {
      final g = _goose()..wake(WakeCause.noise);
      run(g, 0.35, playerX: 236);
      expect(g.state, GooseState.chase);
      g.slip();
      final x = g.x;
      final left = g.chaseLeft;
      run(g, 1.9, playerX: 236);
      expect(g.x, x);
      expect(g.chaseLeft, closeTo(left - 1.9, 0.06));
      expect(g.slipping, isTrue);
      run(g, 0.2, playerX: 236);
      expect(g.slipping, isFalse);
      expect(g.x, lessThan(x));
    });
  });

  group('doors', () {
    // Rooms a | b with the door at 400 closed; her bed at 800 in b.
    late Doors doors;
    late GooseBrain g;
    setUp(() {
      doors = Doors(Level.parse(twoRooms(extra: {'bed': [800, 270]})));
      g = GooseBrain(nav: Nav(doors.level), bed: const Vec(800, 270), tuning: const Tuning(), doors: doors);
    });

    void chase(double playerX) {
      g.wake(WakeCause.noise);
      run(g, 0.35, playerX: playerX);
      expect(g.state, GooseState.chase);
    }

    test('she walks to where the sound really was, and pushes the door open on the way', () {
      g.hear(const Noise(x: 400, loudness: 2), source: const Vec(100, 270));
      expect(g.state, GooseState.sleepwalk);
      run(g, (800 - 424) / 50 + 0.1);
      expect(g.x, 424);
      expect(g.pushingDoor, isTrue);
      expect(doors.isOpen('d'), isFalse);
      run(g, 2);
      expect(doors.isOpen('d'), isTrue);
      expect(doors.takeMoves().map((m) => (m.doorId, m.open, m.byGoose)), [('d', true, true)]);
      expect(g.pushingDoor, isFalse);
      run(g, 324 / 50 + 0.1);
      expect(g.x, 100);
      expect(g.sniffing, isTrue);
    });

    test('a sound on her side of a closed door leaves the door shut', () {
      g.hear(const Noise(x: 410, loudness: 2));
      run(g, (800 - 424) / 50 + 3);
      expect(doors.isOpen('d'), isFalse);
      expect(g.pushingDoor, isFalse);
      expect(g.x, 424);
      expect(g.sniffing, isTrue);
    });

    test('a slip mid-push starts the push over', () {
      chase(100);
      run(g, 376 / 110 + 0.1, playerX: 100);
      run(g, 1.5, playerX: 100);
      g.slip();
      run(g, 2.05, playerX: 100);
      run(g, 1, playerX: 100);
      expect(doors.isOpen('d'), isFalse);
    });

    test('a long frame never carries her through a closed door', () {
      final other = Doors(doors.level);
      final small = GooseBrain(nav: Nav(doors.level), bed: const Vec(800, 270), tuning: const Tuning(), doors: other);
      for (final (brain, dt) in [(g, 0.1), (small, 0.01)]) {
        brain.wake(WakeCause.noise);
        for (var t = 0.0; t < 4.5; t += dt) {
          brain.tick(dt, player: const Vec(100, 270), sees: true);
          expect(brain.x, greaterThanOrEqualTo(424), reason: 'dt $dt at $t');
        }
        expect(brain.x, 424, reason: 'dt $dt');
      }
    });

    test('chasing, she pushes through and follows', () {
      chase(100);
      run(g, 8, playerX: 100);
      expect(doors.isOpen('d'), isTrue);
      expect(g.x, lessThan(400));
    });

    test('turning away from a door starts the push over', () {
      chase(100);
      run(g, 376 / 110 + 0.1, playerX: 100);
      expect(g.pushingDoor, isTrue);
      run(g, 1.5, playerX: 100);
      run(g, 0.5, playerX: 900);
      expect(g.pushingDoor, isFalse);
      run(g, 0.2, playerX: 100);
      run(g, 1.7, playerX: 100);
      expect(doors.isOpen('d'), isFalse);
      run(g, 0.8, playerX: 100);
      expect(doors.isOpen('d'), isTrue);
    });
  });

  group('by sight', () {
    test('out of sight, she goes where she last saw him and gives up 3s after', () {
      final g = _goose()..wake(WakeCause.noise);
      run(g, 0.35);
      expect(g.state, GooseState.chase);
      // He slips out of her room; she last saw him at 236.
      run(g, (g.x - 236) / 110 + 0.1, playerX: 800, unseen: true);
      expect(g.x, 236);
      run(g, 2.8, playerX: 800, unseen: true);
      expect(g.state, GooseState.chase);
      run(g, 0.3, playerX: 800, unseen: true);
      expect(g.state, GooseState.lostYou);
    });

    test('in sight again, the chase is on again', () {
      final g = _goose()..wake(WakeCause.noise);
      run(g, 0.35);
      run(g, 1, playerX: 800, unseen: true);
      run(g, 3, playerX: 100);
      expect(g.state, GooseState.chase);
      expect(g.x, lessThan(236));
    });

    test('seen up where she cannot reach, she gives up after 3s', () {
      final g = GooseBrain(nav: Nav(night3()), bed: const Vec(502, 270), tuning: const Tuning())..wake(WakeCause.noise);
      run(g, 0.35, playerX: 353, playerY: 106);
      run(g, 2.6, playerX: 353, playerY: 106);
      expect(g.state, GooseState.chase);
      run(g, 0.5, playerX: 353, playerY: 106);
      expect(g.state, GooseState.lostYou);
    });

    test('she flaps up onto the counter under the crawl plank', () {
      final g = GooseBrain(nav: Nav(night3()), bed: const Vec(502, 270), tuning: const Tuning())..wake(WakeCause.noise);
      run(g, 0.35, playerX: 353, playerY: 106);
      expect(g.flapping, isFalse);
      run(g, (502 - 270) / 110, playerX: 353, playerY: 106);
      run(g, 0.2, playerX: 353, playerY: 106);
      expect(g.flapping, isTrue);
      expect(g.y, lessThan(270));
      run(g, 0.5, playerX: 353, playerY: 106);
      expect(g.at, const Vec(280, 200));
      expect(g.route!.catches, isFalse);
    });

    test('Milo on the counter she reaches from the floor', () {
      final g = GooseBrain(nav: Nav(night3()), bed: const Vec(502, 270), tuning: const Tuning())..wake(WakeCause.noise);
      run(g, 0.35 + 3, playerX: 200, playerY: 200);
      expect(g.at, const Vec(200, 270));
      expect(g.route!.catches, isTrue);
    });

    test('she takes the stair to a noise upstairs', () {
      final level = Level.parse(twoStoreys());
      final g = GooseBrain(nav: Nav(level), bed: level.bed, tuning: const Tuning())
        ..hear(const Noise(x: 300, y: 270, loudness: 2), source: const Vec(300, 270));
      expect(g.state, GooseState.sleepwalk);
      run(g, (500 + 200) / 50 + 0.2);
      expect(g.at, const Vec(300, 270));
      expect(g.sniffing, isTrue);
    });
  });
}
