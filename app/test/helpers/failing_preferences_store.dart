import 'package:daily_budget/data/preferences/preferences_store.dart';

/// A [PreferencesStore] that misbehaves on purpose (test cases §0,
/// "FakeStore" `readFails` / `writeFails`).
///
/// Unlike the real adapter it *throws*, so tests prove the code above the
/// store survives even a store that breaks its contract. [values] is the
/// backing map: a "Restart (sim)" builds a new store on the same map.
final class FailingPreferencesStore implements PreferencesStore {
  new({
    this.readFails = false,
    this.writeFails = false,
    Map<String, Object>? values,
  }) : values = values ?? {};

  final bool readFails;
  final bool writeFails;
  final Map<String, Object> values;

  @override
  String? readString(String key) {
    if (readFails) throw StateError('read failed');
    return switch (values[key]) {
      final String value => value,
      _ => null,
    };
  }

  @override
  bool? readBool(String key) {
    if (readFails) throw StateError('read failed');
    return switch (values[key]) {
      final bool value => value,
      _ => null,
    };
  }

  @override
  Future<bool> writeString(String key, String value) async {
    if (writeFails) throw StateError('write failed');
    values[key] = value;
    return true;
  }

  @override
  Future<bool> writeBool(String key, {required bool value}) async {
    if (writeFails) throw StateError('write failed');
    values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    if (writeFails) throw StateError('write failed');
    values.remove(key);
    return true;
  }
}
