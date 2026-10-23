import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/state/levels.dart';

void main() {
  test('nights are found by id', () {
    expect(Levels.byId('night3'), same(Levels.night3));
    expect(Levels.byId('house').id, 'house');
    expect(() => Levels.byId('attic'), throwsArgumentError);
  });
}
