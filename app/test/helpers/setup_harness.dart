import 'package:daily_budget/app.dart';
import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/preferences_providers.dart';
import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:daily_budget/core/widgets/amount_field.dart';
import 'package:daily_budget/data/preferences/in_memory_preferences_store.dart';
import 'package:daily_budget/data/preferences/preference_keys.dart';
import 'package:daily_budget/data/repositories/month_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/domain/preferences/hint_id.dart';
import 'package:daily_budget/features/month_setup/widgets/salary_day_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/budget/fixtures.dart';
import '../support/find_copy.dart';
import 'fake_app_database.dart';
import 'fake_money_store.dart';
import 'fake_month_repository.dart';
import 'fake_savings_repository.dart';
import 'fake_transaction_repository.dart';
import 'pump_app.dart';
import 'theme_cases.dart';

/// A device clock a test can move (midnight, the phone date set back).
final class MovableClock {
  new(CalendarDate day) : now = atMorning(day);

  DateTime now;

  DateTime read() => now;

  /// Moves the phone to [day], 10:00.
  void moveTo(CalendarDate day) => now = atMorning(day);
}

/// [day] at 10:00 local time, the clock value a test hands the app.
DateTime atMorning(CalendarDate day) =>
    DateTime(day.year, day.month, day.day, 10);

/// A store holding a confirmed month with [values] from [firstBudgetedDay]
/// (the month's start by default). By default E2 in 5 Nov – 4 Dec 2026.
FakeMoneyStore storeWithMonth({
  PeriodValues? values,
  BudgetMonth? month,
  CalendarDate? firstBudgetedDay,
  List<BudgetPeriod>? periods,
}) {
  final store = FakeMoneyStore();
  addMonth(
    store,
    values: values,
    month: month,
    firstBudgetedDay: firstBudgetedDay,
    periods: periods,
  );
  return store;
}

/// Adds a confirmed month to [store] and returns it.
StoredMonth addMonth(
  FakeMoneyStore store, {
  PeriodValues? values,
  BudgetMonth? month,
  CalendarDate? firstBudgetedDay,
  List<BudgetPeriod>? periods,
}) {
  final budgetMonth = month ?? nov2026;
  final first = firstBudgetedDay ?? budgetMonth.start;
  final stored = StoredMonth(
    id: store.nextId(),
    month: budgetMonth,
    firstBudgetedDay: first,
    confirmedAt: at(first, 8),
    // Saved a day before the first budgeted day, so a change made on that
    // day by the app clock (local time) always orders after it.
    periods:
        periods ??
        [
          period(
            first,
            values ?? e2Values(),
            changedAt: at(first.addDays(-1), 0),
          ),
        ],
  );
  store.months.add(stored);
  return stored;
}

/// The whole app on the fake repositories and [clock], on the Home tab.
/// Hints are dismissed unless [hintsSeen] is false.
Future<void> pumpHome(
  WidgetTester tester, {
  required FakeMoneyStore money,
  required MovableClock clock,
  ThemeCase theme = ThemeCase.light,
  Size? size = kSmallPhone,
  double textScale = 1,
  bool hintsSeen = true,
  bool disableAnimations = false,
}) async {
  theme.applyTo(tester);
  setUpScreen(
    tester,
    size: size,
    textScale: textScale,
    disableAnimations: disableAnimations,
  );
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
        clockProvider.overrideWithValue(clock.read),
      ],
      child: const DailyBudgetApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// A container on the fakes of [money] with the phone date on [clock], for
/// tests without widgets. The caller disposes it inside the test (a pending
/// midnight timer fails a test that has already finished).
ProviderContainer containerOn(FakeMoneyStore money, MovableClock clock) =>
    ProviderContainer(
      overrides: [
        monthRepositoryProvider.overrideWithValue(FakeMonthRepository(money)),
        transactionRepositoryProvider.overrideWithValue(
          FakeTransactionRepository(money),
        ),
        savingsRepositoryProvider.overrideWithValue(
          FakeSavingsRepository(money),
        ),
        clockProvider.overrideWithValue(clock.read),
      ],
    );

/// Scrolls [finder] into view, lets that settle and taps it. What the tap
/// causes is left unsettled, for the same-frame tests.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  // A focused text field scrolls itself back into view and would undo
  // `ensureVisible`.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
}

/// Taps the first text [label] (scrolled into view) and settles.
Future<void> tapText(WidgetTester tester, String label) async {
  await tapVisible(tester, find.text(label));
  await tester.pumpAndSettle();
}

/// The text field of the amount field labelled [label].
Finder amountInput(String label) => find.descendant(
  of: find.widgetWithText(AmountField, label),
  matching: find.byType(TextField),
);

/// Types [text] into the amount field labelled [label], one pump.
Future<void> typeAmount(WidgetTester tester, String label, String text) async {
  await tester.enterText(amountInput(label), text);
  await tester.pump();
}

/// The name fields of the fixed-cost rows, in order (the only text fields
/// with a 40 character limit).
Finder get itemNameFields => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.maxLength == 40,
);

/// The amount fields of the fixed-cost rows, in order (right-aligned).
Finder get itemAmountFields => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.textAlign == TextAlign.end,
);

/// What is typed in the text field [finder].
String typed(WidgetTester tester, Finder finder) =>
    tester.widget<TextField>(finder).controller!.text;

/// Opens the salary day sheet, taps [day] and closes it with Done.
Future<void> pickSalaryDay(WidgetTester tester, int day) async {
  await tapVisible(
    tester,
    find.descendant(
      of: find.byType(SalaryDayField),
      matching: find.byType(InkWell),
    ),
  );
  await tester.pumpAndSettle();
  await tapVisible(
    tester,
    find.descendant(
      of: find.byType(SalaryDaySheet),
      matching: find.text(day >= 29 ? '$day*' : '$day'),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Done'));
  await tester.pumpAndSettle();
}

/// Types the E2 entry (salary 40000, Rent 10000, EMI 5000, Subscriptions
/// 100) into a first setup whose salary day is already chosen.
Future<void> enterE2(WidgetTester tester) async {
  await typeAmount(tester, 'Monthly salary', '40000');
  await tester.enterText(itemAmountFields.at(0), '10000');
  await tester.enterText(itemAmountFields.at(1), '5000');
  await tester.enterText(itemAmountFields.at(2), '100');
  await tester.pump();
}

/// Whether `findCopy(text)` is on screen.
bool hasCopy(String text) => findCopy(text).evaluate().isNotEmpty;

/// The engine's result for the first stored month of [store], for [today].
MonthResult storedResult(FakeMoneyStore store, CalendarDate today) =>
    computeMonth(store.inputFor(store.months.first.id, today));

/// The paise of every budgeted day of [result], in order.
List<int> budgetPaise(MonthResult result) => [
  for (final day in result.days) ?day.budget?.value,
];
