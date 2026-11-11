import 'package:daily_budget/domain/preferences/hint_id.dart';

/// Every preference key the app stores, in one place (plan F-002 §3).
///
/// [allowList] is built from these keys and handed to the plugin, so a key
/// that is not listed here can be neither read nor written.
abstract final class PreferenceKeys {
  /// `ThemeChoice` storage value: `auto`, `light`, `dark` or `dim` (F-002).
  static const themeChoice = 'theme.choice';

  /// Bool, true once the hint has been dismissed (F-004):
  /// `hint.home.v1.seen`, `hint.dashboard.v1.seen`, …
  static String hintSeen(HintId id) => 'hint.${id.storageSuffix}.seen';

  /// Bool, true once the welcome tour was finished or skipped (F-005).
  static const onboardingTourSeen = 'onboarding.tour_seen';

  /// Bool, true once I understand was tapped on the disclaimer (F-005).
  static const onboardingFinished = 'onboarding.finished';

  static final Set<String> allowList = Set.unmodifiable({
    themeChoice,
    for (final id in HintId.values) hintSeen(id),
    onboardingTourSeen,
    onboardingFinished,
  });
}
