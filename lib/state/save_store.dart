import 'package:shared_preferences/shared_preferences.dart';

/// Where the save blob lives: one JSON string.
abstract interface class SaveStore {
  /// The last blob written, or null on a fresh install.
  Future<String?> read();

  Future<void> write(String data);
}

/// The app's store: one key in shared_preferences.
class PrefsSaveStore implements SaveStore {
  static const key = 'save.v1';

  final _prefs = SharedPreferencesAsync();

  @override
  Future<String?> read() => _prefs.getString(key);

  @override
  Future<void> write(String data) => _prefs.setString(key, data);
}

/// A store in memory, for tests.
class MemorySaveStore implements SaveStore {
  MemorySaveStore([this.data]);

  String? data;

  /// Blobs written so far.
  int writes = 0;

  @override
  Future<String?> read() async => data;

  @override
  Future<void> write(String data) async {
    this.data = data;
    writes++;
  }
}
