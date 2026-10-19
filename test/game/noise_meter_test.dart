import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/noise_meter.dart';
import 'package:jangan_bangunin_angsa_app/game/tuning.dart';

void main() {
  test('bands match the design', () {
    final m = NoiseMeter(const Tuning());
    expect(m.band, MeterBand.snoozing);
    m.hear(1);
    expect(m.value, 25);
    expect(m.band, MeterBand.stirring);
    m.hear(1);
    expect(m.band, MeterBand.suspicious); // 50
    m.reset(value: 80);
    expect(m.band, MeterBand.danger);
    m.hear(3);
    expect(m.value, 100); // clamps
    expect(m.band, MeterBand.awake);
  });

  test('drains 10/s only after 2s of quiet', () {
    final m = NoiseMeter(const Tuning())..hear(2); // 50
    m.tick(2.0);
    expect(m.value, 50);
    m.tick(1.0);
    expect(m.value, 40);
    m.tick(10);
    expect(m.value, 0); // clamps
  });

  test('a new noise restarts the quiet timer', () {
    final m = NoiseMeter(const Tuning())..hear(2);
    m.tick(1.5);
    m.hear(0); // 54
    m.tick(1.5);
    expect(m.value, 54);
  });

  test('drowsy doubles gain', () {
    final m = NoiseMeter(const Tuning())..drowsyLeft = 6;
    m.hear(1);
    expect(m.value, 50);
    m.tick(6); // 2s quiet, then 4s × 10 drained → 10; drowsy over
    expect(m.drowsyLeft, 0);
    m.hear(0);
    expect(m.value, 14); // plain +4 again
  });

  test('gain scales every noise', () {
    final m = NoiseMeter(const Tuning(), gain: 1.5)..hear(1);
    expect(m.value, 37.5);
    m
      ..reset()
      ..drowsyLeft = 1
      ..hear(1);
    expect(m.value, 75); // ×2 drowsy, ×1.5 light sleeper
  });
}
