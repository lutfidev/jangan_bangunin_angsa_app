import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/level.dart';

import 'fixtures.dart';

/// The whole message, so a short id like 'a' can't match by accident.
Matcher _formatError(String message) =>
    throwsA(isA<FormatException>().having((e) => e.message, 'message', message));

void main() {
  test('night 3 parses', () {
    final l = night3();
    expect(l.name, 'The Midnight Kitchen');
    expect(l.spots, hasLength(8));
    expect(l.spots['counterPot']!.snap, isTrue);
    expect(l.objects.firstWhere((o) => o.id == 'pot').portable, isTrue);
    expect(l.objects.firstWhere((o) => o.id == 'clock').type, ObjectType.chimer);
    expect(l.linksFrom('sideTable').map((k) => k.to), ['underSideTable', 'clockStand']);
    expect(l.links.first.delay, 0.4);
    expect(l.loot.singleWhere((x) => x.guarded).id, 'egg');
    expect(l.loot.firstWhere((x) => x.id == 'chicken').squeaks, isTrue);
    expect(l.hideSpots, [180, 720]);
  });

  test('rejects a link to an unknown spot', () {
    expect(() => Level.parse(minimalLevel(links: [{'from': 'a', 'to': 'nope'}])), _formatError('link names an unknown spot: nope'));
  });

  test('rejects an object on an unknown spot', () {
    expect(
      () => Level.parse(minimalLevel(objects: [{'id': 'o', 'type': 'tipper', 'spot': 'ghost'}])),
      _formatError('object o names an unknown spot: ghost'),
    );
  });

  test('rejects two objects on one spot', () {
    expect(
      () => Level.parse(minimalLevel(objects: [
        {'id': 'o1', 'type': 'tipper', 'spot': 'a'},
        {'id': 'o2', 'type': 'chimer', 'spot': 'a'},
      ])),
      _formatError('two objects on spot: a'),
    );
  });

  test('rejects more than one guarded loot', () {
    expect(
      () => Level.parse(minimalLevel(loot: [
        {'id': 'egg', 'x': 1, 'guarded': true},
        {'id': 'crown', 'x': 2, 'guarded': true},
      ])),
      _formatError('more than one guarded loot: crown'),
    );
  });

  test('rejects a duplicate id', () {
    expect(
      () => Level.parse(minimalLevel(spots: [{'id': 'a', 'x': 1}, {'id': 'a', 'x': 2}])),
      _formatError('duplicate spot: a'),
    );
  });

  test('rejects an unknown object type', () {
    expect(
      () => Level.parse(minimalLevel(objects: [{'id': 'o', 'type': 'trebuchet', 'spot': 'a'}])),
      _formatError('unknown object type: trebuchet'),
    );
  });
}
