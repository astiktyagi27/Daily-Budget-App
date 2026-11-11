import 'package:daily_budget/data/preferences/preference_keys.dart';
import 'package:daily_budget/data/preferences/preferences_store.dart';
import 'package:daily_budget/domain/preferences/onboarding_stage.dart';

/// Reads and saves the two onboarding flags (F-005 §2.8).
///
/// Never throws. A missing, wrong-type or unreadable flag counts as **not
/// set**, so the app fails towards showing onboarding again, never towards a
/// blank screen (AC-15). Which explainer buttons were tapped is not saved.
class OnboardingRepository {
  const new(this._store);

  final PreferencesStore _store;

  OnboardingStage read() => OnboardingStage.fromFlags(
    tourSeen: _flag(PreferenceKeys.onboardingTourSeen),
    finished: _flag(PreferenceKeys.onboardingFinished),
  );

  /// Returns `false` when the flag could not be saved.
  Future<bool> markTourSeen() => _set(PreferenceKeys.onboardingTourSeen);

  /// Returns `false` when the flag could not be saved.
  Future<bool> markFinished() => _set(PreferenceKeys.onboardingFinished);

  bool _flag(String key) {
    try {
      return _store.readBool(key) ?? false;
    } on Object {
      // A store that breaks its no-throw contract still must not stop the app.
      return false;
    }
  }

  Future<bool> _set(String key) async {
    try {
      return await _store.writeBool(key, value: true);
    } on Object {
      return false;
    }
  }
}
