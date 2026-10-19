import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jangan_bangunin_angsa_app/game/heist.dart';
import 'package:jangan_bangunin_angsa_app/game/tools.dart';
import 'package:jangan_bangunin_angsa_app/state/briefing_prefs.dart';
import 'package:jangan_bangunin_angsa_app/state/game_settings.dart';
import 'package:jangan_bangunin_angsa_app/state/heist_log.dart';
import 'package:jangan_bangunin_angsa_app/state/save_game.dart';
import 'package:jangan_bangunin_angsa_app/state/save_store.dart';

import 'helpers.dart';

/// A store whose disk is gone.
class _BrokenStore implements SaveStore {
  @override
  Future<String?> read() => Future.error(StateError('no disk'));

  @override
  Future<void> write(String data) => Future.error(StateError('no disk'));
}

/// A store whose read fails but whose write would work.
class _UnreadableStore extends MemorySaveStore {
  _UnreadableStore() : super('{"socks": {"night3": ["ghost"]}}');

  @override
  Future<String?> read() => Future.error(StateError('busy'));
}

/// Forgets the in-memory state, as a fresh app launch would.
void _relaunch() {
  HeistLog.instance.clear();
  GameSettings.instance.reset();
  BriefingPrefs.instance.reset();
}

void main() {
  tearDown(() async {
    await SaveGame.stop();
    GameSettings.instance.reset();
  });

  test('a fresh install starts from defaults', () async {
    final store = MemorySaveStore();
    await SaveGame.start(store);
    expect(HeistLog.instance.totalSocks, 0);
    expect(HeistLog.instance.pilfered('night3'), isEmpty);
    expect(GameSettings.instance.sfx, 80);
    expect(BriefingPrefs.instance.remix, isTrue);
    expect(store.writes, 0);
  });

  test('everything round-trips', () async {
    final store = MemorySaveStore();
    await SaveGame.start(store);
    HeistLog.instance.record(sampleEscape(loot: ['toaster', 'egg'], goalsMet: {PlayStyle.trickster}));
    GameSettings.instance
      ..sfx = 30
      ..haptics = false;
    BriefingPrefs.instance
      ..tool = Tool.mouse
      ..remix = false
      ..mirror = true;
    await pumpEventQueue();
    await SaveGame.stop();

    _relaunch();
    await SaveGame.start(store);
    expect(HeistLog.instance.earned('night3'), {PlayStyle.trickster});
    expect(HeistLog.instance.pilfered('night3'), {'toaster', 'egg'});
    expect(GameSettings.instance.sfx, 30);
    expect(GameSettings.instance.haptics, isFalse);
    expect(BriefingPrefs.instance.tool, Tool.mouse);
    expect(BriefingPrefs.instance.remix, isFalse);
    expect(BriefingPrefs.instance.mirror, isTrue);
  });

  test('the blob has the documented shape', () async {
    final store = MemorySaveStore();
    await SaveGame.start(store);
    HeistLog.instance.record(sampleEscape(loot: ['toaster'], goalsMet: {PlayStyle.ghost}));
    await pumpEventQueue();
    expect(jsonDecode(store.data!), {
      'v': 1,
      'socks': {'night3': ['ghost']},
      'pilfered': {'night3': ['toaster']},
      'settings': {'sfx': 80, 'music': 60, 'haptics': true, 'reduceShake': false, 'leftHanded': false},
      'briefing': {'tool': 'socks', 'remix': true, 'lightSleeper': false, 'mirror': false},
    });
  });

  group('bad saves load as defaults', () {
    for (final data in [
      'not json',
      '[]',
      '"v"',
      '{"socks": [1], "settings": 3, "briefing": null}',
      '{"settings": {"sfx": 1e999, "music": -1e999}}',
    ]) {
      test(data, () async {
        await SaveGame.start(MemorySaveStore(data));
        expect(HeistLog.instance.totalSocks, 0);
        expect(GameSettings.instance.sfx, 80);
        expect(BriefingPrefs.instance.tool, Tool.socks);
      });
    }

    test('bad fields go, good ones stay', () async {
      await SaveGame.start(MemorySaveStore(jsonEncode({
        'socks': {'night3': ['ninja', 'ghost', 7]},
        'pilfered': {'night3': ['toaster', false]},
        'settings': {'sfx': 'loud', 'music': 200, 'haptics': 'yes', 'leftHanded': true},
        'briefing': {'tool': 'flamethrower', 'mirror': true},
      })));
      expect(HeistLog.instance.earned('night3'), {PlayStyle.ghost});
      expect(HeistLog.instance.pilfered('night3'), {'toaster'});
      expect(GameSettings.instance.sfx, 80);
      expect(GameSettings.instance.music, 100);
      expect(GameSettings.instance.haptics, isTrue);
      expect(GameSettings.instance.leftHanded, isTrue);
      expect(BriefingPrefs.instance.tool, Tool.socks);
      expect(BriefingPrefs.instance.mirror, isTrue);
    });
  });

  test('a slider drag writes once, with the last value', () async {
    final store = MemorySaveStore();
    await SaveGame.start(store);
    for (var v = 10; v <= 60; v++) {
      GameSettings.instance.sfx = v;
    }
    await pumpEventQueue();
    expect(store.writes, 1);
    expect((jsonDecode(store.data!) as Map)['settings']['sfx'], 60);
  });

  test('a save that could not be read is never overwritten', () async {
    // A read that fails (not a bad blob) may hide real progress: keep it.
    final store = _UnreadableStore();
    await SaveGame.start(store);
    GameSettings.instance.sfx = 20;
    await pumpEventQueue();
    expect(store.writes, 0);
  });

  test('a broken store does not stop the game', () async {
    await SaveGame.start(_BrokenStore());
    GameSettings.instance.sfx = 20;
    await pumpEventQueue();
    expect(GameSettings.instance.sfx, 20);
  });

  test('stop leaves the singletons alone', () async {
    final store = MemorySaveStore();
    await SaveGame.start(store);
    await SaveGame.stop();
    GameSettings.instance.sfx = 10;
    await pumpEventQueue();
    expect(store.writes, 0);
  });
}
