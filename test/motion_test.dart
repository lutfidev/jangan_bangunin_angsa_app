import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/art/art.dart';
import 'package:jangan_bangunin_angsa_app/art/motion.dart';
import 'package:jangan_bangunin_angsa_app/art/rig.dart';
import 'package:jangan_bangunin_angsa_app/game/goose_brain.dart';
import 'package:jangan_bangunin_angsa_app/screens/night_art.dart';

Gait milo({
  double phase = 0,
  double speed = 0,
  double vy = 0,
  bool grounded = true,
  double sinceLanding = 99,
  double landing = 1,
  double time = 0,
  bool sneaking = false,
  bool carrying = false,
  bool panic = false,
  bool crawling = false,
  bool mantling = false,
}) => Gait.milo(
  phase: phase,
  speed: speed,
  vy: vy,
  grounded: grounded,
  sinceLanding: sinceLanding,
  landing: landing,
  facing: 1,
  time: time,
  sneaking: sneaking,
  carrying: carrying,
  panic: panic,
  crawling: crawling,
  mantling: mantling,
);

void main() {
  group('Gait', () {
    test('standing at the start of the night draws the art as it is', () {
      final g = milo();
      expect(g.lift, 0);
      expect(g.tilt, 0);
      expect(g.stretchX, 1);
      expect(g.stretchY, 1);
    });

    test('standing still, he breathes', () {
      final g = milo(time: 0.65); // a quarter of the 2.6s breath
      expect(g.stretchY, greaterThan(1));
      expect(g.stretchX, lessThan(1));
    });

    test('each way of walking hops differently', () {
      const quarter = math.pi / 2; // the top of a hop
      final tiptoe = milo(phase: quarter, speed: 60, sneaking: true);
      final walk = milo(phase: quarter, speed: 120);
      final panic = milo(phase: quarter, speed: 120, panic: true);
      final crawl = milo(phase: quarter, speed: 90, crawling: true);
      expect(tiptoe.lift, lessThan(walk.lift));
      expect(walk.lift, lessThan(panic.lift));
      expect(crawl.lift, lessThan(tiptoe.lift));
    });

    test('carrying loot waddles instead of hopping', () {
      final g = milo(phase: math.pi / 2, speed: 100, carrying: true);
      expect(g.lift, lessThan(milo(phase: math.pi / 2, speed: 100).lift));
      expect(g.tilt, isNot(0));
    });

    test('a crawl stretches and shortens like an inchworm', () {
      final out = milo(phase: math.pi / 2, speed: 90, crawling: true);
      final back = milo(phase: -math.pi / 2, speed: 90, crawling: true);
      expect(out.stretchX, greaterThan(1));
      expect(back.stretchX, lessThan(1));
    });

    test('in the air he stretches, leaning in on the way up and back on the way down', () {
      final up = milo(grounded: false, vy: -550);
      final down = milo(grounded: false, vy: 550);
      expect(up.stretchY, greaterThan(1));
      expect(down.stretchY, greaterThan(1));
      expect(up.tilt, greaterThan(0));
      expect(down.tilt, lessThan(0));
    });

    test('a landing squats and fades away', () {
      final now = milo(sinceLanding: 0);
      final later = milo(sinceLanding: 0.1);
      final done = milo(sinceLanding: 0.2);
      expect(now.stretchY, lessThan(later.stretchY));
      expect(later.stretchY, lessThan(1));
      expect(done.stretchY, 1);
      expect(now.stretchX, greaterThan(1));
    });

    test('a soft landing squats less than a hard one', () {
      expect(milo(sinceLanding: 0, landing: 0.3).stretchY, greaterThan(milo(sinceLanding: 0, landing: 1).stretchY));
    });

    test('a mantle hunches him forward', () {
      final g = milo(mantling: true);
      expect(g.tilt, greaterThan(0));
      expect(g.stretchY, lessThan(1));
    });

    test('scaled by 0 is still, and by 1 is itself', () {
      final g = milo(phase: math.pi / 2, speed: 120);
      expect(g.scaled(0).lift, 0);
      expect(g.scaled(0).stretchY, 1);
      expect(g.scaled(1).lift, g.lift);
    });
  });

  group('FigureMotion', () {
    test('the walk cycle advances with the ground covered, not with time', () {
      final m = FigureMotion(stride: 64)..update(0.016, 0, 0);
      for (var i = 0; i < 60; i++) {
        m.update(0.016, 0, 0);
      }
      expect(m.phase, 0);
      m.update(0.5, 64, 0);
      expect(m.phase, closeTo(2 * math.pi, 1e-9));
    });

    test('his pace eases up to speed and settles when he stops', () {
      final m = FigureMotion()..update(1 / 60, 0, 0);
      for (var i = 1; i <= 30; i++) {
        m.update(1 / 60, i * 2.0, 0);
      }
      expect(m.speed, closeTo(120, 5));
      for (var i = 0; i < 60; i++) {
        m.update(1 / 60, 60, 0);
      }
      expect(m.speed, lessThan(1));
    });

    test('a jump across a room is not a walk', () {
      final m = FigureMotion()..update(1 / 60, 0, 0);
      m.update(1 / 60, 500, 0);
      expect(m.phase, 0);
      expect(m.speed, 0);
    });

    test('coming down remembers when he landed and how hard', () {
      final m = FigureMotion()..update(1 / 60, 0, 0);
      m.update(1 / 60, 0, -40, grounded: false);
      m.update(1 / 60, 0, 0, grounded: false);
      for (var i = 0; i < 10; i++) {
        m.update(1 / 60, 0, 12.0 * (i + 1), grounded: false);
      }
      m.update(1 / 60, 0, 130, grounded: true);
      expect(m.sinceLanding, 0);
      expect(m.landing, greaterThan(0.3));
      m.update(0.1, 0, 130);
      expect(m.sinceLanding, closeTo(0.1, 1e-9));
    });

    test('a frame with no time passing changes nothing', () {
      final m = FigureMotion()..update(1 / 60, 0, 0);
      m.update(0, 40, 0);
      expect(m.phase, 0);
      expect(m.speed, 0);
    });
  });

  group('gooseGait', () {
    Gait goose(GooseState s, {double phase = math.pi / 2, double speed = 0, double time = 0.8}) =>
        gooseGait(s, phase: phase, speed: speed, time: time, dir: 1);

    test('asleep she breathes, deeper than he does', () {
      final g = goose(GooseState.asleep, time: 0.8); // a quarter of the 3.2s breath
      expect(g.stretchY, closeTo(1.03, 1e-9));
      expect(g.lift, 0);
    });

    test('the chase is a hurried waddle that sleepwalking is not', () {
      final run = goose(GooseState.chase, speed: 110);
      final walk = goose(GooseState.sleepwalk, speed: 50);
      expect(run.lift, greaterThan(walk.lift));
      expect(run.tilt.abs(), greaterThan(walk.tilt.abs()));
    });

    test('stuck at a door mid-chase she fumes in place instead of waddling', () {
      final g = goose(GooseState.chase, speed: 0);
      expect(g.lift, 0);
    });
  });

  group('miloBends', () {
    Map<String, Bend> bends(
      BurglarPose pose, {
      double phase = math.pi / 2,
      double speed = 120,
      double vy = 0,
      bool grounded = true,
      bool sneaking = false,
      bool mantling = false,
      double time = 0,
    }) => miloBends(pose, phase: phase, speed: speed, vy: vy, grounded: grounded, time: time, sneaking: sneaking, mantling: mantling);

    test('standing still on the first frame bends nothing: the parts draw the canvas art', () {
      for (final pose in [BurglarPose.sneak, BurglarPose.carry, BurglarPose.crawl]) {
        for (final b in bends(pose, speed: 0).values) {
          expect(b, Bend.none, reason: '$pose');
        }
      }
    });

    test('the legs swing against each other and lift in turn', () {
      final b = bends(BurglarPose.sneak);
      expect(b['legA']!.angle, closeTo(-b['legB']!.angle, 1e-9));
      expect(b['legA']!.angle, isNot(0));
      final later = bends(BurglarPose.sneak, phase: 3 * math.pi / 2);
      expect(later['legA']!.angle, closeTo(-b['legA']!.angle, 1e-9));
      // One foot is off the floor while the other is down.
      final mid = bends(BurglarPose.sneak, phase: 0);
      expect(mid['legA']!.dy, lessThan(0));
      expect(mid['legB']!.dy, 0);
    });

    test('the arms swing against the legs', () {
      final b = bends(BurglarPose.sneak);
      expect(b['armA']!.angle.sign, isNot(b['legA']!.angle.sign));
    });

    test('tiptoeing takes smaller steps than walking, and a panic the biggest', () {
      double swing(Map<String, Bend> b) => b['legA']!.angle.abs();
      final tiptoe = swing(bends(BurglarPose.sneak, sneaking: true));
      final walk = swing(bends(BurglarPose.sneak));
      final panic = swing(bends(BurglarPose.panic));
      expect(tiptoe, lessThan(walk));
      expect(walk, lessThan(panic));
    });

    test('carrying keeps the arms up and shaking while the legs walk', () {
      final b = bends(BurglarPose.carry, time: 0.5);
      expect(b['armA']!.angle.abs(), lessThan(0.05));
      expect(b['armA']!.angle, isNot(0));
      expect(b['legA']!.angle, isNot(0));
    });

    test('a crawl moves a front limb with the opposite back leg', () {
      final b = bends(BurglarPose.crawl, speed: 90);
      expect(b['armA']!.angle.sign, b['legB']!.angle.sign);
    });

    test('a panicking Milo flails even when he cannot move', () {
      expect(bends(BurglarPose.panic, speed: 0, time: 0.04)['armA']!.angle, isNot(0));
    });

    test('in the air the arms fly out and a knee tucks', () {
      final b = bends(BurglarPose.sneak, grounded: false, vy: -500);
      expect(b['armA']!.angle, lessThan(0));
      expect(b['armB']!.angle, greaterThan(0));
      expect(b['legA']!.angle, lessThan(0));
      expect(b['legA']!.dy, lessThan(0));
    });

    test('a mantle scrambles the legs', () {
      final a = bends(BurglarPose.sneak, mantling: true, time: 0.05);
      final b = bends(BurglarPose.sneak, mantling: true, time: 0.15);
      expect(a['legA']!.angle, isNot(b['legA']!.angle));
    });
  });

  group('gooseBends', () {
    Map<String, Bend> bends(GooseState s, {double phase = math.pi / 2, double speed = 0, double time = 0.8}) =>
        gooseBends(s, phase: phase, speed: speed, time: time);

    test('asleep her head rises and falls with her breath', () {
      final up = bends(GooseState.asleep, time: 0.8)['head']!;
      final down = bends(GooseState.asleep, time: 2.4)['head']!;
      expect(up.dy, greaterThan(0));
      expect(down.dy, lessThan(0));
    });

    test('suspicious she sweeps her head from side to side', () {
      final a = bends(GooseState.suspicious, time: 0.5)['head']!.angle;
      final b = bends(GooseState.suspicious, time: 2.3)['head']!.angle;
      expect(a.sign, isNot(b.sign));
    });

    test('in the chase her legs alternate and her wings beat', () {
      final b = bends(GooseState.chase, speed: 110);
      expect(b['legA']!.angle, closeTo(-b['legB']!.angle, 1e-9));
      expect(b['legA']!.angle, isNot(0));
      final later = bends(GooseState.chase, speed: 110, time: 1.0);
      expect(later['wingNear']!.angle, isNot(b['wingNear']!.angle));
    });

    test('her head thrusts forward (-x) on a stride and back on the next', () {
      final a = bends(GooseState.chase, speed: 110, phase: math.pi / 2)['head']!.dx;
      final b = bends(GooseState.chase, speed: 110, phase: 3 * math.pi / 2)['head']!.dx;
      expect(a, lessThan(b));
    });
  });
}