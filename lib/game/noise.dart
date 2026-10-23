import 'geom.dart';
import 'tuning.dart';

/// One sound at a point in the room. Ring count = loudness:
/// 0 a footstep's tiny ring, 1 small, 2 medium, 3 loud.
class Noise {
  const Noise({required this.x, this.y, required this.loudness});

  final double x;

  /// Where it went off up the room; null is on the floor line she stands
  /// on. Chain objects are heard from the floor, where things clatter down.
  final double? y;
  final int loudness;

  double radius(Tuning t) => loudness == 0 ? t.footstepRadius : loudness * t.ringRadius;

  /// Whether the outer ring reaches the ear zone around a goose standing
  /// at [ear]: the dashed ellipse, grown by the ring's radius. Only rings
  /// that touch it raise the meter.
  bool touchesEar(Vec ear, Tuning t) {
    final r = radius(t);
    return insideEllipse(Vec(x, y ?? ear.y), ear, t.earHalfWidth + r, t.earHalfHeight + r);
  }

  @override
  String toString() => 'Noise(x: $x, y: $y, loudness: $loudness)';
}
