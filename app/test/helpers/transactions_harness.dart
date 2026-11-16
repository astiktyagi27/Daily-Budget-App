import 'package:daily_budget/app.dart';
import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/preferences_providers.dart';
import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:daily_budget/data/preferences/in_memory_preferences_store.dart';
import 'package:daily_budget/data/preferences/preference_keys.dart';
import 'package:daily_budget/data/repositories/month_repository.dart';
import 'package:daily_budget/data/repositories/transaction_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/domain/preferences/hint_id.dart';
import 'package:daily_budget/features/month_setup/month_setup_controller.dart';
import 'package:daily_budget/features/transactions/month_setup_launcher.dart';
import 'package:daily_budget/features/transactions/today_line_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/budget/fixtures.dart';
import 'fake_app_database.dart';
import 'fake_money_store.dart';
import 'fake_month_repository.dart';
import 'fake_savings_repository.dart';
import 'fake_transaction_repository.dart';
import 'pump_app.dart';
import 'shell.dart';
import 'theme_cases.dart';

/// A device clock a test can move (midnight, clock set back).
final class TestClock {
  new(this.now);

  DateTime now;

  DateTime read() => now;
}

/// Mon 9 Nov 2026, mid-morning: the F-009 worked example's day.
DateTime nov9() => DateTime(2026, 11, 9, 10);

/// The money store seeded with month E2 (5 Nov - 4 Dec 2026, ₹830 a day).
FakeMoneyStore e2Store({
  CalendarDate? firstBudgetedDay,
  PeriodValues? values,
  List<BudgetPeriod>? periods,
}) {
  final store = FakeMoneyStore();
  final first = firstBudgetedDay ?? d(2026, 11, 5);
  store.months.add(
    StoredMonth(
      id: store.nextId(),
      month: nov2026,
      firstBudgetedDay: first,
      confirmedAt: at(first, 8),
      periods: periods ?? [period(first, values ?? e2Values())],
    ),
  );
  return store;
}

/// Adds a spend of [paise] on [date] to the store's month.
int addSpendTo(
  FakeMoneyStore store,
  CalendarDate date,
  int paise, {
  String? note,
  int? createdAt,
  int monthIndex = 0,
}) {
  final monthId = store.months[monthIndex].id;
  final id = store.nextId();
  store.spendsByMonth
      .putIfAbsent(monthId, () => [])
      .add(
        StoredSpend(
          spend: Spend(
            id: id,
            date: date,
            amount: Paise(paise),
            createdAt: createdAt ?? at(date, 12),
          ),
          note: note,
        ),
      );
  return id;
}

/// Adds a stored cover (D-040 test data).
void addCoverTo(FakeMoneyStore store, CalendarDate day, int paise) {
  final monthId = store.months.first.id;
  store.coversByMonth
      .putIfAbsent(monthId, () => [])
      .add(
        Cover(
          id: store.nextId(),
          day: day,
          amount: Paise(paise),
          madeAt: at(day, 20),
        ),
      );
}

/// The whole app on the fake repositories and a test clock, opened on the
/// Transactions tab. Hints are dismissed unless [hintsSeen] is false.
/// [onSetUpMonth] replaces the setup route and is called with the mode when a
/// "Set up ..." button is tapped; without it the real setup screen opens.
Future<void> pumpTransactions(
  WidgetTester tester, {
  required FakeMoneyStore money,
  TestClock? clock,
  ThemeCase theme = ThemeCase.light,
  Size? size = kSmallPhone,
  double textScale = 1,
  bool hintsSeen = true,
  void Function(SetupMode mode)? onSetUpMonth,
  bool openTab = true,
}) async {
  final testClock = clock ?? TestClock(nov9());
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
        monthRepositoryProvider.overrideWithValue(FakeMonthRepository(money)),
        transactionRepositoryProvider.overrideWithValue(
          FakeTransactionRepository(money),
        ),
        savingsRepositoryProvider.overrideWithValue(
          FakeSavingsRepository(money),
        ),
        clockProvider.overrideWithValue(testClock.read),
        if (onSetUpMonth != null)
          monthSetupLauncherProvider.overrideWithValue(
            (context, mode) => onSetUpMonth(mode),
          ),
      ],
      child: const DailyBudgetApp(),
    ),
  );
  await tester.pumpAndSettle();
  if (openTab) await tapTab(tester, 'Transactions');
}

/// The text of the Today line, its parts joined by one space, marks left
/// out: `budget ₹830 · spent ₹250 · ₹580 left today`.
String todayLineText(WidgetTester tester) {
  final line = find.byKey(TodayLineView.lineKey);
  final texts = find.descendant(of: line, matching: find.byType(Text));
  final parts = <String>[];
  for (final element in texts.evaluate()) {
    final text = element.widget as Text;
    if (text.key == TodayLineView.markKey) continue;
    parts.add(text.data ?? text.textSpan!.toPlainText());
  }
  return parts.join(' ').replaceAll(' ', ' ').replaceAll('⁠', '');
}

/// The Add spend button of the shell.
Finder get addSpendButton => find.byType(FloatingActionButton);

/// Types [text] into [field] (the editor's Amount or Note).
Future<void> typeInto(WidgetTester tester, Finder field, String text) async {
  await tester.enterText(field, text);
  await tester.pump();
}

/// The editor's amount field and note field.
Finder get amountInput => find.byType(TextField).first;
Finder get noteInput => find.byType(TextField).last;

/// Taps the first button whose label is [label].
Future<void> tapLabel(WidgetTester tester, String label) async {
  // Test text input leaves a selection handle over the bottom buttons.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  final finder = find.text(label).hitTestable();
  await tester.ensureVisible(finder.first);
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

/// All stored spends of the first month.
List<StoredSpend> storedSpends(FakeMoneyStore store) =>
    store.spendsByMonth[store.months.first.id] ?? <StoredSpend>[];
