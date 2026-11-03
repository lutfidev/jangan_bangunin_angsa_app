import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'art.dart' show BurglarPose;
import 'rig.dart';

/// How a figure is bent for one frame: lifted, leaned and squashed about its
/// feet. The art stays the canvas art; the gait moves it, so each way of
/// walking looks different without a second drawing.
class Gait {
  const Gait({this.lift = 0, this.tilt = 0, this.stretchX = 1, this.stretchY = 1});

  /// At rest: draws the art as it is.
  static const still = Gait();

  /// Pixels up off the floor.
  final double lift;

  /// Radians, clockwise positive (leaning towards +x).
  final double tilt;
  final double stretchX;
  final double stretchY;

  static Gait lerp(Gait a, Gait b, double t) => Gait(
    lift: a.lift + (b.lift - a.lift) * t,
    tilt: a.tilt + (b.tilt - a.tilt) * t,
    stretchX: a.stretchX + (b.stretchX - a.stretchX) * t,
    stretchY: a.stretchY + (b.stretchY - a.stretchY) * t,
  );

  /// This gait with every bend multiplied by [k]; 0 is [still].
  Gait scaled(double k) => lerp(still, this, k);

  /// Squashed by [amount] (0.3 is a 30% squat), wider in return.
  Gait squashed(double amount) =>
      Gait(lift: lift, tilt: tilt, stretchX: stretchX * (1 + amount * 0.7), stretchY: stretchY * (1 - amount));

  Matrix4 get matrix =>
      Matrix4.translationValues(0, -lift, 0) * Matrix4.rotationZ(tilt) * Matrix4.diagonal3Values(stretchX, stretchY, 1);

  /// Breathing: a slow swell of the chest, [depth] of the figure's height.
  static Gait breathe(double time, {double period = 2.6, double depth = 0.025}) {
    final b = math.sin(2 * math.pi * time / period);
    return Gait(stretchY: 1 + depth * b, stretchX: 1 - depth * 0.5 * b);
  }

  /// Milo. Each way of moving has its own gait: the hop of a walk, the low
  /// lean of tiptoeing, the heavy waddle of carrying loot, the lurch of a
  /// panic, the inchworm of a crawl; and the stretch of a jump, the squat of a
  /// landing and the hunch of a mantle.
  ///
  /// [phase] is the walk cycle (see [FigureMotion]), [speed] his pace in px/s,
  /// [vy] his vertical speed (y down), [facing] +1 right or -1 left, and
  /// [time] the night's clock, for breathing.
  static Gait milo({
    required double phase,
    required double speed,
    required double vy,
    required bool grounded,
    required double sinceLanding,
    required double landing,
    required double facing,
    required double time,
    bool sneaking = false,
    bool carrying = false,
    bool panic = false,
    bool crawling = false,
    bool mantling = false,
  }) {
    if (mantling) return Gait(tilt: facing * 0.22, stretchX: 1.06, stretchY: 0.9);

    if (!grounded) {
      // Stretched along the way up and down; leaning in on the rise, back on the fall.
      final v = (vy / _topSpeed).clamp(-1.0, 1.0);
      final tall = 1 + 0.14 * v.abs();
      return Gait(tilt: -facing * 0.12 * v, stretchX: 1 / tall, stretchY: tall);
    }

    final s = math.sin(phase);
    final hop = s.abs();
    // The legs and arms do the stepping (see [miloBends]); the whole figure
    // only bobs and leans a little on top.
    final step = crawling
        ? Gait(lift: 0.4 * hop, stretchX: 1 + 0.05 * s, stretchY: 1 - 0.03 * s)
        : panic
        ? Gait(lift: 4 * hop, tilt: facing * 0.12 + 0.06 * s, stretchY: 1 + 0.04 * hop)
        : carrying
        ? Gait(lift: 1.0 * hop, tilt: 0.05 * s, stretchY: 1 - 0.03 * (1 - hop))
        : sneaking
        ? Gait(lift: 0.6 * hop, tilt: facing * 0.05 + 0.02 * s, stretchY: 0.97 + 0.02 * hop)
        : Gait(lift: 2.2 * hop, tilt: facing * 0.04 + 0.04 * s, stretchY: 1 + 0.03 * hop);

    final moving = (speed / _moving).clamp(0.0, 1.0);
    final gait = lerp(breathe(time), step, moving);

    if (sinceLanding >= _landTime) return gait;
    return gait.squashed(0.3 * landing * (1 - sinceLanding / _landTime));
  }

  /// A jump's speed that stretches him the full amount (the tuning's
  /// `jumpSpeed`).
  static const _topSpeed = 550.0;

  /// Pace in px/s at which he counts as walking, not standing.
  static const _moving = 30.0;

  /// How long a landing's squat lasts, in seconds.
  static const _landTime = 0.2;
}

/// Follows a figure frame by frame to give its [Gait] what it needs: a walk
/// cycle that advances with the ground covered, so feet never skate, its
/// smoothed pace, its vertical speed and the moment it last landed.
class FigureMotion {
  FigureMotion({this.stride = 64});

  /// Pixels of ground for one full cycle (two steps).
  final double stride;

  /// Radians of the walk cycle, ever growing.
  double phase = 0;

  /// Pace in px/s, eased so a stop settles instead of snapping.
  double speed = 0;

  /// Vertical speed in px/s, y down.
  double vy = 0;

  /// Seconds since the figure last came down; huge until it has.
  double sinceLanding = double.maxFinite;

  /// How hard that landing was, 0.3 (a hop) to 1 (a long fall).
  double landing = 0;

  double? _x;
  double? _y;
  bool _grounded = true;
  double _fall = 0;

  /// A move faster than this in px/s is a teleport (a vent, a new room), not a walk.
  static const _teleport = 600.0;

  /// A fall at this speed in px/s lands the hardest.
  static const _hardFall = 600.0;

  void update(double dt, double x, double y, {bool grounded = true}) {
    final fromX = _x;
    final fromY = _y;
    _x = x;
    _y = y;
    if (dt <= 0) return;
    if (fromX != null && fromY != null) {
      final dx = (x - fromX).abs();
      final pace = dx / dt;
      if (pace < _teleport) {
        speed += (pace - speed) * math.min(1, dt * 14);
        phase += dx / stride * 2 * math.pi;
        vy = (y - fromY) / dt;
      } else {
        speed = 0;
        vy = 0;
      }
    }
    sinceLanding = math.min(sinceLanding + dt, double.maxFinite);
    if (!grounded) {
      _fall = math.max(_fall, vy);
    } else {
      if (!_grounded) {
        landing = (_fall / _hardFall).clamp(0.3, 1.0);
        sinceLanding = 0;
      }
      _fall = 0;
    }
    _grounded = grounded;
  }
}

/// [child] bent by [gait], about its feet.
class GaitBox extends StatelessWidget {
  const GaitBox({super.key, required this.gait, required this.child});

  final Gait gait;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Transform(alignment: Alignment.bottomCenter, transform: gait.matrix, child: child);
}

/// The limbs of Milo for one frame: legs that swing and lift in turn, arms
/// that swing against them, a head that lags the body. [sneaking] tiptoes
/// with small steps; a walk strides and swings; carrying keeps the arms up
/// over the loot and strains; a panic flails; a crawl moves the limbs in
/// diagonal pairs. In the air the legs tuck and the arms fly out; on a
/// mantle they scramble.
///
/// [phase] and [speed] come from his [FigureMotion], [vy] is y down, [time]
/// is the night's clock. With no motion at all every bend is zero (the head
/// breathes), and the parts draw the canvas art.
Map<String, Bend> miloBends(
  BurglarPose pose, {
  required double phase,
  required double speed,
  required double vy,
  required bool grounded,
  required double time,
  bool sneaking = false,
  bool mantling = false,
}) {
  final move = (speed / 30).clamp(0.0, 1.0);
  final s = math.sin(phase);
  final c = math.cos(phase);
  final breath = math.sin(2 * math.pi * time / 2.6);
  final crawl = pose == BurglarPose.crawl;
  final carry = pose == BurglarPose.carry;
  final panic = pose == BurglarPose.panic;

  // Swing of each leg in radians, how far a lifted foot rises, and the arms' swing.
  final (legSwing, lift, armSwing) = crawl
      ? (0.4, 3.0, 0.5)
      : panic
      ? (0.75, 7.0, 0.6)
      : carry
      ? (0.3, 2.5, 0.0)
      : sneaking
      ? (0.3, 3.5, 0.2)
      : (0.55, 5.0, 0.45);

  var legA = Bend(angle: -legSwing * s * move, dy: -math.max(0.0, c) * lift * move);
  var legB = Bend(angle: legSwing * s * move, dy: -math.max(0.0, -c) * lift * move);
  // Each arm swings with the opposite leg (in a crawl, diagonal pairs).
  var armA = Bend(angle: armSwing * s * move);
  var armB = Bend(angle: -armSwing * s * move);
  var head = Bend(angle: -0.05 * s * move + 0.015 * math.sin(time * 1.3), dy: 0.9 * s.abs() * move + 0.5 * breath);
  var body = Bend(angle: 0.04 * s * move, dy: 0.4 * breath);

  if (carry) {
    // Straining under the weight: the arms shake and the whole body sinks with each step.
    armA = Bend(angle: 0.035 * math.sin(time * 9));
    armB = Bend(angle: 0.035 * math.sin(time * 9.7));
    body = Bend(angle: 0.05 * s * move, dy: 1.2 * s.abs() * move);
    head = Bend(angle: -0.04 * s * move, dy: 1.2 * s.abs() * move + 0.5 * breath);
  }
  if (panic) {
    // Arms never stop flailing, even when he is cornered.
    final flail = 0.18 * math.sin(time * 19);
    armA = Bend(angle: armA.angle + flail);
    armB = Bend(angle: armB.angle - flail);
    head = Bend(angle: head.angle + 0.04 * math.sin(time * 23), dy: head.dy);
  }

  if (mantling) {
    final k = math.sin(time * 16);
    legA = Bend(angle: -0.7 + 0.45 * k, dy: -3);
    legB = Bend(angle: 0.3 - 0.45 * k, dy: -1);
    armA = Bend(angle: -0.5 + 0.2 * k);
    armB = Bend(angle: 0.5 - 0.2 * k);
  } else if (!grounded) {
    // Rising he tucks a knee and throws his arms wide; falling, he reaches for the ground.
    final v = (vy / 550).clamp(-1.0, 1.0);
    final fall = math.max(v, 0.0);
    legA = Bend(angle: -0.55 + 0.35 * fall, dy: -3 + 3 * fall);
    legB = Bend(angle: 0.45 - 0.2 * fall, dy: -1);
    final out = 0.5 + 0.2 * v.abs();
    if (!carry) {
      armA = Bend(angle: -out);
      armB = Bend(angle: out);
    }
    head = Bend(angle: -0.05 * v);
  }

  return {'legA': legA, 'legB': legB, 'armA': armA, 'armB': armB, 'head': head, 'body': body};
}
