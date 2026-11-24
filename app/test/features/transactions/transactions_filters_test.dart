// F-015 test cases for the Dates, Category and Type filters, the results
// line, the date range picker and how the filters live (tests/F-015 TC-015-10
// to -18, -25, -44, -47 to -49, -51, -52, -63). Search text cases are in
// `transactions_search_test.dart` and `transactions_search_queries_test.dart`.

import 'dart:ui' show Tristate;

import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/preferences_providers.dart';
import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:daily_budget/core/theme/budget_theme.dart';
import 'package:daily_budget/data/preferences/in_memory_preferences_store.dart';
import 'package:daily_budget/data/preferences/preference_keys.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/domain/preferences/hint_id.dart';
import 'package:daily_budget/domain/preferences/theme_choice.dart';
import 'package:daily_budget/features/transactions/sheets/category_filter_sheet.dart';
import 'package:daily_budget/features/transactions/transactions_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/fake_month_repository.dart';
import '../../helpers/fake_savings_repository.dart';
import '../../helpers/fake_transaction_repository.dart';
import '../../helpers/phase3_data.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/shell.dart';
import '../../helpers/transactions_harness.dart';
import '../../support/app_lifecycle.dart';
import '../../support/find_copy.dart';

Future<TestClock> _open(
  WidgetTester tester,
  Phase3Fixture fixture, {
  FakeMoneyStore? store,
  Size size = const Size(400, 1800),
}) async {
  final clock = TestClock(fixture.now);
  await pumpTransactions(
    tester,
    money: store ?? storeFor(fixture),
    clock: clock,
    size: size,
  );
  return clock;
}

Future<void> _search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField).first, text);
  await tester.pump(const Duration(milliseconds: 260));
  await tester.pumpAndSettle();
}

Future<void> _tapChip(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// A row of the Category filter sheet.
Finder _filterRow(String name) => find.descendant(
  of: find.byType(CategoryFilterSheet),
  matching: find.text(name),
);

/// Opens the Category sheet, ticks [names] (toggling) and taps `Show`.
Future<void> _toggleCategories(
  WidgetTester tester,
  String chip,
  List<String> names,
) async {
  await _tapChip(tester, chip);
  for (final name in names) {
    await tester.tap(_filterRow(name));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text('Show'));
  await tester.pumpAndSettle();
}

Future<void> _pickType(WidgetTester tester, String name) async {
  await _tapChip(tester, 'Type: All');
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

/// Dates → Custom range → taps [first] and [last] (day numbers; the last
/// month built by the picker is the one with the later date) → Save.
Future<void> _pickRange(
  WidgetTester tester,
  String chip,
  String first,
  String last, {
  bool firstIsLastBuilt = true,
  bool lastIsLastBuilt = true,
}) async {
  await _tapChip(tester, chip);
  await tester.tap(find.text('Custom range'));
  await tester.pumpAndSettle();
  final start = find.text(first);
  await tester.tap(firstIsLastBuilt ? start.last : start.first);
  await tester.pump();
  final end = find.text(last);
  await tester.tap(lastIsLastBuilt ? end.last : end.first);
  await tester.pump();
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

/// A fixture with the stored months of [months] (oldest first) and today.
Phase3Fixture _months(
  CalendarDate today,
  List<(BudgetMonth, List<FixtureEntry>)> months,
) => Phase3Fixture(
  name: 'two months with a gap',
  today: today,
  months: [
    for (final (month, entries) in months)
      FixtureMonth(
        month: month,
        firstBudgetedDay: month.start,
        periods: [
          period(
            month.start,
            e2Values(),
            changedAt: at(month.start.addDays(-1), 0),
          ),
        ],
        entries: entries,
      ),
  ],
);

void main() {
  testWidgets('TC-015-10 no results with filters offers clear all', (
    tester,
  ) async {
    await _open(tester, fixtureA);
    await _toggleCategories(tester, 'Category: All', ['Food']);
    expect(find.text('Category: Food'), findsOneWidget);
    expect(find.text('No spends match your filters.'), findsOneWidget);
    await _search(tester, 'taxi');
    expect(
      find.text('No spends match your search and filters.'),
      findsOneWidget,
    );
    expect(find.text('Clear search'), findsNothing);
    expect(find.text('Clear all'), findsWidgets);
    // (b) Clear the search with its x: the filters stay.
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('No spends match your filters.'), findsOneWidget);
    expect(find.text('Clear search'), findsNothing);
    expect(find.text('Category: Food'), findsOneWidget);
  });

  testWidgets('TC-015-11 the dates sheet lists the months and their ranges', (
    tester,
  ) async {
    await _open(tester, fixtureO1);
    await _tapChip(tester, 'Dates: This month');
    expect(find.text('Show spends from'), findsOneWidget);
    expect(find.text('This month'), findsOneWidget);
    expect(find.text('5 Nov – 4 Dec'), findsOneWidget);
    expect(find.text('Last month'), findsOneWidget);
    expect(find.text('5 Oct – 4 Nov'), findsOneWidget);
    expect(find.text('Custom range'), findsOneWidget);
    expect(find.text('Pick the first and last day'), findsOneWidget);
    await tester.tap(find.text('Last month'));
    await tester.pumpAndSettle();
    expect(findCopy('3 results · spent ₹2,250'), findsOneWidget);
    for (final day in ['Sat, 10 Oct', 'Tue, 20 Oct', 'Wed, 4 Nov']) {
      expect(find.text(day), findsOneWidget);
    }
    expect(find.text('Wed, 11 Nov'), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp('Dates, Last month, filter on, button')),
      findsOneWidget,
      reason: 'the chip is on now',
    );
  });

  testWidgets('TC-015-12 custom range spanning two months shows separators', (
    tester,
  ) async {
    await _open(tester, fixtureO1);
    await _pickRange(tester, 'Dates: This month', '1', '13');
    expect(find.text('Dates: 1 Nov – 13 Nov'), findsOneWidget);
    expect(find.text('November · 5 Nov – 4 Dec'), findsOneWidget);
    expect(findCopy('10 results · spent ₹5,780'), findsOneWidget);
    expect(find.text('November · 5 Nov – 4 Dec'), findsOneWidget);
    // October's separator comes after November's days, above the 4 Nov row.
    await tester.scrollUntilVisible(
      find.text('Wed, 4 Nov'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('October · 5 Oct – 4 Nov'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('October · 5 Oct – 4 Nov')).dy,
      lessThan(tester.getTopLeft(find.text('Wed, 4 Nov')).dy),
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 5000));
    await tester.pumpAndSettle();
    expect(find.text('Sat, 10 Oct'), findsNothing);
    expect(find.text('Tue, 20 Oct'), findsNothing);
    // Inside one month there is no separator.
    await _pickRange(tester, 'Dates: 1 Nov – 13 Nov', '9', '9');
    expect(find.textContaining(' · 5 '), findsNothing);
  });

  testWidgets('TC-015-13 custom range picker stops at the first stored month '
      'and today', (tester) async {
    await _open(tester, fixtureO1);
    await _tapChip(tester, 'Dates: This month');
    await tester.tap(find.text('Custom range'));
    await tester.pumpAndSettle();
    final picker = tester.widget<DateRangePickerDialog>(
      find.byType(DateRangePickerDialog),
    );
    expect(picker.firstDate, DateTime(2026, 10, 5));
    expect(picker.lastDate, DateTime(2026, 11, 13));
    expect(find.text('Pick the first and last day'), findsWidgets);
    await tester.tap(find.byTooltip('Close').first);
    await tester.pumpAndSettle();

    // Only A stored: Last month is not available.
    await tester.pumpWidget(const SizedBox());
    await _open(tester, fixtureA);
    await _tapChip(tester, 'Dates: This month');
    expect(find.text('No earlier month yet'), findsOneWidget);
    await tester.tap(find.text('Last month'));
    await tester.pumpAndSettle();
    expect(find.text('Show spends from'), findsOneWidget, reason: 'disabled');
  });

  testWidgets('TC-015-14 category filter treats missing category as other', (
    tester,
  ) async {
    await _open(tester, fixtureAF);
    await _tapChip(tester, 'Category: All');
    expect(find.text('Show categories'), findsOneWidget);
    expect(
      find.text('Spends without a category count as Other.'),
      findsOneWidget,
    );
    for (final name in [
      'Food',
      'Groceries',
      'Shopping',
      'Travel',
      'Bills & Recharge',
      'Entertainment',
      'Health',
      'Friends & People',
      'Other',
    ]) {
      expect(_filterRow(name), findsOneWidget, reason: name);
    }
    expect(find.text('Show'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
    await tester.tap(_filterRow('Food'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    expect(find.text('Category: Food'), findsOneWidget);
    expect(findCopy('2 results · spent ₹670'), findsOneWidget);

    // Other only: untick Food, tick Other.
    await _toggleCategories(tester, 'Category: Food', ['Food', 'Other']);
    expect(find.text('Category: Other'), findsOneWidget);
    expect(findCopy('7 results · spent ₹4,860'), findsOneWidget);

    // Food and Other together.
    await _toggleCategories(tester, 'Category: Other', ['Food']);
    expect(find.text('Category: 2 categories'), findsOneWidget);
    expect(findCopy('9 results · spent ₹5,530'), findsOneWidget);
  });

  testWidgets('TC-015-15 category sheet applies only on show', (tester) async {
    await _open(tester, fixtureAF);
    await _tapChip(tester, 'Category: All');
    await tester.tap(_filterRow('Food'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Show categories'), findsNothing);
    expect(find.text('Category: All'), findsOneWidget, reason: 'scrim');

    await _tapChip(tester, 'Category: All');
    await tester.tap(_filterRow('Food'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Category: All'), findsOneWidget, reason: 'back');

    await _toggleCategories(tester, 'Category: All', ['Food']);
    expect(find.text('Category: Food'), findsOneWidget);
    await _tapChip(tester, 'Category: Food');
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('Category: All'), findsOneWidget);
    expect(find.text('Clear all'), findsNothing);
  });

  testWidgets('TC-015-17 day total is net of refunds', (tester) async {
    await _open(tester, fixtureAPlusRefund);
    expect(findCopy('−₹80'), findsOneWidget);
    final semantics = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(RegExp('Refund, ₹500, Amazon return, Friday 13 N')),
      findsOneWidget,
    );
    expect(findCopy('+₹500'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('TC-015-18 clear all resets search and every filter', (
    tester,
  ) async {
    final fixture = fixtureO1.mapEntries(
      'AF + O1',
      (entry) =>
          entry.note == 'Lunch' ? entry.copyWith(categoryKey: 'food') : entry,
    );
    await _open(tester, fixture);
    await _toggleCategories(tester, 'Category: All', ['Food']);
    await _search(tester, 'lunch');
    await _tapChip(tester, 'Dates: This month');
    await tester.tap(find.text('Last month'));
    await tester.pumpAndSettle();
    expect(
      find.text('No spends match your search and filters.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Clear all').first);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      '',
    );
    for (final chip in ['Dates: This month', 'Category: All', 'Type: All']) {
      expect(find.text(chip), findsOneWidget);
    }
    expect(find.text('Clear all'), findsNothing);
    expect(find.textContaining('result'), findsNothing);
    expect(find.text('Phone bill'), findsOneWidget);
    expect(find.text('Thu, 5 Nov'), findsOneWidget);
  });

  testWidgets('TC-015-25 filters survive a tab switch but not a restart', (
    tester,
  ) async {
    await _open(tester, fixtureAF);
    await _search(tester, 'lunch');
    await _toggleCategories(tester, 'Category: All', ['Food']);
    await tapTab(tester, 'Home');
    await tapTab(tester, 'Transactions');
    expect(find.text('Category: Food'), findsOneWidget);
    expect(findCopy('2 results · spent ₹670'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'lunch',
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await _open(tester, fixtureAF);
    expect(find.text('Category: All'), findsOneWidget);
    expect(find.text('Dates: This month'), findsOneWidget);
    expect(find.text('Type: All'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      '',
    );
  });

  testWidgets('TC-015-67 filters and search text outlive a rebuilt tab', (
    tester,
  ) async {
    // The bare tab on a container the test owns, so the same provider scope
    // can host a new tab widget (the shell's IndexedStack never rebuilds it).
    final fixture = fixtureAF;
    setUpScreen(tester, size: const Size(400, 1800));
    final money = storeFor(fixture);
    final clock = TestClock(fixture.now);
    final preferences = InMemoryPreferencesStore.allowing(
      PreferenceKeys.allowList,
    );
    for (final id in HintId.values) {
      await preferences.writeBool(PreferenceKeys.hintSeen(id), value: true);
    }
    final container = ProviderContainer(
      overrides: [
        preferencesStoreProvider.overrideWithValue(preferences),
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
    final theme = themeConfigFor(ThemeChoice.light);
    Widget host(Widget home) => UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: theme.light,
        home: Scaffold(body: home),
      ),
    );
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(host(TransactionsTab(controller: controller)));
    await tester.pumpAndSettle();

    await _search(tester, 'lunch');
    await _toggleCategories(tester, 'Category: All', ['Food']);
    expect(find.text('Category: Food'), findsOneWidget);
    expect(findCopy('2 results · spent ₹670'), findsOneWidget);

    await tester.pumpWidget(host(const SizedBox()));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionsTab), findsNothing);
    await tester.pumpWidget(host(TransactionsTab(controller: controller)));
    await tester.pumpAndSettle();

    expect(find.text('Category: Food'), findsOneWidget);
    expect(findCopy('2 results · spent ₹670'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'lunch',
    );
    // The midnight timer of the clock provider must be gone before the test
    // ends.
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });

  testWidgets('TC-015-44 a one day custom range', (tester) async {
    await _open(tester, fixtureA);
    await _pickRange(tester, 'Dates: This month', '9', '9');
    expect(find.text('Dates: 9 Nov'), findsOneWidget);
    expect(findCopy('2 results · spent ₹620'), findsOneWidget);
    expect(find.text('Mon, 9 Nov'), findsOneWidget);
    expect(find.text('Tue, 10 Nov'), findsNothing);
  });

  testWidgets('TC-015-47 a missed month has no separator', (tester) async {
    final fixture = _months(d(2026, 10, 20), [
      (
        BudgetMonth.startIn(5, 2026, 8),
        [fixtureSpend(d(2026, 8, 25), 40000, note: 'August trip')],
      ),
      (oct2026, [fixtureSpend(d(2026, 10, 10), 60000, note: 'October rent')]),
    ]);
    await _open(tester, fixture);
    await _pickRange(
      tester,
      'Dates: This month',
      '20',
      '20',
      firstIsLastBuilt: false,
    );
    // The picker builds August, September and October; the first 20 is
    // August's and the last is October's.
    expect(find.text('Dates: 20 Aug – 20 Oct'), findsOneWidget);
    expect(find.text('October · 5 Oct – 4 Nov'), findsOneWidget);
    expect(find.text('August · 5 Aug – 4 Sep'), findsOneWidget);
    expect(find.textContaining('September'), findsNothing);
    expect(find.text('August trip'), findsOneWidget);
    expect(find.text('October rent'), findsOneWidget);
  });

  testWidgets('TC-015-48 filters survive midnight and the month follows', (
    tester,
  ) async {
    final clock = TestClock(DateTime(2026, 11, 13, 23, 59));
    await pumpTransactions(
      tester,
      money: storeFor(fixtureAF),
      clock: clock,
      size: const Size(400, 1800),
    );
    await _search(tester, 'lunch');
    expect(find.text('Today'), findsWidgets);
    expect(find.text('Yesterday'), findsNothing);
    sendToBackground(tester);
    clock.now = DateTime(2026, 11, 14, 0, 1);
    bringToForeground(tester);
    await tester.pump(const Duration(minutes: 2));
    await tester.pumpAndSettle();
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Dates: This month'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'lunch',
    );
    expect(findCopy('2 results · spent ₹670'), findsOneWidget);
  });

  testWidgets('TC-015-49 a new month that is not set up defaults to last '
      'month', (tester) async {
    final store = e2Store();
    addSpendTo(store, d(2026, 11, 20), 52000, note: 'Groceries');
    await pumpTransactions(
      tester,
      money: store,
      clock: TestClock(DateTime(2026, 12, 5, 10)),
      size: const Size(400, 1800),
    );
    expect(find.text('Dates: Last month'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Set up your new month first'), findsWidgets);
    expect(
      find.text('Other'),
      findsOneWidget,
      reason: 'the row keeps its chip',
    );
    expect(find.byIcon(Icons.check), findsNothing, reason: 'not active styled');
    final semantics = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(RegExp('Dates, Last month, filter, button')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('TC-015-51 refunds are listed in a shortfall month', (
    tester,
  ) async {
    final fixture = fixtureS.plus(
      name: 'S + refund',
      entries: [
        fixtureMoneyIn(d(2026, 11, 7), 50000, note: 'Shop refund'),
        fixtureSpend(d(2026, 11, 7), 20000, note: 'Tea', hour: 13),
      ],
    );
    await _open(tester, fixture);
    await _pickType(tester, 'Refunds');
    expect(find.text('Shop refund'), findsOneWidget);
    expect(find.text('Refund'), findsOneWidget);
    expect(findCopy('+₹500'), findsOneWidget);
    expect(find.text('Tea'), findsNothing);
    expect(findCopy('1 result · refunds ₹500'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('TC-015-52 results line shows spent and refunds together', (
    tester,
  ) async {
    await _open(tester, fixtureAPlusRefund);
    await _search(tester, 'a');
    expect(findCopy('2 results · spent ₹200 · refunds ₹500'), findsOneWidget);
    expect(find.text('Chai and snacks'), findsOneWidget);
    expect(find.text('Amazon return'), findsOneWidget);
  });

  testWidgets('TC-015-63 dates sheet in a month that is not set up', (
    tester,
  ) async {
    await _open(tester, fixtureA.copyWith(today: d(2026, 12, 5)));
    expect(find.text('Dates: Last month'), findsOneWidget);
    expect(find.text('Phone bill', skipOffstage: false), findsOneWidget);
    await _tapChip(tester, 'Dates: Last month');
    expect(find.text('Set up your month first'), findsOneWidget);
    final semantics = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(
        RegExp('This month, not available, Set up your month first'),
      ),
      findsOneWidget,
    );
    semantics.dispose();
    await tester.tap(find.text('This month'));
    await tester.pumpAndSettle();
    expect(find.text('Show spends from'), findsOneWidget, reason: 'disabled');
    expect(_selectedRows(tester), ['Last month']);
  });

  testWidgets('TC-015-16 type filter keeps spends apart from refunds', (
    tester,
  ) async {
    await _open(tester, fixtureAPlusRefund);
    await _tapChip(tester, 'Type: All');
    expect(find.text('Show'), findsOneWidget);
    expect(
      find.text(
        'Refunds are money paid back to you. They lower what you spent '
        'that day.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Spends'));
    await tester.pumpAndSettle();
    expect(find.text('Type: Spends'), findsOneWidget);
    expect(findCopy('9 results · spent ₹5,530'), findsOneWidget);
    expect(find.text('Amazon return'), findsNothing);
    await _tapChip(tester, 'Type: Spends');
    await tester.tap(find.text('All').last);
    await tester.pumpAndSettle();
    await _search(tester, 'amazon');
    expect(findCopy('1 result · refunds ₹500'), findsOneWidget);
    expect(find.text('Amazon return'), findsOneWidget);
  });
}

/// The labels of the selected rows of the open Dates sheet.
List<String> _selectedRows(WidgetTester tester) {
  final selected = <String>[];
  for (final label in ['This month', 'Last month', 'Custom range']) {
    final node = tester.getSemantics(find.text(label).last);
    if (node.getSemanticsData().flagsCollection.isSelected == Tristate.isTrue) {
      selected.add(label);
    }
  }
  return selected;
}
