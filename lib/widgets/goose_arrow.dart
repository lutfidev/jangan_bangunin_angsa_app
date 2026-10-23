import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/goose_brain.dart';
import '../theme/palette.dart';
import 'hud.dart';

/// The chip at the screen's edge pointing to Gertrude while she is off
/// screen ("New · House camera & doors" board): her face, and a triangle
/// in her mood's colour pointing out to [left] or right, or up or down when
/// she is on another storey.
class GooseArrow extends StatelessWidget {
  const GooseArrow({super.key, required this.left, this.vertical = 0, required this.state, this.pulse = 0});

  /// Which edge it sits on, pointing out past.
  final bool left;

  /// -1 she is above, 1 below, 0 on this storey.
  final int vertical;
  final GooseState state;

  /// Seconds into the night: it pulses with them while she runs.
  final double pulse;

  /// Moonlight asleep, orange when she's up to something, red once awake.
  static Color colorFor(GooseState s) => switch (s) {
    GooseState.asleep || GooseState.stirring || GooseState.drowsy => Palette.moonlight,
    GooseState.suspicious || GooseState.sleepwalk || GooseState.lostYou => Palette.beakOrange,
    GooseState.awake || GooseState.chase || GooseState.distracted => Palette.alarmTomato,
  };

  @override
  Widget build(BuildContext context) {
    final running = state == GooseState.chase || state == GooseState.distracted;
    final triangle = vertical == 0
        ? CustomPaint(size: const Size(10, 16), painter: _TrianglePainter(colorFor(state), left: left))
        : CustomPaint(size: const Size(16, 10), painter: _TrianglePainter(colorFor(state), left: left, vertical: vertical));
    return Semantics(
      label: switch (vertical) {
        < 0 => 'Gertrude is off screen, above',
        > 0 => 'Gertrude is off screen, below',
        _ => 'Gertrude is off screen to the ${left ? 'left' : 'right'}',
      },
      excludeSemantics: true,
      child: Transform.scale(
        // Like the EXIT sign: ±8% at 1.5 Hz.
        scale: running ? 1 + 0.08 * math.sin(2 * math.pi * 1.5 * pulse) : 1,
        child: Container(
          width: 64,
          height: 44,
          decoration: BoxDecoration(
            color: Palette.night,
            border: Border.all(color: Palette.ink, width: 3),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [BoxShadow(color: Palette.ink, offset: Offset(0, 3))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 4,
            children: left ? [triangle, const GooseFace()] : [const GooseFace(), triangle],
          ),
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter(this.color, {required this.left, this.vertical = 0});

  final Color color;
  final bool left;
  final int vertical;

  @override
  void paint(Canvas canvas, Size size) {
    final path = vertical != 0
        ? (vertical > 0
              ? (Path()
                  ..moveTo(1, 1)
                  ..lineTo(8, 9)
                  ..lineTo(15, 1)
                  ..close())
              : (Path()
                  ..moveTo(1, 9)
                  ..lineTo(8, 1)
                  ..lineTo(15, 9)
                  ..close()))
        : left
        ? (Path()
            ..moveTo(9, 1)
            ..lineTo(1, 8)
            ..lineTo(9, 15)
            ..close())
        : (Path()
            ..moveTo(1, 1)
            ..lineTo(9, 8)
            ..lineTo(1, 15)
            ..close());
    canvas
      ..drawPath(path, Paint()..color = color)
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round
          ..color = Palette.ink,
      );
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color || old.left != left || old.vertical != vertical;
}
