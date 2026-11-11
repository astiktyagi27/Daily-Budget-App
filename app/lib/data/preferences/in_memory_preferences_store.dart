import 'package:daily_budget/data/preferences/preferences_store.dart';

/// A [PreferencesStore] backed by a plain map.
///
/// Used as the fake in tests and as the runtime fallback when the plugin
/// cannot be opened: the app then works for the session and starts from the
/// defaults on the next launch.
final class InMemoryPreferencesStore implements PreferencesStore {
  /// Accepts any key.
  new([Map<String, Object> initialValues = const {}])
    : _values = Map.of(initialValues),
      _allowList = null;

  /// Accepts only the keys in [allowList], like the device store: other keys
  /// read as `null` and their writes return `false`. The app's test harness
  /// and the runtime fallback use `PreferenceKeys.allowList`, so a feature
  /// that forgets to register its key fails in widget tests too.
  new allowing(
    Set<String> allowList, [
    Map<String, Object> initialValues = const {},
  ]) : _values = Map.of(initialValues),
       _allowList = allowList;

  final Map<String, Object> _values;
  final Set<String>? _allowList;

  /// A read-only view of what is stored, so tests can check what was saved.
  Map<String, Object> get values => Map.unmodifiable(_values);

  bool _allows(String key) => _allowList?.contains(key) ?? true;

  Object? _read(String key) => _allows(key) ? _values[key] : null;

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
  Future<bool> writeString(String key, String value) async {
    if (!_allows(key)) return false;
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> writeBool(String key, {required bool value}) async {
    if (!_allows(key)) return false;
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    if (!_allows(key)) return false;
    _values.remove(key);
    return true;
  }
}
