import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/art/art.dart';
import 'package:jangan_bangunin_angsa_app/art/rig.dart';
import 'package:jangan_bangunin_angsa_app/art/rigs.dart';

final _key = GlobalKey();

/// [child] drawn on a plain background, as raw pixels.
Future<Uint8List> _pixels(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          key: _key,
          child: ColoredBox(
            color: const Color(0xFF27264A),
            child: Padding(padding: const EdgeInsets.all(20), child: child),
          ),
        ),
      ),
    ),
  );
  // flutter_svg decodes off the frame; give it a few turns.
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump();
  }
  final boundary = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = (await tester.runAsync(() => boundary.toImage(pixelRatio: 2)))!;
  final data = (await tester.runAsync(() => image.toByteData(format: ui.ImageByteFormat.rawRgba)))!;
  return data.buffer.asUint8List();
}

/// The share of pixels that differ visibly between two renders.
double _difference(Uint8List a, Uint8List b) {
  expect(a.length, b.length);
  var different = 0;
  for (var i = 0; i < a.length; i += 4) {
    final d = (a[i] - b[i]).abs() + (a[i + 1] - b[i + 1]).abs() + (a[i + 2] - b[i + 2]).abs();
    if (d > 60) different++;
  }
  return different / (a.length / 4);
}

void main() {
  group('a rig at rest is the canvas art', () {
    for (final pose in miloRigs.keys) {
      testWidgets('Milo, ${pose.name}', (tester) async {
        final whole = await _pixels(tester, Burglar(pose: pose, width: 240));
        final parts = await _pixels(tester, Burglar(pose: pose, width: 240, bends: const {}));
        expect(whole.any((v) => v != whole[0]), isTrue, reason: 'the art drew something');
        expect(_difference(whole, parts), lessThan(0.002));
      });
    }

    for (final mood in gooseRigs.keys) {
      testWidgets('Gertrude, ${mood.name}', (tester) async {
        final whole = await _pixels(tester, Goose(mood: mood, width: 300));
        final parts = await _pixels(tester, Goose(mood: mood, width: 300, bends: const {}));
        expect(whole.any((v) => v != whole[0]), isTrue, reason: 'the art drew something');
        expect(_difference(whole, parts), lessThan(0.002));
      });
    }
  });

  testWidgets('a bent limb moves; the rest stay put', (tester) async {
    final rest = await _pixels(tester, const Burglar(width: 240, bends: {}));
    final bent = await _pixels(tester, Burglar(width: 240, bends: {'legA': Bend(angle: rad(30))}));
    final diff = _difference(rest, bent);
    expect(diff, greaterThan(0.002));
    expect(diff, lessThan(0.08));
  });

  test('every rig has the layers the animation moves', () {
    for (final entry in miloRigs.entries) {
      final ids = [for (final l in entry.value.layers) l.id];
      expect(ids, containsAll(['legA', 'legB', 'body', 'head', 'armA', 'armB']), reason: '${entry.key}');
    }
    for (final entry in gooseRigs.entries) {
      final ids = [for (final l in entry.value.layers) l.id];
      expect(ids, contains('head'), reason: '${entry.key}');
      expect(ids, contains('body'), reason: '${entry.key}');
    }
  });
}
