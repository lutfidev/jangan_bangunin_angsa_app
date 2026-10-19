import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/heist.dart';
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
    expect(l.hideSpots, [148, 703]);
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

  test('night 3 has the crawlway and the chicken up on it', () {
    final l = night3();
    expect(l.crawlway!.from, 250);
    expect(l.crawlway!.to, 420);
    expect(l.loot.firstWhere((x) => x.id == 'chicken').high, isTrue);
    expect(l.loot.firstWhere((x) => x.id == 'toaster').high, isFalse);
  });

  test('a level without a crawlway has none', () {
    expect(Level.parse(minimalLevel()).crawlway, isNull);
  });

  test('rejects a crawlway that runs backwards', () {
    expect(
      () => Level.parse(minimalLevel(crawlway: {'from': 420, 'to': 250})),
      _formatError('crawlway runs backwards: test'),
    );
  });

  test('rejects high loot off the crawlway', () {
    final cup = {'id': 'cup', 'x': 500, 'high': true};
    expect(
      () => Level.parse(minimalLevel(crawlway: {'from': 0, 'to': 100}, loot: [cup])),
      _formatError('high loot off the crawlway: cup'),
    );
    expect(() => Level.parse(minimalLevel(loot: [cup])), _formatError('high loot off the crawlway: cup'));
  });

  test('night 3 has a goal per style', () {
    final goals = night3().goals;
    expect(goals.map((g) => g.style), [PlayStyle.ghost, PlayStyle.trickster, PlayStyle.chaos]);
    expect(goals.map((g) => g.kind), [GoalKind.neverSuspicious, GoalKind.lure, GoalKind.chain]);
    expect(goals.map((g) => g.count), [1, 2, 5]);
  });

  test('goals are optional', () {
    expect(Level.parse(minimalLevel()).goals, isEmpty);
  });

  test('rejects bad goals', () {
    Level parse(List<Object?> goals) => Level.parse(minimalLevel(goals: goals));
    expect(() => parse([{'style': 'sneaky', 'kind': 'lure'}]), _formatError('unknown goal style: sneaky'));
    expect(() => parse([{'style': 'ghost', 'kind': 'nap'}]), _formatError('unknown goal kind: nap'));
    expect(
      () => parse([{'style': 'ghost', 'kind': 'neverSuspicious'}, {'style': 'ghost', 'kind': 'lure'}]),
      _formatError('duplicate goal style: ghost'),
    );
    expect(() => parse([{'style': 'chaos', 'kind': 'chain', 'count': 0}]), _formatError('goal count below 1: chaos'));
  });
}
