import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../art/art.dart';
import '../game/night_sim.dart';
import '../game/tools.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import '../widgets/hud.dart';
import 'night_art.dart';
import 'scene.dart';

/// Where a sock leaves Milo's hand, and the highest its arc may climb.
const _handY = 212.0;

const _handOut = 26.0;
const _topY = 20.0;

/// A sock that misses lands on the floor here.
const _floorY = 262.0;

/// The one parabola every throw follows (Plan View: `M356 212 Q210 40 66 176`).
class ThrowArc {
  const ThrowArc(this.start, this.control, this.end);

  final Offset start;
  final Offset control;
  final Offset end;

  /// The point [t] of the way along, 0 at the hand and 1 where it lands.
  Offset at(double t) {
    final u = 1 - t;
    return start * (u * u) + control * (2 * u * t) + end * (t * t);
  }
}

/// The arc from Milo at [fromX] to [end]: out of the hand on the throwing
/// side, apex over the middle, higher the further it goes. [handY] is
/// where his hand is when he is not on the floor.
ThrowArc throwArc({required double fromX, required Offset end, double handY = _handY}) {
  final start = Offset(fromX + _handOut * (end.dx < fromX ? -1 : 1), handY);
  final control = Offset(
    (start.dx + end.dx) / 2,
    math.max(_topY, handY - 0.6 * (end.dx - start.dx).abs()),
  );
  return ThrowArc(start, control, end);
}

/// Where a sock landing at [landingX] ends up on screen: on the object it
/// would hit, else on the floor.
Offset throwEnd(NightSim sim, double landingX) {
  final target = sim.throwTarget(landingX);
  return target == null ? Offset(landingX, _floorY) : spotAnchors[target]!;
}

/// The dotted aim arc and the crosshair where it lands.
class AimLayer extends StatelessWidget {
  const AimLayer({super.key, required this.arc});

  final ThrowArc arc;

  @override
  Widget build(BuildContext context) =>
      IgnorePointer(child: CustomPaint(size: Size.infinite, painter: _AimPainter(arc)));
}

class _AimPainter extends CustomPainter {
  _AimPainter(this.arc);

  final ThrowArc arc;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(arc.start.dx, arc.start.dy)
      ..quadraticBezierTo(arc.control.dx, arc.control.dy, arc.end.dx, arc.end.dy);
    final dots = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = Palette.lamp;
    // stroke-dasharray="2 9".
    for (final PathMetric m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 11) {
        canvas.drawPath(m.extractPath(d, math.min(d + 2, m.length)), dots);
      }
    }

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = Palette.lamp;
    final c = arc.end;
    canvas.drawCircle(c, 20, ring);
    for (final dir in const [Offset(0, -1), Offset(0, 1), Offset(-1, 0), Offset(1, 0)]) {
      canvas.drawLine(c + dir * 18, c + dir * 26, ring);
    }
  }

  @override
  bool shouldRepaint(_AimPainter old) =>
      old.arc.start != arc.start || old.arc.control != arc.control || old.arc.end != arc.end;
}

/// The "Drag to aim · release to throw" hint, ending beside the Tool button.
Widget aimHint() => const Positioned(
  right: 258,
  top: 324,
  child: _AimHint(),
);

class _AimHint extends StatelessWidget {
  const _AimHint();

  @override
  Widget build(BuildContext context) => Pill(
    'Drag to aim · release to throw',
    color: Palette.night,
    borderColor: Palette.lamp,
    radius: 12,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    textStyle: ui(12, weight: FontWeight.w800, color: Palette.lamp),
  );
}

/// A sock tumbling along [arc], one turn per throw.
Widget flyingSock(Flight flight, ThrowArc arc) {
  final p = arc.at(flight.progress);
  return at(
    p.dx - 11,
    p.dy - 11,
    Transform.rotate(angle: flight.progress * 2 * math.pi, child: const Prop(PropKind.sock, size: 22)),
  );
}

/// The wind-up mouse on the floor, nose the way it walks.
Widget toyMouse(ToyMouse mouse) => at(mouse.x - 15, 240, Prop(PropKind.mouse, size: 30, flip: mouse.dir < 0));

/// Spilled marbles on the floor (the Chaos escape board's three).
List<Widget> marbleSpill(double x) => [
  for (final (dx, dy, size, color) in const [
    (-6.0, 252.0, 12.0, Palette.calmMint),
    (10.0, 258.0, 10.0, Palette.moonlight),
    (-22.0, 258.0, 10.0, Palette.lamp),
  ])
    box(x + dx, dy, size, size, color, border: 2, oval: true),
];
