import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/noise.dart';
import 'package:jangan_bangunin_angsa_app/game/tuning.dart';

void main() {
  const t = Tuning();

  test('ring radius grows with loudness', () {
    expect(const Noise(x: 0, loudness: 0).radius(t), 18);
    expect(const Noise(x: 0, loudness: 1).radius(t), 36);
    expect(const Noise(x: 0, loudness: 2).radius(t), 72);
  });

  test('ear zone touch is distance to the zone edge', () {
    // Goose at 502 → ear zone 330..674.
    expect(const Noise(x: 113, loudness: 2).touchesEar(502, t), isFalse); // 113 + 72 = 185
    expect(const Noise(x: 667, loudness: 3).touchesEar(502, t), isTrue); // inside
    expect(const Noise(x: 250, loudness: 3).touchesEar(502, t), isTrue); // 250 + 108 = 358
    expect(const Noise(x: 300, loudness: 0).touchesEar(502, t), isFalse); // 300 + 18 = 318
    expect(const Noise(x: 760, loudness: 3).touchesEar(502, t), isTrue); // 760 - 108 = 652
  });
}
