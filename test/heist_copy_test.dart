import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/heist.dart';
import 'package:jangan_bangunin_angsa_app/game/night_sim.dart';
import 'package:jangan_bangunin_angsa_app/screens/briefing_screen.dart';
import 'package:jangan_bangunin_angsa_app/screens/heist_copy.dart';
import 'package:jangan_bangunin_angsa_app/state/heist_log.dart';
import 'package:jangan_bangunin_angsa_app/state/levels.dart';

import 'helpers.dart';

void main() {
  tearDown(HeistLog.instance.clear);

  List<HeistGoal> goals() => Levels.night3.goals;

  test('briefing copy', () {
    expect(goals().map(goalBrief), [
      'Never let her turn suspicious',
      'Lure her out of bed twice',
      'Fire a 5-link chain',
    ]);
    expect(goalBrief(const HeistGoal(style: PlayStyle.trickster, kind: GoalKind.lure)), 'Lure her out of bed once');
    expect(goalBrief(const HeistGoal(style: PlayStyle.trickster, kind: GoalKind.lure, count: 3)), 'Lure her out of bed 3 times');
  });

  test('recap copy', () {
    expect(goals().map(goalRecap), ['Never seen', 'Lured her out twice', '5+ link chain']);
    expect(goalRecap(const HeistGoal(style: PlayStyle.trickster, kind: GoalKind.lure, count: 3)), 'Lured her out 3 times');
    expect(goalRecap(const HeistGoal(style: PlayStyle.trickster, kind: GoalKind.lure)), 'Lured her out once');
  });

  test('HUD pill copy', () {
    final sim = NightSim(Levels.night3);
    expect(goals().map((g) => goalPill(g, sim)), [
      'Never let her turn suspicious',
      'Lure her out of bed · 0/2',
      'Fire a 5-link chain · 0/5',
    ]);
  });

  test('thousands', () {
    expect(thousands(8450), '8,450');
    expect(thousands(1200), '1,200');
    expect(thousands(0), '0');
    expect(thousands(999), '999');
    expect(thousands(1234567), '1,234,567');
  });

  test('the log keeps the socks a getaway earned', () {
    HeistLog.instance.record(sampleEscape(goalsMet: {PlayStyle.trickster}));
    expect(HeistLog.instance.earned('night3'), {PlayStyle.trickster});
    HeistLog.instance.record(sampleCaught());
    expect(HeistLog.instance.earned('night3'), {PlayStyle.trickster});
    expect(HeistLog.instance.earned('night9'), isEmpty);
  });

  testWidgets('Briefing counts the socks earned', (tester) async {
    HeistLog.instance.record(sampleEscape(goalsMet: {PlayStyle.ghost}));
    await pumpScreen(tester, const BriefingScreen());
    expect(find.text('HEIST GOALS · 1 / 3 SOCKS'), findsOneWidget);
    expect(find.text('Lure her out of bed twice'), findsOneWidget);
    expect(find.bySemanticsLabel('Sock earned'), findsOneWidget);
    expect(find.bySemanticsLabel('Sock not yet earned'), findsNWidgets(2));
  });
}
