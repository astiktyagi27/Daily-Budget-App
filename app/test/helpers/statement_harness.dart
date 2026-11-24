import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/preferences_providers.dart';
import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:daily_budget/core/theme/budget_theme.dart';
import 'package:daily_budget/core/theme/system_bars.dart';
import 'package:daily_budget/data/preferences/in_memory_preferences_store.dart';
import 'package:daily_budget/data/preferences/preference_keys.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/statement/month_statement_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_money_store.dart';
import 'fake_month_repository.dart';
import 'fake_savings_repository.dart';
import 'fake_transaction_repository.dart';
import 'phase3_data.dart';
import 'phase3_fixtures.dart';
import 'pump_app.dart';
import 'setup_harness.dart';
import 'theme_cases.dart';

/// Pumps the month statement of [fixture]'s newest month (or the stored
/// month at the given index) on the fake repositories, with the phone date on
/// the fixture's `today`. Returns the store and the clock.
Future<({FakeMoneyStore store, MovableClock clock})> pumpStatement(
  WidgetTester tester,
  Phase3Fixture fixture, {
  ThemeCase theme = ThemeCase.light,
  Size? size = kSmallPhone,
  double textScale = 1,
  CalendarDate? scrollToPeriodStart,
  FakeMoneyStore? store,
  bool disableAnimations = false,
  bool settle = true,
}) async {
  // A new app, so no state of an earlier pump is kept.
  await tester.pumpWidget(const SizedBox());
  theme.applyTo(tester);
  setUpScreen(
    tester,
    size: size,
    textScale: textScale,
    disableAnimations: disableAnimations,
  );
  final money = store ?? storeFor(fixture);
  final clock = clockFor(fixture);
  final config = themeConfigFor(theme.choice);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesStoreProvider.overrideWithValue(
          InMemoryPreferencesStore.allowing(PreferenceKeys.allowList),
        ),
        monthRepositoryProvider.overrideWithValue(FakeMonthRepository(money)),
        transactionRepositoryProvider.overrideWithValue(
          FakeTransactionRepository(money),
        ),
        savingsRepositoryProvider.overrideWithValue(
          FakeSavingsRepository(money),
        ),
        clockProvider.overrideWithValue(clock.read),
      ],
      child: MaterialApp(
        themeMode: config.mode,
        theme: config.light,
        darkTheme: config.dark,
        builder: (context, child) => SystemBarsStyle(child: child!),
        home: MonthStatementScreen(
          monthId: money.months.last.id,
          scrollToPeriodStart: scrollToPeriodStart,
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
  return (store: money, clock: clock);
}
