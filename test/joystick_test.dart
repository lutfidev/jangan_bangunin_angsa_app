import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/tuning.dart';
import 'package:jangan_bangunin_angsa_app/widgets/joystick.dart';

import 'helpers.dart';

void main() {
  late List<(double, double)> values;

  Future<TestGesture> press(WidgetTester tester, {bool hintUp = false, bool hintDown = false}) async {
    values = [];
    useStageSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            Positioned(
              left: 0,
              top: 286,
              child: Joystick(onChanged: (x, y) => values.add((x, y)), hintUp: hintUp, hintDown: hintDown),
            ),
          ],
        ),
      ),
    );
    return tester.startGesture(tester.getCenter(find.byType(Joystick)));
  }

  Offset knob(WidgetTester tester) =>
      tester.getTopLeft(find.byKey(Joystick.knobKey)) - tester.getTopLeft(find.byType(Joystick));

  testWidgets('dragging right reports full right', (tester) async {
    final g = await press(tester);
    await g.moveBy(const Offset(30, 0));
    await tester.pump();
    expect(values.last, (1.0, 0.0));
    expect(knob(tester), const Offset(54 + 24, 28));
  });

  testWidgets('a small wobble is ignored', (tester) async {
    final g = await press(tester);
    await g.moveBy(const Offset(2, 0));
    await tester.pump();
    expect(values, isEmpty);
  });

  testWidgets('half a push is half speed', (tester) async {
    final g = await press(tester);
    await g.moveBy(const Offset(-12, 0));
    await tester.pump();
    expect(values.last, (-0.5, 0.0));
  });

  testWidgets('release reports zero and recentres the knob', (tester) async {
    final g = await press(tester);
    await g.moveBy(const Offset(30, 0));
    await tester.pump();
    await g.up();
    await tester.pump();
    expect(values.last, (0.0, 0.0));
    expect(knob(tester), const Offset(54, 28));
  });

  testWidgets('a cancelled drag reports zero', (tester) async {
    final g = await press(tester);
    await g.moveBy(const Offset(30, 0));
    await tester.pump();
    await g.cancel();
    await tester.pump();
    expect(values.last, (0.0, 0.0));
  });

  testWidgets('a drag up reports up, and moves the knob up', (tester) async {
    final g = await press(tester);
    await g.moveBy(const Offset(0, -30));
    await tester.pump();
    expect(values.last, (0.0, -1.0));
    expect(knob(tester), const Offset(54, 4));
  });

  testWidgets('a drag down reports down', (tester) async {
    final g = await press(tester);
    await g.moveBy(const Offset(0, 30));
    await tester.pump();
    expect(values.last, (0.0, 1.0));
  });

  testWidgets('a small vertical push reports how far', (tester) async {
    final g = await press(tester);
    await g.moveBy(const Offset(0, -12));
    await tester.pump();
    expect(values.last, (0.0, -0.5));
  });

  testWidgets('walking on a slant does not climb', (tester) async {
    final g = await press(tester);
    await g.moveBy(const Offset(30, -10));
    await tester.pump();
    expect(values.last.$1, greaterThan(0.9));
    expect(values.last.$2.abs(), lessThan(const Tuning().verticalThreshold));
    final k = knob(tester) - const Offset(54, 28);
    expect(k.distance, closeTo(24, 0.01));
  });

  testWidgets('hints light the arrows that work', (tester) async {
    await press(tester, hintUp: true);
    expect(find.byKey(Joystick.hintUpKey), findsOneWidget);
    expect(find.byKey(Joystick.hintDownKey), findsNothing);
    await press(tester, hintDown: true);
    expect(find.byKey(Joystick.hintUpKey), findsNothing);
    expect(find.byKey(Joystick.hintDownKey), findsOneWidget);
  });
}
