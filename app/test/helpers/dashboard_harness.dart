import 'package:daily_budget/app.dart';
import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/preferences_providers.dart';
import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:daily_budget/data/preferences/in_memory_preferences_store.dart';
import 'package:daily_budget/data/preferences/preference_keys.dart';
import 'package:daily_budget/data/repositories/transaction_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/domain/preferences/hint_id.dart';
import 'package:daily_budget/features/day_details/open_day_details.dart';
import 'package:daily_budget/features/month_setup/month_setup_controller.dart';
import 'package:daily_budget/features/statement/open_month_statement.dart';
import 'package:daily_budget/features/transactions/month_setup_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_app_database.dart';
import 'fake_money_store.dart';
import 'fake_month_repository.dart';
import 'fake_savings_repository.dart';
import 'fake_transaction_repository.dart';
import 'phase3_data.dart';
import 'phase3_fixtures.dart';
import 'pump_app.dart';
import 'shell.dart';
import 'theme_cases.dart';
import 'transactions_harness.dart';

/// What the Dashboard's seams were asked to open.
final class DashboardCalls {
  final List<({int monthId, CalendarDate date})> days = [];
  final List<int> statements = [];
  final List<SetupMode> setups = [];
}

/// The whole app on the fake repositories, opened on the Dashboard tab.
/// [fixture] seeds the store (and sets the clock) unless [money] is given.
Future<DashboardCalls> pumpDashboard(
  WidgetTester tester, {
  Phase3Fixture? fixture,
  FakeMoneyStore? money,
  TestClock? clock,
  ThemeCase theme = ThemeCase.light,
  Size? size = kSmallPhone,
  double textScale = 1,
  bool hintsSeen = true,
  bool openTab = true,
}) async {
  final store =
      money ?? (fixture == null ? FakeMoneyStore() : storeFor(fixture));
  final testClock =
      clock ?? (fixture == null ? TestClock(nov9()) : TestClock(fixture.now));
  // `setUpScreen` only sets what differs from the default and never undoes
  // it, so a sweep opening many states in one test starts each from the
  // defaults.
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
  tester.platformDispatcher.clearTextScaleFactorTestValue();
  tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
  await tester.pumpWidget(const SizedBox());
  final calls = DashboardCalls();
  theme.applyTo(tester);
  setUpScreen(tester, size: size, textScale: textScale);
  final preferences = InMemoryPreferencesStore.allowing(
    PreferenceKeys.allowList,
  );
  await preferences.writeString(
    PreferenceKeys.themeChoice,
    theme.choice.storageValue,
  );
  if (hintsSeen) {
    for (final id in HintId.values) {
      await preferences.writeBool(PreferenceKeys.hintSeen(id), value: true);
    }
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesStoreProvider.overrideWithValue(OnboardedStore(preferences)),
        appDatabaseProvider.overrideWith((ref) async => FakeAppDatabase()),
        monthRepositoryProvider.overrideWithValue(FakeMonthRepository(store)),
        transactionRepositoryProvider.overrideWithValue(
          FakeTransactionRepository(store),
        ),
        savingsRepositoryProvider.overrideWithValue(
          FakeSavingsRepository(store),
        ),
        clockProvider.overrideWithValue(testClock.read),
        monthSetupLauncherProvider.overrideWithValue(
          (context, mode) => calls.setups.add(mode),
        ),
        dayDetailsLauncherProvider.overrideWithValue(
          (context, {required monthId, required date}) =>
              calls.days.add((monthId: monthId, date: date)),
        ),
        monthStatementLauncherProvider.overrideWithValue(
          (context, monthId, {scrollToPeriodStart}) =>
              calls.statements.add(monthId),
        ),
      ],
      child: const DailyBudgetApp(),
    ),
  );
  await tester.pumpAndSettle();
  if (openTab) await tapTab(tester, 'Dashboard');
  return calls;
}

/// Replaces the stored spend [id] of the store's [monthIndex] month with the
/// same spend in [category] and tells the watchers (what F-015 does).
void setCategoryOf(
  FakeMoneyStore store,
  int id,
  SpendCategory? category, {
  int monthIndex = 0,
}) {
  final list = store.spendsByMonth[store.months[monthIndex].id]!;
  final index = list.indexWhere((s) => s.spend.id == id);
  final old = list[index];
  list[index] = StoredSpend(
    spend: Spend(
      id: old.spend.id,
      date: old.spend.date,
      amount: old.spend.amount,
      createdAt: old.spend.createdAt,
      direction: old.spend.direction,
      category: category,
    ),
    note: old.note,
  );
  store.notify();
}
