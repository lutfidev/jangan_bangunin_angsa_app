import 'package:flutter/material.dart';

/// Every screen is laid out on the design's 844×390 landscape artboard and
/// scaled to fit the device, letterboxed in the screen's ground colour.
class Stage extends StatelessWidget {
  const Stage({super.key, required this.background, required this.children});

  static const width = 844.0;
  static const height = 390.0;

  final Color background;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Center(
        child: FittedBox(
          child: SizedBox(
            width: width,
            height: height,
            child: ClipRect(child: Stack(children: children)),
          ),
        ),
      ),
    );
  }
}

/// A flat coloured block, used for walls, floors and furniture.
class Block extends StatelessWidget {
  const Block({
    super.key,
    required this.color,
    this.border,
    this.radius,
    this.opacity = 1,
  });

  final Color color;
  final BoxBorder? border;
  final BorderRadius? radius;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        border: border,
        borderRadius: radius,
      ),
    );
    return opacity == 1 ? box : Opacity(opacity: opacity, child: box);
  }
}
