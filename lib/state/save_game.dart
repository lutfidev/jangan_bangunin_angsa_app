import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'briefing_prefs.dart';
import 'game_settings.dart';
import 'heist_log.dart';
import 'json_fields.dart';
import 'save_store.dart';

/// Keeps the socks, the pilfered loot, the settings and the briefing picks
/// on disk. [start] restores them, then rewrites the whole blob after any
/// change, once per microtask turn however many changes land in it.
///
/// The blob: `{"v": 1, "socks": {...}, "pilfered": {...}, "settings":
/// {...}, "briefing": {...}}`. A field that is missing or the wrong shape
/// keeps its default; a store that fails is ignored.
abstract final class SaveGame {
  static SaveStore? _store;
  static bool _pending = false;

  static List<Listenable> get _sources => [HeistLog.instance, GameSettings.instance, BriefingPrefs.instance];

  static Future<void> start(SaveStore store) async {
    String? data;
    try {
      data = await store.read();
    } catch (e) {
      debugPrint('SaveGame: could not read the save ($e)');
    }
    final json = _decode(data);
    HeistLog.instance.restore(json);
    GameSettings.instance.restore(jsonMap(json['settings']));
    BriefingPrefs.instance.restore(jsonMap(json['briefing']));

    _store = store;
    for (final s in _sources) {
      s.addListener(_changed);
    }
  }

  /// Stops saving; the state stays as it is.
  @visibleForTesting
  static Future<void> stop() async {
    for (final s in _sources) {
      s.removeListener(_changed);
    }
    _store = null;
    _pending = false;
  }

  static void _changed() {
    if (_pending) return;
    _pending = true;
    scheduleMicrotask(_write);
  }

  static Future<void> _write() async {
    if (!_pending) return;
    _pending = false;
    final store = _store;
    if (store == null) return;
    final blob = {
      'v': 1,
      ...HeistLog.instance.toJson(),
      'settings': GameSettings.instance.toJson(),
      'briefing': BriefingPrefs.instance.toJson(),
    };
    try {
      await store.write(jsonEncode(blob));
    } catch (e) {
      debugPrint('SaveGame: could not write the save ($e)');
    }
  }

  static Map<String, Object?> _decode(String? data) {
    if (data == null) return const {};
    try {
      return jsonMap(jsonDecode(data));
    } on FormatException {
      return const {};
    }
  }
}
