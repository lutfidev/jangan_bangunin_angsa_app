import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/art/art.dart';
import 'package:jangan_bangunin_angsa_app/art/motion.dart';

import 'helpers.dart';

/// The bend the screen puts on the figure of type [T] right now.
Gait _gaitOf<T>(WidgetTester tester) =>
    tester.widget<GaitBox>(find.ancestor(of: find.byType(T), matching: find.byType(GaitBox))).gait;

void main() {
  testWidgets('Milo hops as he walks and breathes when he stops', (tester) async {
    final sim = await pumpGameplay(tester);
    sim.setSneak(false);
    sim.setMove(1);

    var tallest = 0.0;
    for (var i = 0; i < 40; i++) {
      await play(tester, 1 / 60);
      tallest = tallest < _gaitOf<Burglar>(tester).lift ? _gaitOf<Burglar>(tester).lift : tallest;
    }
    expect(tallest, greaterThan(2), reason: 'a walking step leaves the floor');

    sim.setMove(0);
    await play(tester, 1.5);
    expect(_gaitOf<Burglar>(tester).lift, closeTo(0, 0.2));
  });

  testWidgets('he squats when he lands from a jump', (tester) async {
    final sim = await pumpGameplay(tester);
    sim.jump();

    var squat = 1.0;
    for (var i = 0; i < 90; i++) {
      await play(tester, 1 / 60);
      final g = _gaitOf<Burglar>(tester);
      squat = squat < g.stretchY ? squat : g.stretchY;
    }
    expect(squat, lessThan(0.95));
  });

  testWidgets('Gertrude breathes in her nest', (tester) async {
    await pumpGameplay(tester);
    final heights = <double>{};
    for (var i = 0; i < 60; i++) {
      await play(tester, 1 / 20);
      heights.add(_gaitOf<Goose>(tester).stretchY);
    }
    expect(heights.length, greaterThan(10));
  });
}
