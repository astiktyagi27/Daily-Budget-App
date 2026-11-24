// F-015 test cases for the Category row of the Add / Edit spend screen
// (tests/F-015 TC-015-30 to -34, -57, -64).

import 'package:daily_budget/data/repositories/transaction_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/transactions/widgets/category_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/phase3_data.dart';
import '../../helpers/phase3_fixtures.dart';
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

Finder get _field => find.byType(CategoryField);

/// The tappable row of the field (the label above it is not).
Finder get _fieldRow =>
    find.descendant(of: _field, matching: find.byType(InkWell));

Finder _fieldText(String name) =>
    find.descendant(of: _field, matching: find.text(name));

Future<void> _pickInEditor(WidgetTester tester, String name) async {
  await tester.ensureVisible(_field);
  await tester.pumpAndSettle();
  await tester.tap(_fieldRow);
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

Finder get _saveButton => find.ancestor(
  of: find.text('Save changes'),
  matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
);

StoredSpend _lunch(FakeMoneyStore store) =>
    storedSpends(store)
        .firstWhere((s) => s.note == 'Lunch' && s.spend.amount.value == 25000);

void main() {
  testWidgets('TC-015-31 an untouched category stores nothing', (tester) async {
    final store = storeFor(fixtureA);
    await _open(tester, fixtureA, store);
    await tester.tap(addSpendButton);
    await tester.pumpAndSettle();
    expect(_fieldText('Other'), findsOneWidget);
    await typeInto(tester, amountInput, '250');
    await typeInto(tester, noteInput, 'Tea');
    await tapLabel(tester, 'Save');
    final added = storedSpends(store).last;
    expect(added.note, 'Tea');
    expect(added.spend.category, isNull);
    expect(find.text('Tea'), findsOneWidget);
  });

  testWidgets('TC-015-32 the category row is hidden for money back', (
    tester,
  ) async {
    final store = storeFor(fixtureA);
    await _open(tester, fixtureA, store);
    await tester.tap(addSpendButton);
    await tester.pumpAndSettle();
    await _pickInEditor(tester, 'Food');
    expect(_fieldText('Food'), findsOneWidget);
    await tester.tap(find.text('Money back / refund'));
    await tester.pumpAndSettle();
    expect(_field, findsNothing, reason: 'hidden while on');
    await tester.tap(find.text('Money back / refund'));
    await tester.pumpAndSettle();
    expect(_fieldText('Food'), findsOneWidget, reason: 'kept in the draft');
    await tester.tap(find.text('Money back / refund'));
    await tester.pumpAndSettle();
    await typeInto(tester, amountInput, '500');
    await tapLabel(tester, 'Save');
    final added = storedSpends(store).last.spend;
    expect(added.direction, SpendDirection.moneyIn);
    expect(added.category, isNull);
  });

  testWidgets('TC-015-33 editing the category saves it and moves nothing', (
    tester,
  ) async {
    final store = storeFor(fixtureAF);
    await _open(tester, fixtureAF, store);
    await tester.tap(find.text('Lunch').last);
    await tester.pumpAndSettle();
    expect(find.text('Edit spend'), findsOneWidget);
    expect(_fieldText('Food'), findsOneWidget);
    expect(tester.widget<ButtonStyleButton>(_saveButton).onPressed, isNull);
    await _pickInEditor(tester, 'Shopping');
    expect(_fieldText('Shopping'), findsOneWidget);
    expect(tester.widget<ButtonStyleButton>(_saveButton).onPressed, isNotNull);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    await tapLabel(tester, 'Save changes');
    final saved = _lunch(store).spend;
    expect(saved.category, SpendCategory.shopping);
    expect((saved.amount.value, saved.date), (25000, d(2026, 11, 9)));
    expect(find.text('Spend updated'), findsOneWidget);
    // The 9 Nov row keeps its place: the 370 entry is still first.
    expect(
      tester.getTopLeft(findCopy('₹370')).dy,
      lessThan(tester.getTopLeft(findCopy('₹250')).dy),
    );
    expect(findCopy('₹620'), findsOneWidget, reason: 'day total unchanged');
  });

  testWidgets('TC-015-34 editor category sheet changes the field only', (
    tester,
  ) async {
    final store = storeFor(fixtureA);
    await _open(tester, fixtureA, store);
    await tester.tap(find.text('Lunch').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(_field);
    await tester.pumpAndSettle();
    await tester.tap(_fieldRow);
    await tester.pumpAndSettle();
    expect(find.text('Category'), findsWidgets);
    expect(
      find.text('Only this spend changes. Automatic categories come later.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Travel').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Only this spend changes. Automatic categories come later.'),
      findsNothing,
    );
    expect(_fieldText('Travel'), findsOneWidget);
    expect(_lunch(store).spend.category, isNull, reason: 'nothing saved yet');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Edit spend'), findsNothing);
    expect(_lunch(store).spend.category, isNull);
  });

  testWidgets('TC-015-57 a chosen category counts as input when leaving add', (
    tester,
  ) async {
    final store = storeFor(fixtureA);
    await _open(tester, fixtureA, store);
    await tester.tap(addSpendButton);
    await tester.pumpAndSettle();
    await _pickInEditor(tester, 'Food');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Discard this spend?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Add spend'), findsOneWidget, reason: 'back on the tab');
    expect(storedSpends(store), hasLength(9));
  });

  testWidgets('TC-015-64 reopening other on an untouched spend is no change', (
    tester,
  ) async {
    final store = storeFor(fixtureA);
    await _open(tester, fixtureA, store);
    await tester.tap(find.text('Lunch').last);
    await tester.pumpAndSettle();
    expect(_fieldText('Other'), findsOneWidget);
    await tester.ensureVisible(_field);
    await tester.pumpAndSettle();
    await tester.tap(_fieldRow);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Only this spend changes. Automatic categories come later.'),
      findsNothing,
    );
    expect(tester.widget<ButtonStyleButton>(_saveButton).onPressed, isNull);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsNothing);
    expect(find.text('Edit spend'), findsNothing);

    // A spend stored as Food: picking Other is a change and stores `other`.
    await tester.pumpWidget(const SizedBox());
    final foodStore = storeFor(fixtureAF);
    await _open(tester, fixtureAF, foodStore);
    await tester.tap(find.text('Lunch').last);
    await tester.pumpAndSettle();
    await _pickInEditor(tester, 'Other');
    expect(tester.widget<ButtonStyleButton>(_saveButton).onPressed, isNotNull);
    await tapLabel(tester, 'Save changes');
    expect(_lunch(foodStore).spend.category, SpendCategory.other);
  });

  testWidgets('TC-015-30 add spend stores the chosen category', (tester) async {
    final store = storeFor(fixtureA);
    await _open(tester, fixtureA, store);
    await tester.tap(addSpendButton);
    await tester.pumpAndSettle();
    expect(find.text('Category'), findsWidgets);
    await typeInto(tester, amountInput, '250');
    await tester.ensureVisible(find.text('Other').last);
    await tester.tap(find.text('Other').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    await tapLabel(tester, 'Save');
    final added = storedSpends(store).last.spend;
    expect((added.amount.value, added.category), (25000, SpendCategory.food));
  });
}
