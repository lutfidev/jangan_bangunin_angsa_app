import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../game/geom.dart';
import '../game/goose_brain.dart';
import '../game/hearing.dart';
import '../game/level.dart';
import '../game/night_sim.dart';
import '../game/tools.dart';
import '../game/tuning.dart';
import '../screens/night_art.dart';
import '../screens/scene.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import 'hud.dart';
import 'outlined_text.dart';

/// How long each effect stays on screen, in seconds.
const _ringLife = 0.9;
const _ringGrow = 0.5;
const _wordLife = 0.9;
const _badgeLife = 2.0;
const _honkLife = 1.0;

/// Effects fade out over their last this-many seconds.
const _fade = 0.4;

/// How far above Milo's feet his footsteps and his other noises (squeaks,
/// landings, the kazoo) go off: 262 and 220 on the 270 floor.
const _feetUp = 8.0;
const _handsUp = 50.0;

/// Gertrude's head, and where she slips, above her feet.
const _headUp = 60.0;
const _slipUp = 70.0;

abstract class _Fx {
  _Fx(this.life);

  final double life;
  double age = 0;

  bool get done => age >= life;

  /// 1 while fresh, falling to 0 over the last [_fade] seconds.
  double get opacity => ((life - age) / _fade).clamp(0, 1).toDouble();
}

/// Concentric rings: ring count = loudness, outer radius = how far it carries.
/// [dashed] rings are a noise heard muffled through a door, a stair, a
/// vent or a floor, drawn where she hears it.
class RingFx extends _Fx {
  RingFx(this.center, this.radius, this.circles, this.color, {this.dashed = false}) : super(_ringLife);

  final Offset center;
  final double radius;
  final int circles;
  final Color color;
  final bool dashed;

  /// Rings grow from 40% to full size over their first half second.
  double get scale => 0.4 + 0.6 * (age / _ringGrow).clamp(0, 1);
}

/// A numbered chain-link badge, with the dotted arc from the link before it.
class BadgeFx extends _Fx {
  BadgeFx(this.link, this.at, this.from) : super(_badgeLife);

  final int link;
  final Offset at;
  final Offset? from;
}

/// A comic SFX word over the object that made the noise.
class WordFx extends _Fx {
  WordFx(this.text, this.color, this.at) : super(_wordLife);

  final String text;
  final Color color;
  final Offset at;
}

class HonkFx extends _Fx {
  HonkFx(this.at) : super(_honkLife);

  final Offset at;
}

/// Turns the night's events into short-lived effects for [FxLayer].
class NoiseFx {
  NoiseFx({required this.level, required this.anchors, this.tuning = const Tuning()});

  final Level level;
  final Map<String, Offset> anchors;
  final Tuning tuning;

  final List<RingFx> rings = [];
  final List<BadgeFx> badges = [];
  final List<WordFx> words = [];
  HonkFx? honk;

  /// The last badge of each chain, where the next link's arc starts.
  final Map<int, Offset> _lastLink = {};

  void take(SimEvent e, {required Vec goose}) {
    switch (e) {
      case NoiseMade(:final noise, :final link, :final tool, :final heard, :final door):
        final at = link == null
            ? Offset(noise.x, (noise.y ?? level.floorY) - (noise.loudness == 0 ? _feetUp : _handsUp))
            : anchors[link.spotId]!;
        rings.add(RingFx(at, noise.radius(tuning), math.max(noise.loudness, 1), threatColor(noise.loudness)));
        if (heard case Heard(muffled: true, noise: final muffled)) {
          rings.add(RingFx(
            Offset(muffled.x, (muffled.y ?? level.floorY) - _handsUp),
            muffled.radius(tuning),
            math.max(muffled.loudness, 1),
            threatColor(muffled.loudness),
            dashed: true,
          ));
        }
        if (door != null) words.add(WordFx('creak!', threatColor(noise.loudness), at));
        switch (tool) {
          case Tool.socks:
            words.add(WordFx('flop!', Palette.calmMint, at));
          case Tool.kazoo:
            words.add(WordFx('TOOT!', Palette.alarmTomato, at));
          case _:
        }
        if (link == null) return;
        badges.add(BadgeFx(link.link, at, link.link == 1 ? null : _lastLink[link.chainId]));
        _lastLink[link.chainId] = at;
        final type = level.objects.firstWhere((o) => o.id == link.objectId).type;
        words.add(WordFx(sfxWord(type), threatColor(noise.loudness), at));
      case GooseChanged(to: GooseState.awake):
        honk = HonkFx(Offset(goose.x, goose.y - _headUp));
      case GooseSlipped(:final at):
        words.add(WordFx('SLIP!', Palette.lamp, Offset(at.x, at.y - _slipUp)));
      case _:
    }
  }

  void advance(double dt) {
    for (final list in <List<_Fx>>[rings, badges, words]) {
      for (final fx in list) {
        fx.age += dt;
      }
      list.removeWhere((fx) => fx.done);
    }
    honk?.age += dt;
    if (honk?.done ?? false) honk = null;
  }
}

/// Draws [NoiseFx] over the scene: rings and arcs, then badges and words.
class FxLayer extends StatelessWidget {
  const FxLayer({super.key, required this.fx});

  final NoiseFx fx;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: CustomPaint(painter: _FxPainter(fx))),
          for (final b in fx.badges)
            at(
              b.at.dx - 12,
              b.at.dy - 52,
              Opacity(
                opacity: b.opacity,
                child: Unmirror(
                  child: LinkBadge(b.link, color: linkColor(b.link), textColor: linkTextColor(b.link), size: 24),
                ),
              ),
            ),
          for (final w in fx.words)
            at(
              w.at.dx - 24,
              w.at.dy - 80,
              Opacity(
                opacity: w.opacity,
                child: Unmirror(
                  child: Transform.rotate(
                    angle: deg(-6),
                    child: OutlinedText(w.text, style: display(18, color: w.color, height: 1), stroke: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FxPainter extends CustomPainter {
  _FxPainter(this.fx);

  final NoiseFx fx;

  // Per circle, inner to outer (Noise Chain Reaction, panel 04).
  static const _strokes = [3.0, 3.0, 2.5];
  static const _alphas = [1.0, 0.6, 0.35];

  @override
  void paint(Canvas canvas, Size size) {
    for (final r in fx.rings) {
      for (var i = 0; i < r.circles; i++) {
        final radius = r.radius * r.scale * (i + 1) / r.circles;
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r.dashed ? 2.5 : _strokes[i]
          ..color = r.color.withValues(alpha: _alphas[i] * r.opacity * (r.dashed ? 0.8 : 1));
        if (r.dashed) {
          _dashedCircle(canvas, r.center, radius, paint);
        } else {
          canvas.drawCircle(r.center, radius, paint);
        }
      }
    }
    for (final b in fx.badges) {
      if (b.from != null) _arc(canvas, b.from!, b.at, linkColor(b.link), b.opacity);
    }
  }

  /// A circle dashed 6 on, 5 off, like the board's muffled ring.
  void _dashedCircle(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    for (final PathMetric m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 11) {
        canvas.drawPath(m.extractPath(d, math.min(d + 6, m.length)), paint);
      }
    }
  }

  /// A dotted arc from cause to effect, with a small white arrowhead.
  void _arc(Canvas canvas, Offset from, Offset to, Color color, double opacity) {
    final mid = Offset((from.dx + to.dx) / 2, math.min(from.dy, to.dy) - 34);
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, to.dx, to.dy);
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: opacity);
    for (final PathMetric m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 9) {
        canvas.drawPath(m.extractPath(d, math.min(d + 4, m.length)), dash);
      }
    }
    final head = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = Palette.gooseWhite.withValues(alpha: opacity);
    final back = (mid - to).direction;
    for (final spread in [-0.5, 0.5]) {
      canvas.drawLine(to, to + Offset.fromDirection(back + spread, 9), head);
    }
  }

  @override
  bool shouldRepaint(_FxPainter oldDelegate) => true;
}
