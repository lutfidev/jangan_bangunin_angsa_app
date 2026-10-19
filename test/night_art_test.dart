import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/geom.dart';
import 'package:jangan_bangunin_angsa_app/art/art.dart';
import 'package:jangan_bangunin_angsa_app/game/chain.dart';
import 'package:jangan_bangunin_angsa_app/game/goose_brain.dart';
import 'package:jangan_bangunin_angsa_app/game/night_sim.dart';
import 'package:jangan_bangunin_angsa_app/game/noise.dart';
import 'package:jangan_bangunin_angsa_app/screens/night3_set.dart';
import 'package:jangan_bangunin_angsa_app/screens/night_art.dart';
import 'package:jangan_bangunin_angsa_app/state/levels.dart';

NightResult _caughtBy(List<String> objects, {WakeCause cause = WakeCause.noise}) {
  final level = Levels.night3;
  final chain = [
    for (final (i, id) in objects.indexed)
      LinkFired(
        chainId: 1,
        link: i + 1,
        objectId: id,
        spotId: level.objects.firstWhere((o) => o.id == id).spot,
        noise: const Noise(x: 0, loudness: 1),
      ),
  ];
  return NightResult(
    level: level,
    outcome: Outcome.caught,
    loot: const [],
    wakeChain: chain,
    wakeCause: cause,
    time: 10,
  );
}

void main() {
  test('the crawlway plank covers the level crawlway', () {
    final crawl = Levels.night3.crawlway!;
    expect(crawlwayArt.left, lessThanOrEqualTo(crawl.from));
    expect(crawlwayArt.right, greaterThanOrEqualTo(crawl.to));
  });

  test('every hide spot has art', () {
    for (final Vec(:x) in Levels.night3.hideSpots) {
      expect(hideArt[x], isNotNull, reason: '$x');
    }
    expect(hideArt[148]!.crack, isNotNull);
    expect(hideArt[703]!.crack, isNull);
  });

  test('every Night 3 spot has an anchor on its x', () {
    for (final spot in Levels.night3.spots.values) {
      expect(spotAnchors[spot.id]?.dx, spot.x, reason: spot.id);
    }
  });

  test('every loot has art centred on its x', () {
    for (final loot in Levels.night3.loot) {
      expect(lootBox(loot).centerX, loot.x, reason: loot.id);
    }
  });

  test('every remix spot has art', () {
    final level = Levels.night3;
    for (final loot in level.loot) {
      for (final x in [loot.x, ...?level.remixLoot[loot.id]?.map((p) => p.x)]) {
        expect(lootTops[loot.id]?[x], isNotNull, reason: '${loot.id} at $x');
      }
    }
    for (final MapEntry(key: id, value: spots) in level.remixSpots.entries) {
      for (final spotId in spots) {
        expect(snapAnchors[spotId], isNotNull, reason: '$id on $spotId');
      }
    }
  });

  testWidgets('every object has an icon', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(children: [for (final o in Levels.night3.objects) objectIcon(o.id)]),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  test('every goose state has a mood', () {
    for (final s in GooseState.values) {
      expect(() => moodFor(s), returnsNormally);
    }
    expect(moodFor(GooseState.sleepwalk).name, 'investigate');
    expect(moodFor(GooseState.chase).name, 'chase');
  });

  test('wakeTip names the pot when the pot woke her', () {
    expect(wakeTip(_caughtBy(['glass', 'pot'])), contains('pot doubles'));
  });

  test('wakeTip without a chain follows the cause', () {
    expect(wakeTip(_caughtBy([], cause: WakeCause.footsteps)), contains('Sneak'));
    expect(wakeTip(_caughtBy([], cause: WakeCause.grabbedGuarded)), contains('roll-over'));
  });

  test('every hide spot has its tag and peek', () {
    expect(hideArt.keys, Levels.night3.hideSpots.map((h) => h.x));
  });

  test('every snap spot has a glow and a pot box on its x', () {
    for (final spot in Levels.night3.spots.values.where((s) => s.snap)) {
      expect(snapAnchors[spot.id]?.dx, spot.x, reason: spot.id);
      expect(potBoxAt(spot.id).centerX, closeTo(spot.x, 0.5), reason: spot.id);
    }
  });

  testWidgets('every burglar pose renders', (tester) async {
    for (final pose in BurglarPose.values) {
      await tester.pumpWidget(Center(child: Burglar(pose: pose, width: 60)));
      expect(find.byType(Burglar), findsOneWidget, reason: pose.name);
      expect(tester.takeException(), isNull, reason: pose.name);
    }
  });
}
