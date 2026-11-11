import 'package:daily_budget/data/preferences/in_memory_preferences_store.dart';
import 'package:daily_budget/data/preferences/preference_keys.dart';
import 'package:daily_budget/data/preferences/preferences_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opens the device preferences store, or returns an empty
/// [InMemoryPreferencesStore] if it cannot be opened, so the app always
/// starts (plan F-002 §7, "store cannot be opened").
Future<PreferencesStore> openPreferencesStore() async {
  try {
    return await SharedPreferencesStore.open();
  } on Object {
    return InMemoryPreferencesStore.allowing(PreferenceKeys.allowList);
  }
}

/// [PreferencesStore] on the `shared_preferences` plugin. The only file that
/// imports the plugin.
///
/// Uses `SharedPreferencesWithCache`: one async load, then synchronous reads
/// from the cache. On Android the plugin stores the values in Jetpack
/// DataStore.
final class SharedPreferencesStore implements PreferencesStore {
  new _(this._preferences, this._allowList);

  /// Loads every allowed key from the device. Throws if the platform store
  /// cannot be read; [openPreferencesStore] handles that.
  /// [allowList] defaults to [PreferenceKeys.allowList].
  static Future<SharedPreferencesStore> open({Set<String>? allowList}) async {
    final keys = allowList ?? PreferenceKeys.allowList;
    final preferences = await SharedPreferencesWithCache.create(
      cacheOptions: SharedPreferencesWithCacheOptions(allowList: keys),
    );
    return SharedPreferencesStore._(preferences, keys);
  }

  final SharedPreferencesWithCache _preferences;
  final Set<String> _allowList;

  // The plugin throws for a key outside the allow list; checking first keeps
  // reads total without catching errors.
  Object? _read(String key) =>
      _allowList.contains(key) ? _preferences.get(key) : null;

  @override
  String? readString(String key) => switch (_read(key)) {
    final String value => value,
    _ => null,
  };

  @override
  bool? readBool(String key) => switch (_read(key)) {
    final bool value => value,
    _ => null,
  };

  @override
  Future<bool> writeString(String key, String value) =>
      _write(key, () => _preferences.setString(key, value));

  @override
  Future<bool> writeBool(String key, {required bool value}) =>
      _write(key, () => _preferences.setBool(key, value));

  @override
  Future<bool> remove(String key) =>
      _write(key, () => _preferences.remove(key));

  Future<bool> _write(String key, Future<void> Function() write) async {
    if (!_allowList.contains(key)) return false;
    try {
      await write();
      return true;
    } on Object {
      return false;
    }
  }
}
