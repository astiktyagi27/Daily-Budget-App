// F-015 test cases for changing a category from a list row: the sheet, the
// snackbar with Undo, past months, filtered lists, order, `Other`, a failed
// save and the Dashboard (tests/F-015 TC-015-20 to -24, -46, -53, -55, -56).

import 'package:daily_budget/core/widgets/category_chip.dart';
import 'package:daily_budget/data/repositories/transaction_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/transactions/sheets/category_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_money_store.dart';
import '../../helpers/phase3_data.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../helpers/shell.dart';
import '../../helpers/transactions_harness.dart';
import '../../support/find_copy.dart';

Future<void> _open(
  WidgetTester tester,
  Phase3Fixture fixture,
  FakeMoneyStore store,
) => pumpTransactions(
  tester,
  money: store,
  clock: TestClock(fixture.now),
  size: const Size(400, 1800),
);

/// The category chip under the row whose note is [note] (the lowest match).
Finder _chipOf(WidgetTester tester, String note) {
  final noteTop = tester.getTopLeft(find.text(note).last).dy;
  final chips = find.byType(CategoryChip).evaluate().toList();
  Element? best;
  var bestGap = double.infinity;
  for (final chip in chips) {
    final gap = (tester.getTopLeft(find.byWidget(chip.widget)).dy) - noteTop;
    if (gap >= 0 && gap < bestGap) {
      best = chip;
      bestGap = gap;
    }
  }
  return find.byWidget(best!.widget);
}

Future<void> _pick(WidgetTester tester, Finder chip, String name) async {
  await tester.tap(chip);
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

List<SpendCategory?> _categories(FakeMoneyStore store) => [
  for (final s in storedSpends(store)) s.spend.category,
];

StoredSpend _spend(FakeMoneyStore store, String note, {int? paise}) =>
    storedSpends(store).firstWhere(
      (s) => s.note == note && (paise == null || s.spend.amount.value == paise),
    );

void main() {
  testWidgets('TC-015-20 category sheet lists nine categories with the '
      'current one ticked', (tester) async {
    final store = storeFor(fixtureA);
    await _open(tester, fixtureA, store);
    await tester.tap(_chipOf(tester, 'Lunch'));
    await tester.pumpAndSettle();
    expect(findCopy('Category for ₹250 · Lunch'), findsOneWidget);
    expect(
      find.text('Only this spend changes. Automatic categories come later.'),
      findsOneWidget,
    );
    final semantics = tester.ensureSemantics();
    for (final name in [
      'Food',
      'Groceries',
      'Shopping',
      'Travel',
      'Bills & Recharge',
      'Entertainment',
      'Health',
      'Friends & People',
    ]) {
      expect(find.bySemanticsLabel('$name, category'), findsOneWidget);
    }
    expect(find.bySemanticsLabel('Other, category, selected'), findsOneWidget);
    semantics.dispose();
    expect(find.text('Done'), findsOneWidget);
    // Nine rows in README order, top to bottom.
    final tops = [
      for (final name in [
        'Food',
        'Groceries',
        'Shopping',
        'Travel',
        'Bills & Recharge',
        'Entertainment',
        'Health',
        'Friends & People',
      ])
        tester.getTopLeft(find.text(name).last).dy,
    ];
    expect(tops, orderedEquals([...tops]..sort()));
    await tester.tap(find.text('Food').last);
    await tester.pumpAndSettle();
    expect(find.text('Moved to Food'), findsOneWidget);
    expect(_spend(store, 'Lunch', paise: 42000).spend.category, isNull);
    // The 9 Nov Lunch is the one that changed.
    expect(
      [for (final s in storedSpends(store)) s.spend.category]
          .whereType<Object>(),
      hasLength(1),
    );
    expect(
      storedSpends(store)
          .singleWhere((s) => s.spend.category == SpendCategory.food)
          .spend
          .amount
          .value,
      25000,
    );
  });

  testWidgets('TC-015-21 undo restores the previous value and the same pick is '
      'a no op', (tester) async {
    final store = storeFor(fixtureA);
    await _open(tester, fixtureA, store);
    await _pick(tester, _chipOf(tester, 'Phone bill'), 'Food');
    expect(find.text('Moved to Food'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(_categories(store), everyElement(isNull), reason: 'not other');

    // (b) The snackbar leaves after 6 s and the value stays.
    await _pick(tester, _chipOf(tester, 'Phone bill'), 'Food');
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Undo'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsNothing);
    expect(_spend(store, 'Phone bill').spend.category, SpendCategory.food);

    // (c) The ticked category again: closed, no snackbar, no change.
    await _pick(tester, _chipOf(tester, 'Phone bill'), 'Food');
    expect(find.textContaining('Moved to'), findsNothing);
    expect(_spend(store, 'Phone bill').spend.category, SpendCategory.food);
  });

  testWidgets('TC-015-21 undo is gone six seconds after the change without a '
      'screen reader', (tester) async {
    final store = storeFor(fixtureA);
    await _open(tester, fixtureA, store);
    await _pick(tester, _chipOf(tester, 'Phone bill'), 'Food');
    // The timer starts after the 250 ms slide in: 5.75 s + 0.25 s = 6 s.
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).duration,
      const Duration(milliseconds: 5750),
    );
    await tester.pump(const Duration(seconds: 6, milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsNothing);
    expect(find.text('Moved to Food'), findsNothing);
    expect(_spend(store, 'Phone bill').spend.category, SpendCategory.food);
  });

  testWidgets('TC-015-21 undo stays while a screen reader is on', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(accessibleNavigation: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final store = storeFor(fixtureA);
    await _open(tester, fixtureA, store);
    await _pick(tester, _chipOf(tester, 'Phone bill'), 'Food');
    await tester.pump(const Duration(seconds: 30));
    await tester.pump();
    expect(find.text('Undo'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(_categories(store), everyElement(isNull));
  });

  testWidgets('TC-015-23 a category change reaches the dashboard', (
    tester,
  ) async {
    final store = storeFor(fixtureA);
    await _open(tester, fixtureA, store);
    await tapTab(tester, 'Dashboard');
    await tapTab(tester, 'Transactions');
    await _pick(tester, _chipOf(tester, 'Shoes'), 'Shopping');
    await tapTab(tester, 'Dashboard');
    expect(findCopy('Shopping'), findsOneWidget);
    expect(findCopy('₹1,000'), findsWidgets);
    expect(findCopy('₹4,530'), findsOneWidget);
  });

  testWidgets('TC-015-24 past month rows allow a category change only', (
    tester,
  ) async {
    final store = storeFor(fixtureO1);
    await _open(tester, fixtureO1, store);
    await tester.tap(find.text('Dates: This month'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last month'));
    await tester.pumpAndSettle();
    final chip = find.byType(CategoryChip).last; // Sat 10 Oct, the oldest
    await _pick(tester, chip, 'Travel');
    expect(find.text('Moved to Travel'), findsOneWidget);
    expect(find.text('Travel'), findsOneWidget);
    // The rest of the row opens nothing and has no Edit hint.
    await tester.tap(find.text('No note').last);
    await tester.pumpAndSettle();
    expect(find.text('Edit spend'), findsNothing);
    expect(find.text('Category'), findsNothing);
    final editable = find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.hint == 'Edit',
    );
    expect(editable, findsNothing);
    final oct = storedSpends(store)
        .where((s) => s.spend.date.month == 10 && s.spend.date.day == 10);
    expect(oct.single.spend.category, SpendCategory.travel);
  });

  testWidgets('TC-015-46 a row changed out of a filter returns on undo', (
    tester,
  ) async {
    final store = storeFor(fixtureAF);
    await _open(tester, fixtureAF, store);
    await tester.ensureVisible(find.text('Category: All'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Category: All'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(CategoryFilterSheet),
        matching: find.text('Food'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    expect(findCopy('2 results · spent ₹670'), findsOneWidget);
    await _pick(tester, find.byType(CategoryChip).last, 'Travel');
    expect(findCopy('1 result · spent ₹420'), findsOneWidget);
    expect(find.text('Mon, 9 Nov'), findsNothing);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(findCopy('2 results · spent ₹670'), findsOneWidget);
    expect(find.text('Mon, 9 Nov'), findsOneWidget);
  });

  testWidgets('TC-015-53 editing never reorders a day', (tester) async {
    final store = storeFor(fixtureA);
    await _open(tester, fixtureA, store);
    double top(String text) => tester.getTopLeft(findCopy(text)).dy;
    expect(top('₹370'), lessThan(top('₹250')));
    await _pick(tester, _chipOf(tester, 'Lunch'), 'Food');
    expect(top('₹370'), lessThan(top('₹250')));
    // Edit the note of the 9 Nov Lunch.
    await tester.tap(find.text('Lunch').last);
    await tester.pumpAndSettle();
    expect(find.text('Edit spend'), findsOneWidget);
    await tester.enterText(noteInput, 'Late lunch');
    await tester.pump();
    await tapLabel(tester, 'Save changes');
    expect(find.text('Late lunch'), findsOneWidget);
    expect(top('₹370'), lessThan(top('₹250')));
    expect(
      tester.getTopLeft(find.text('No note')).dy,
      lessThan(tester.getTopLeft(find.text('Late lunch')).dy),
    );
  });

  testWidgets('TC-015-55 picking other after a category reads as other '
      'everywhere', (tester) async {
    final store = storeFor(fixtureAF);
    await _open(tester, fixtureAF, store);
    await _pick(tester, _chipOf(tester, 'Lunch'), 'Other');
    expect(find.text('Moved to Other'), findsOneWidget);
    expect(
      _spend(store, 'Lunch', paise: 25000).spend.category,
      SpendCategory.other,
    );
    expect(
      _spend(store, 'Lunch', paise: 42000).spend.category,
      SpendCategory.food,
    );
    await tester.ensureVisible(find.text('Category: All'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Category: All'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(CategoryFilterSheet),
        matching: find.text('Other'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    expect(findCopy('8 results · spent ₹5,110'), findsOneWidget);
  });

  testWidgets('TC-015-56 a failed category save keeps the old value', (
    tester,
  ) async {
    final store = storeFor(fixtureA);
    await _open(tester, fixtureA, store);
    store.failNextWrite = true;
    await _pick(tester, _chipOf(tester, 'Phone bill'), 'Food');
    expect(find.text("Couldn't save. Please try again."), findsOneWidget);
    expect(find.text('Moved to Food'), findsNothing);
    expect(_categories(store), everyElement(isNull));
    expect(find.text('Food'), findsNothing, reason: 'the chip kept Other');
  });
}
