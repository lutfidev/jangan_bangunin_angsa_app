import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/geom.dart';
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
    expect(const Noise(x: 113, loudness: 2).touchesEar(const Vec(502, 270), t), isFalse); // 113 + 72 = 185
    expect(const Noise(x: 667, loudness: 3).touchesEar(const Vec(502, 270), t), isTrue); // inside
    expect(const Noise(x: 250, loudness: 3).touchesEar(const Vec(502, 270), t), isTrue); // 250 + 108 = 358
    expect(const Noise(x: 300, loudness: 0).touchesEar(const Vec(502, 270), t), isFalse); // 300 + 18 = 318
    expect(const Noise(x: 760, loudness: 3).touchesEar(const Vec(502, 270), t), isTrue); // 760 - 108 = 652
  });

  test('on the floor line the ellipse matches the old ear zone', () {
    for (var loudness = 0; loudness <= 3; loudness++) {
      final r = Noise(x: 0, loudness: loudness).radius(t);
      for (final side in [-1, 1]) {
        expect(Noise(x: 502 + side * (172 + r), loudness: loudness).touchesEar(const Vec(502, 270), t), isTrue);
        expect(Noise(x: 502 + side * (173 + r), loudness: loudness).touchesEar(const Vec(502, 270), t), isFalse);
      }
    }
  });

  test('up high the ear zone is far away', () {
    // The kazoo on the crawl plank, right over her.
    expect(const Noise(x: 502, y: 106, loudness: 3).touchesEar(const Vec(502, 270), t), isFalse);
    // A small thump on a side table near her is heard; at counter height
    // it is already above the ellipse.
    expect(const Noise(x: 602, y: 236, loudness: 1).touchesEar(const Vec(502, 270), t), isTrue);
    expect(const Noise(x: 602, y: 200, loudness: 1).touchesEar(const Vec(502, 270), t), isFalse);
    // Landing on the high shelf.
    expect(const Noise(x: 350, y: 160, loudness: 1).touchesEar(const Vec(502, 270), t), isFalse);
  });

  test('with no height it sounds on the floor she stands on', () {
    expect(const Noise(x: 502, loudness: 1).touchesEar(const Vec(502, 200), t), isTrue);
    expect(const Noise(x: 502, y: 270, loudness: 0).touchesEar(const Vec(502, 200), t), isFalse);
  });
}
