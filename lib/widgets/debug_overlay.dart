import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/geom.dart';
import '../game/hearing.dart';
import '../game/nav.dart';
import '../game/night_sim.dart';
import '../theme/type.dart';

/// What the sim knows, painted over the room layer for playtesting (debug
/// builds only): rooms, solids, furniture tops she can and can't stand on,
/// stairs, vents, her nav graph and route, the portals sound crosses and
/// what each costs, Milo's body, and the last noise's way to her.
class DebugOverlay extends StatelessWidget {
  const DebugOverlay({super.key, required this.sim, this.lastNoise});

  final NightSim sim;

  /// The last noise that went off, to draw its way to her.
  final NoiseMade? lastNoise;

  @override
  Widget build(BuildContext context) =>
      IgnorePointer(child: CustomPaint(size: Size.infinite, painter: _DebugPainter(sim, lastNoise)));
}

class _DebugPainter extends CustomPainter {
  _DebugPainter(this.sim, this.lastNoise);

  final NightSim sim;
  final NoiseMade? lastNoise;

  static const _room = Color(0xFFFFFFFF);
  static const _solid = Color(0xFFFF4D4D);
  static const _stands = Color(0xFF40E0FF);
  static const _safe = Color(0xFFFF40FF);
  static const _stair = Color(0xFF40FF80);
  static const _vent = Color(0xFFB080FF);
  static const _flap = Color(0xFFFF9A40);
  static const _route = Color(0xFFFFC14D);

  Paint _stroke(Color c, double w, {double alpha = 1}) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..color = c.withValues(alpha: alpha);

  void _label(Canvas canvas, String text, Offset at, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: ui(10, weight: FontWeight.w700, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.drawRect((at & tp.size).inflate(2), Paint()..color = const Color(0xB0000000));
    tp.paint(canvas, at);
  }

  Offset _o(Vec v) => Offset(v.x, v.y);

  @override
  void paint(Canvas canvas, Size size) {
    final level = sim.level;

    for (final r in level.rooms) {
      canvas.drawRect(Rect.fromLTRB(r.box.left, r.box.top, r.box.right, r.box.bottom), _stroke(_room, 1, alpha: 0.6));
      _label(canvas, '${r.id} · floor ${r.floorY.round()}', Offset(r.box.left + 4, r.box.top + 4), _room);
    }
    for (final s in level.geometry.solids) {
      final b = s.box;
      if (b.right < 0 || b.left > level.width) continue;
      canvas.drawRect(Rect.fromLTRB(b.left, math.max(b.top, -2), b.right, math.min(b.bottom, level.height + 2)), _stroke(_solid, 1.5));
    }
    for (final p in level.geometry.platforms) {
      final stands = sim.nav.standable(p);
      canvas.drawLine(Offset(p.from, p.y), Offset(p.to, p.y), _stroke(stands ? _stands : _safe, 3));
      _label(canvas, '${p.id}${p.crawl ? ' crawl' : ''}', Offset(p.from, p.y - 14), stands ? _stands : _safe);
    }
    for (final s in level.stairs) {
      canvas.drawLine(_o(s.bottom), _o(s.top), _stroke(_stair, 2));
    }
    for (final v in level.vents) {
      canvas.drawLine(_o(v.from), _o(v.to), _stroke(_vent, 2));
    }

    // Her nav graph: flaps as lines, doorways and stair ends as dots.
    for (final l in sim.nav.links) {
      final a = l.a.at(l.xa);
      final b = l.b.at(l.xb);
      if (l.kind == LinkKind.flap) {
        canvas.drawLine(_o(a), _o(b), _stroke(_flap, 2));
      } else {
        canvas.drawCircle(_o(a), 4, Paint()..color = l.kind == LinkKind.door ? _route : _stair);
      }
    }
    final route = sim.goose.route;
    if (route != null) {
      final path = Path()..moveTo(route.points.first.x, route.points.first.y - 4);
      for (final p in route.points.skip(1)) {
        path.lineTo(p.x, p.y - 4);
      }
      canvas
        ..drawPath(path, _stroke(_route, 3))
        ..drawCircle(Offset(route.goal.x, route.goal.y - 4), 7, _stroke(route.catches ? _route : _safe, 3));
    }

    // Sound: what each portal takes off.
    final t = sim.tuning;
    for (final p in sim.hearing.portals) {
      final cost = switch (p.kind) {
        PortalKind.door => sim.doors.isOpen(p.id) ? 0 : t.closedDoorMuffle,
        PortalKind.stairs => t.stairMuffle,
        PortalKind.vent => 0,
        PortalKind.floor => t.floorMuffle,
      };
      final at = switch (p.kind) {
        PortalKind.door => level.doors.firstWhere((d) => d.id == p.id).handle,
        PortalKind.stairs => level.stairs.firstWhere((s) => s.id == p.id).top,
        PortalKind.vent => level.vents.firstWhere((v) => v.id == p.id).from,
        PortalKind.floor => () {
          final a = level.rooms.firstWhere((r) => r.id == p.a).box;
          final b = level.rooms.firstWhere((r) => r.id == p.b).box;
          return Vec((math.max(a.left, b.left) + math.min(a.right, b.right)) / 2, a.bottom);
        }(),
      };
      _label(canvas, '${p.kind.name} −$cost', Offset(at.x - 20, at.y + 18), _vent);
    }
    final heard = lastNoise?.heard;
    if (lastNoise case final n?) {
      final from = Offset(n.noise.x, n.noise.y ?? level.floorY);
      canvas.drawCircle(from, n.noise.radius(t), _stroke(_route, 1.5, alpha: 0.7));
      if (heard != null && heard.muffled) {
        canvas.drawLine(from, Offset(heard.noise.x, heard.noise.y ?? level.floorY), _stroke(_route, 1.5));
      }
      _label(
        canvas,
        heard == null ? 'not heard' : 'heard ${heard.noise.loudness}${n.touchedEar ? ' · ear' : ''}',
        from + const Offset(6, -30),
        _route,
      );
    }

    // Milo's body.
    canvas.drawRect(
      Rect.fromLTRB(sim.playerX - t.bodyWidth / 2, sim.playerY - t.bodyHeight, sim.playerX + t.bodyWidth / 2, sim.playerY),
      _stroke(_room, 1.5),
    );
  }

  @override
  bool shouldRepaint(_DebugPainter old) => true;
}
