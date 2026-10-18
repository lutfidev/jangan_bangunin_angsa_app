import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/widgets/joystick.dart';

import 'helpers.dart';

void main() {
  late List<double> values;

  Future<TestGesture> press(WidgetTester tester) async {
    values = [];
    useStageSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [Positioned(left: 0, top: 286, child: Joystick(onChanged: values.add))],
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
    expect(values.last, 1.0);
    expect(knob(tester), const Offset(54 + 24, 28));
  });

  testWidgets('a small wobble is ignored', (tester) async {
    final g = await press(tester);
    await g.moveBy(const Offset(2, 0));
    await tester.pump();
    expect(values.where((v) => v != 0), isEmpty);
  });

  testWidgets('half a push is half speed', (tester) async {
    final g = await press(tester);
    await g.moveBy(const Offset(-12, 0));
    await tester.pump();
    expect(values.last, -0.5);
  });

  testWidgets('release reports zero and recentres the knob', (tester) async {
    final g = await press(tester);
    await g.moveBy(const Offset(30, 0));
    await tester.pump();
    await g.up();
    await tester.pump();
    expect(values.last, 0);
    expect(knob(tester), const Offset(54, 28));
  });

  testWidgets('a cancelled drag reports zero', (tester) async {
    final g = await press(tester);
    await g.moveBy(const Offset(30, 0));
    await tester.pump();
    await g.cancel();
    await tester.pump();
    expect(values.last, 0);
  });

  testWidgets('vertical drags do nothing', (tester) async {
    final g = await press(tester);
    await g.moveBy(const Offset(0, 30));
    await tester.pump();
    expect(values.where((v) => v != 0), isEmpty);
    expect(knob(tester), const Offset(54, 28));
  });
}
