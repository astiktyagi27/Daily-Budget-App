/// Small key-value store for app preferences (theme, onboarding and hint
/// flags). The code above `data/` only sees this interface, never the plugin.
///
/// Reads are synchronous: every value is loaded before the first frame, so the
/// first frame already uses the saved values. A missing key, a key the store
/// does not accept or a value of the wrong type reads as `null`, and the
/// caller uses its default.
///
/// Writes never throw. They return `false` when the value could not be saved;
/// the app keeps its in-memory state for the session.
abstract interface class PreferencesStore {
  String? readString(String key);

  bool? readBool(String key);

  Future<bool> writeString(String key, String value);

  Future<bool> writeBool(String key, {required bool value});

  Future<bool> remove(String key);
}
