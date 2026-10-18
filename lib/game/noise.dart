import 'tuning.dart';

/// One sound at a spot on the floor line. Ring count = loudness:
/// 0 a footstep's tiny ring, 1 small, 2 medium, 3 loud.
class Noise {
  const Noise({required this.x, required this.loudness});

  final double x;
  final int loudness;

  double radius(Tuning t) => loudness == 0 ? t.footstepRadius : loudness * t.ringRadius;

  /// Whether the outer ring reaches the ear zone around a goose at [gooseX].
  /// Only rings that touch it raise the meter.
  bool touchesEar(double gooseX, Tuning t) {
    final left = gooseX - t.earHalfWidth;
    final right = gooseX + t.earHalfWidth;
    final gap = x < left ? left - x : (x > right ? x - right : 0.0);
    return gap <= radius(t);
  }

  @override
  String toString() => 'Noise(x: $x, loudness: $loudness)';
}
