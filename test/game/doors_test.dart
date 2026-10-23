import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/doors.dart';
import 'package:jangan_bangunin_angsa_app/game/geom.dart';
import 'package:jangan_bangunin_angsa_app/game/level.dart';

import 'fixtures.dart';

void main() {
  Doors doors({bool open = false}) => Doors(Level.parse(twoRooms(open: open)));

  test('doors start as the level says', () {
    expect(doors().isOpen('d'), isFalse);
    expect(doors(open: true).isOpen('d'), isTrue);
    expect(doors().all.single.id, 'd');
    expect(Doors(night3()).all, isEmpty);
  });

  test('opening and closing are recorded once, in order', () {
    final d = doors();
    d.open('d', byGoose: true);
    expect(d.isOpen('d'), isTrue);
    d.close('d');
    expect(d.isOpen('d'), isFalse);
    final moves = d.takeMoves();
    expect(moves.map((m) => (m.doorId, m.open, m.byGoose)), [('d', true, true), ('d', false, false)]);
    expect(d.takeMoves(), isEmpty);
  });

  test('a change to how a door already is records nothing', () {
    final d = doors();
    d.close('d');
    expect(d.takeMoves(), isEmpty);
    d
      ..open('d')
      ..open('d');
    expect(d.takeMoves(), hasLength(1));
  });

  test('only closed doors are walls', () {
    expect(doors().closedLeaves.map((s) => s.box), [const Box(394, 140, 406, 270)]);
    expect(doors(open: true).closedLeaves, isEmpty);
  });

  test('closedAhead finds the closed door a walk would run into', () {
    final d = doors();
    expect(d.closedAhead(300, 390, 24, floorY: 270)?.id, 'd');
    expect(d.closedAhead(300, 370, 24, floorY: 270), isNull);
    expect(d.closedAhead(500, 410, 24, floorY: 270)?.id, 'd');
    expect(d.closedAhead(376, 380, 24, floorY: 270)?.id, 'd');
    expect(d.closedAhead(390, 300, 24, floorY: 270), isNull);
    expect(doors(open: true).closedAhead(300, 500, 24, floorY: 270), isNull);
    expect(d.closedAhead(300, 390, 24, floorY: 660), isNull, reason: 'a door on another floor is no wall');
  });

  test('freeSpan runs between closed doors and the world edges', () {
    expect(doors().freeSpan(200, floorY: 270), (min: 0.0, max: 394.0));
    expect(doors().freeSpan(600, floorY: 270), (min: 406.0, max: 844.0));
    expect(doors(open: true).freeSpan(200, floorY: 270), (min: 0.0, max: 844.0));
  });
}
