import 'dart:math' as math;

import 'tuning.dart';

/// The alert meter's named bands from the Noise Chain Reaction board.
enum MeterBand { snoozing, stirring, suspicious, danger, awake }

/// How close Gertrude is to waking, 0..100. The caller decides whether a
/// noise reached her ear zone; the meter only counts what it is told.
class NoiseMeter {
  NoiseMeter(this.tuning);

  final Tuning tuning;

  double _value = 0;
  double _quiet = 0;

  /// Seconds left of "wakes 2× easier".
  double drowsyLeft = 0;

  double get value => _value;

  MeterBand get band => switch (_value) {
    >= 100 => MeterBand.awake,
    >= 80 => MeterBand.danger,
    >= 50 => MeterBand.suspicious,
    >= 25 => MeterBand.stirring,
    _ => MeterBand.snoozing,
  };

  /// A noise of [loudness] 0..3 that touched the ear zone.
  void hear(int loudness) {
    final gain = switch (loudness) {
      0 => tuning.meterStep,
      1 => tuning.meterSmall,
      2 => tuning.meterMedium,
      _ => tuning.meterLoud,
    };
    _value = math.min(100, _value + gain * (drowsyLeft > 0 ? tuning.drowsyGain : 1));
    _quiet = 0;
  }

  void tick(double dt) {
    final before = _quiet;
    _quiet += dt;
    final draining = _quiet - math.max(before, tuning.quietBeforeDrain);
    if (draining > 0) {
      _value = math.max(0, _value - draining * tuning.drainPerSecond);
    }
    drowsyLeft = math.max(0, drowsyLeft - dt);
  }

  void reset({double value = 0}) {
    _value = value;
    _quiet = 0;
  }
}
