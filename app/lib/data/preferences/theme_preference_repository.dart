import 'package:daily_budget/data/preferences/preference_keys.dart';
import 'package:daily_budget/data/preferences/preferences_store.dart';
import 'package:daily_budget/domain/preferences/theme_choice.dart';

/// Reads and saves the theme choice (F-002).
///
/// Never throws: a missing, unknown or unreadable value reads as
/// [ThemeChoice.auto] (AC-8), and a failed save returns `false` while the app
/// keeps the new choice for the session.
class ThemePreferenceRepository {
  const new(this._store);

  final PreferencesStore _store;

  ThemeChoice read() {
    try {
      return ThemeChoice.fromStorage(
        _store.readString(PreferenceKeys.themeChoice),
      );
    } on Object {
      // A store that breaks its no-throw contract still must not stop the app.
      return ThemeChoice.auto;
    }
  }

  Future<bool> write(ThemeChoice choice) async {
    try {
      return await _store.writeString(
        PreferenceKeys.themeChoice,
        choice.storageValue,
      );
    } on Object {
      return false;
    }
  }
}
