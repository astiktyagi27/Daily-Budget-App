import 'package:daily_budget/app.dart';
import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/preferences_providers.dart';
import 'package:daily_budget/core/theme/budget_theme.dart';
import 'package:daily_budget/core/theme/system_bars.dart';
import 'package:daily_budget/data/database/app_database.dart';
import 'package:daily_budget/data/preferences/in_memory_preferences_store.dart';
import 'package:daily_budget/data/preferences/preference_keys.dart';
import 'package:daily_budget/data/preferences/preferences_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_app_database.dart';
import 'fake_money_store.dart';
import 'fake_month_repository.dart';
import 'fake_savings_repository.dart';
import 'fake_transaction_repository.dart';
import 'theme_cases.dart';

/// Test screen sizes in dp (test cases §0).
const kSmallPhone = Size(360, 640);
const kNarrowPhone = Size(320, 640);
const kNarrowShortPhone = Size(320, 568);
const kSmallLandscape = Size(640, 360);

/// Sets the logical screen size, text scale and accessibility flags for one
/// test; everything is reset when the test ends.
void setUpScreen(
  WidgetTester tester, {
  Size? size,
  double textScale = 1,
  bool boldText = false,
  bool highContrast = false,
  bool disableAnimations = false,
}) {
  if (size != null) {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = size * 3;
    addTearDown(tester.view.reset);
  }
  if (textScale != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  if (boldText || highContrast || disableAnimations) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(
          boldText: boldText,
          highContrast: highContrast,
          disableAnimations: disableAnimations,
        );
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
}

/// Pumps the whole app as `main()` starts it, on [store] (by default a fresh
/// in-memory store that accepts only the app's registered keys, like the
/// device store). [theme] is saved in the store first, unless
/// [seedTheme] is false (for tests that seed the store themselves).
///
/// Onboarding counts as finished, so the app opens on Home (plan F-005 §8),
/// unless [onboarded] is false (the F-005 onboarding tests).
///
/// [settle] false stops after the first frame, for "first frame" checks.
///
/// The money database opens through [openDatabase], by default a
/// `FakeAppDatabase` that opens at once and is never used (widget tests
/// never touch Drift). Pass a function that throws a `StorageException` to
/// see the storage error screen (F-007 T-208). The three repositories are the
/// in-memory fakes on [money] (an empty store by default).
Future<void> pumpBudgetApp(
  WidgetTester tester, {
  PreferencesStore? store,
  ThemeCase theme = ThemeCase.light,
  bool seedTheme = true,
  bool onboarded = true,
  Size? size,
  double textScale = 1,
  bool disableAnimations = false,
  bool settle = true,
  Future<AppDatabase> Function()? openDatabase,
  FakeMoneyStore? money,
}) async {
  final moneyStore = money ?? FakeMoneyStore();
  theme.applyTo(tester);
  setUpScreen(
    tester,
    size: size,
    textScale: textScale,
    disableAnimations: disableAnimations,
  );
  final preferences =
      store ?? InMemoryPreferencesStore.allowing(PreferenceKeys.allowList);
  if (seedTheme) {
    await preferences.writeString(
      PreferenceKeys.themeChoice,
      theme.choice.storageValue,
    );
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesStoreProvider.overrideWithValue(
          onboarded ? OnboardedStore(preferences) : preferences,
        ),
        appDatabaseProvider.overrideWith(
          (ref) => (openDatabase ?? () async => FakeAppDatabase())(),
        ),
        monthRepositoryProvider.overrideWithValue(
          FakeMonthRepository(moneyStore),
        ),
        transactionRepositoryProvider.overrideWithValue(
          FakeTransactionRepository(moneyStore),
        ),
        savingsRepositoryProvider.overrideWithValue(
          FakeSavingsRepository(moneyStore),
        ),
      ],
      child: const DailyBudgetApp(),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

/// Pumps [child] alone inside a themed `MaterialApp` + `Scaffold`, for
/// component tests. The theme comes straight from [theme]'s choice; no store
/// is involved apart from an empty in-memory one in the `ProviderScope`.
/// Pass [settle] false when [child] animates forever (a progress ring), and
/// [scaffold] false when [child] is a whole screen with its own `Scaffold`.
Future<void> pumpBudgetWidget(
  WidgetTester tester,
  Widget child, {
  ThemeCase theme = ThemeCase.light,
  Size? size,
  double textScale = 1,
  bool boldText = false,
  bool highContrast = false,
  bool disableAnimations = false,
  bool settle = true,
  List<NavigatorObserver> navigatorObservers = const [],
  bool scaffold = true,
}) async {
  theme.applyTo(tester);
  setUpScreen(
    tester,
    size: size,
    textScale: textScale,
    boldText: boldText,
    highContrast: highContrast,
    disableAnimations: disableAnimations,
  );
  final config = themeConfigFor(theme.choice);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesStoreProvider.overrideWithValue(
          InMemoryPreferencesStore.allowing(PreferenceKeys.allowList),
        ),
      ],
      child: MaterialApp(
        themeMode: config.mode,
        theme: config.light,
        darkTheme: config.dark,
        builder: (context, child) => SystemBarsStyle(child: child!),
        navigatorObservers: navigatorObservers,
        home: scaffold ? Scaffold(body: SafeArea(child: child)) : child,
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

/// Test cases §0 "Restart (sim)": disposes the whole tree (and its
/// `ProviderScope`), then pumps a brand-new app on [store], a new store
/// object that shares only the old backing map. [system] sets the phone's
/// light/dark setting; nothing is seeded. Onboarding counts as finished
/// unless [onboarded] is false. Stops after the first frame unless [settle]
/// is true.
Future<void> restartApp(
  WidgetTester tester,
  PreferencesStore store, {
  ThemeCase system = ThemeCase.light,
  bool onboarded = true,
  bool settle = false,
}) async {
  await tester.pumpWidget(const SizedBox());
  await pumpBudgetApp(
    tester,
    store: store,
    theme: system,
    seedTheme: false,
    onboarded: onboarded,
    settle: settle,
  );
}

/// [inner] with onboarding finished (plan F-005 §8: the F-002…F-004 cases
/// start on Home). Only the two onboarding flags are answered here, as
/// `true`; everything else, including failures, goes to [inner], and nothing
/// is written to it.
final class OnboardedStore implements PreferencesStore {
  new(this.inner);

  final PreferencesStore inner;

  static const Set<String> _flags = {
    PreferenceKeys.onboardingTourSeen,
    PreferenceKeys.onboardingFinished,
  };

  @override
  bool? readBool(String key) =>
      _flags.contains(key) ? true : inner.readBool(key);

  @override
  String? readString(String key) => inner.readString(key);

  @override
  Future<bool> writeBool(String key, {required bool value}) =>
      inner.writeBool(key, value: value);

  @override
  Future<bool> writeString(String key, String value) =>
      inner.writeString(key, value);

  @override
  Future<bool> remove(String key) => inner.remove(key);
}
