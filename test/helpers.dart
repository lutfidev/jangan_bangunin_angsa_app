import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/widgets/stage.dart';

/// Sizes the test surface to the design artboard, so screens render at 1:1.
void useStageSurface(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(Stage.width, Stage.height)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Pumps [screen] on its own inside a [MaterialApp].
Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
  useStageSurface(tester);
  await tester.pumpWidget(MaterialApp(home: screen));
  await tester.pumpAndSettle();
}
