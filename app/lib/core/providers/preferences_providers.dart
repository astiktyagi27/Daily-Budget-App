import 'package:daily_budget/data/preferences/hint_repository.dart';
import 'package:daily_budget/data/preferences/onboarding_repository.dart';
import 'package:daily_budget/data/preferences/preferences_store.dart';
import 'package:daily_budget/data/preferences/theme_preference_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app's single [PreferencesStore]. `main()` opens it before the first
/// frame and overrides this provider with it; tests override it with an
/// `InMemoryPreferencesStore`. Without an override it throws, so a missing
/// bootstrap shows up at once.
final preferencesStoreProvider = Provider<PreferencesStore>(
  (ref) => throw StateError(
    'preferencesStoreProvider was not overridden with the opened store',
  ),
);

final themePreferenceRepositoryProvider = Provider<ThemePreferenceRepository>(
  (ref) => ThemePreferenceRepository(ref.watch(preferencesStoreProvider)),
);

final hintRepositoryProvider = Provider<HintRepository>(
  (ref) => HintRepository(ref.watch(preferencesStoreProvider)),
);

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(ref.watch(preferencesStoreProvider)),
);
