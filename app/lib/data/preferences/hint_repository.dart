import 'package:daily_budget/data/preferences/preference_keys.dart';
import 'package:daily_budget/data/preferences/preferences_store.dart';
import 'package:daily_budget/domain/preferences/hint_id.dart';

/// Reads and saves whether a first-time hint was dismissed (F-004).
///
/// Never throws. A missing, wrong-type or unreadable flag counts as **not
/// seen**, so the app fails towards showing help (AC-12).
class HintRepository {
  const new(this._store);

  final PreferencesStore _store;

  bool isSeen(HintId id) {
    try {
      return _store.readBool(PreferenceKeys.hintSeen(id)) ?? false;
    } on Object {
      // A store that breaks its no-throw contract still must not stop the app.
      return false;
    }
  }

  /// Returns `false` when the flag could not be saved.
  Future<bool> markSeen(HintId id) async {
    try {
      return await _store.writeBool(PreferenceKeys.hintSeen(id), value: true);
    } on Object {
      return false;
    }
  }
}
