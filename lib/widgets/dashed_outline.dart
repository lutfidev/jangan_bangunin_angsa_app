import 'package:flutter/widgets.dart';

/// A dashed rounded-rect or oval outline, for hint rings and "nearby" slots.
class DashedOutline extends StatelessWidget {
  const DashedOutline({
    super.key,
    required this.color,
    this.strokeWidth = 3,
    this.radius = 0,
    this.oval = false,
    this.dash = 9,
    this.gap = 6,
    this.fill,
    this.child,
  });

  final Color color;
  final double strokeWidth;
  final double radius;
  final bool oval;
  final double dash;
  final double gap;
  final Color? fill;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedPainter(this),
      child: child ?? const SizedBox.expand(),
    );
  }
}

class _DashedPainter extends CustomPainter {
  _DashedPainter(this.spec);

  final DashedOutline spec;

  @override
  void paint(Canvas canvas, Size size) {
    // The stroke sits inside the box, like a CSS border.
    final inset = spec.strokeWidth / 2;
    final rect = (Offset.zero & size).deflate(inset);
    final path = spec.oval
        ? (Path()..addOval(rect))
        : (Path()..addRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(spec.radius - inset)),
          ));
    if (spec.fill != null) {
      canvas.drawPath(path, Paint()..color = spec.fill!);
    }
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = spec.strokeWidth
      ..color = spec.color;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += spec.dash + spec.gap) {
        canvas.drawPath(metric.extractPath(d, d + spec.dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter oldDelegate) =>
      oldDelegate.spec != spec;
}
