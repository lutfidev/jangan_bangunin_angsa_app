import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// How one limb or body part is bent for a frame: [angle] radians about its
/// pivot (clockwise positive), then shifted by ([dx], [dy]) in art units.
class Bend {
  const Bend({this.angle = 0, this.dx = 0, this.dy = 0});

  static const none = Bend();

  final double angle;
  final double dx;
  final double dy;

  @override
  bool operator ==(Object other) => other is Bend && other.angle == angle && other.dx == dx && other.dy == dy;

  @override
  int get hashCode => Object.hash(angle, dx, dy);
}

/// One part of a character: a piece of the canvas art that moves on its own
/// about [pivot] (a hip, a shoulder, the base of a neck), in art units.
class RigLayer {
  const RigLayer(this.id, this.markup, {this.pivot = Offset.zero, this.wrapped = true});

  /// What the animation calls it: `legA`, `armB`, `head`, `body`, ...
  final String id;

  /// SVG elements, copied from the canvas art.
  final String markup;
  final Offset pivot;

  /// Shares the whole pose's lean (see [RigSpec.leanAngle]); a shadow does not.
  final bool wrapped;
}

/// A character cut into [layers], back to front. Drawn at rest, the layers
/// make the canvas art again, so the poses stay the designer's.
class RigSpec {
  const RigSpec({
    required this.label,
    required this.width,
    required this.height,
    required this.layers,
    this.leanAngle = 0,
    this.leanPivot = Offset.zero,
  });

  final String label;

  /// The art's size in its own units (the SVG viewBox).
  final double width;
  final double height;
  final List<RigLayer> layers;

  /// A pose that is drawn tilted as a whole (the panicking Milo), in radians
  /// about [leanPivot].
  final double leanAngle;
  final Offset leanPivot;

  /// The standalone SVG for one layer, built once per layer: a figure
  /// rebuilds every frame, and flutter_svg caches pictures by this string.
  String svgOf(RigLayer layer) => _svgs[layer] ??=
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${_n(width)} ${_n(height)}">'
      '<g stroke="#1C1A2B" stroke-width="4" stroke-linejoin="round" stroke-linecap="round">${layer.markup}</g>'
      '</svg>';

  static final _svgs = Expando<String>('rig layer svg');

  static String _n(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

/// A [RigSpec] drawn at [width], each layer bent by its entry in [bends].
class RiggedArt extends StatelessWidget {
  const RiggedArt({super.key, required this.spec, required this.bends, required this.width, this.flip = false});

  final RigSpec spec;
  final Map<String, Bend> bends;
  final double width;
  final bool flip;

  @override
  Widget build(BuildContext context) {
    final k = width / spec.width;
    final height = spec.height * k;
    Widget layer(RigLayer l) {
      Widget w = SvgPicture.string(spec.svgOf(l), width: width, height: height, excludeFromSemantics: true);
      final b = bends[l.id] ?? Bend.none;
      if (b != Bend.none) {
        w = Transform(
          origin: Offset(l.pivot.dx * k, l.pivot.dy * k),
          transform: Matrix4.translationValues(b.dx * k, b.dy * k, 0) * Matrix4.rotationZ(b.angle),
          child: w,
        );
      }
      if (l.wrapped && spec.leanAngle != 0) {
        w = Transform(
          origin: Offset(spec.leanPivot.dx * k, spec.leanPivot.dy * k),
          transform: Matrix4.rotationZ(spec.leanAngle),
          child: w,
        );
      }
      return w;
    }

    Widget figure = SizedBox(
      width: width,
      height: height,
      child: Stack(clipBehavior: Clip.none, children: [for (final l in spec.layers) layer(l)]),
    );
    if (flip) figure = Transform.flip(flipX: true, child: figure);
    return Semantics(label: spec.label, image: true, child: figure);
  }
}

/// Degrees to radians for rig data.
double rad(double degrees) => degrees * math.pi / 180;
