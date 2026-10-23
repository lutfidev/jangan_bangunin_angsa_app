import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/night_sim.dart';
import 'package:jangan_bangunin_angsa_app/screens/night_art.dart';
import 'package:jangan_bangunin_angsa_app/screens/tool_art.dart';
import 'package:jangan_bangunin_angsa_app/state/levels.dart';

void main() {
  test('the throw arc matches Plan View', () {
    // Canvas: M356 212 Q210 40 66 176.
    final arc = throwArc(fromX: 382, end: const Offset(62, 184));
    expect(arc.start, const Offset(356, 212));
    expect(arc.control.dx, 209);
    expect(arc.control.dy, closeTo(35.6, 1e-9));
    expect(arc.end, const Offset(62, 184));
  });

  test('a long throw keeps its apex on screen', () {
    expect(throwArc(fromX: 800, end: const Offset(440, 262)).control.dy, 20);
  });

  test('throwing right starts from the right hand', () {
    final arc = throwArc(fromX: 100, end: const Offset(130, 262));
    expect(arc.start, const Offset(126, 212));
    expect(arc.control.dx, 128);
    expect(arc.control.dy, closeTo(209.6, 1e-9));
  });

  test('the arc ends on the object it would hit, else on the floor', () {
    final sim = NightSim(Levels.night3);
    expect(throwEnd(sim, 70, spotAnchors), spotAnchors['counterLeft']);
    expect(throwEnd(sim, 250, spotAnchors), const Offset(250, 262));
  });

  test('a point along the arc', () {
    final arc = throwArc(fromX: 382, end: const Offset(62, 184));
    expect(arc.at(0), arc.start);
    expect(arc.at(1), arc.end);
  });
}
