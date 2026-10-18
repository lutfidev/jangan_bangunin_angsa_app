import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/goose_brain.dart';
import 'package:jangan_bangunin_angsa_app/game/noise.dart';
import 'package:jangan_bangunin_angsa_app/game/tuning.dart';

GooseBrain _goose() => GooseBrain(bedX: 502, tuning: const Tuning());

/// Ticks in 0.05s steps, like a frame loop would.
void run(GooseBrain g, double seconds, {double playerX = 236, bool hidden = false}) {
  for (var t = 0.0; t < seconds - 1e-9; t += 0.05) {
    g.tick(0.05, playerX: playerX, playerHidden: hidden);
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
    run(g, 6);
    expect(g.state, GooseState.drowsy);
    expect(g.inBed, isTrue);
    expect(g.meter.value, 0);
  });

  test('chase gives up after 12s', () {
    // The burglar keeps 100px ahead; she never gets close enough to catch them.
    final g = _goose()..wake(WakeCause.noise);
    void outrun(double seconds) {
      for (var t = 0.0; t < seconds - 1e-9; t += 0.05) {
        g.tick(0.05, playerX: g.x - 100, playerHidden: false);
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
}
