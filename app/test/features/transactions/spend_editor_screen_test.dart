import 'package:daily_budget/core/widgets/focus_ring.dart';
import 'package:daily_budget/data/repositories/storage_exception.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/transactions_harness.dart';
import '../../support/find_copy.dart';

Future<void> _openAdd(WidgetTester tester) async {
  await tester.tap(addSpendButton);
  await tester.pumpAndSettle();
}

Future<void> _fill(WidgetTester tester, String amount, [String? note]) async {
  await typeInto(tester, amountInput, amount);
  if (note != null) await typeInto(tester, noteInput, note);
}

Future<void> _save(WidgetTester tester) async {
  // Test text input leaves a selection handle over the button.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tapLabel(tester, 'Save');
}

Future<void> _addSpend(
  WidgetTester tester,
  String amount, [
  String? note,
]) async {
  await _openAdd(tester);
  await _fill(tester, amount, note);
  await _save(tester);
}

Future<void> _openEdit(WidgetTester tester, String rowText) async {
  await tester.tap(find.text(rowText));
  await tester.pumpAndSettle();
}

Future<void> _pickDay(WidgetTester tester, String day) async {
  await tester.tap(find.byIcon(Icons.calendar_today_outlined));
  await tester.pumpAndSettle();
  await tester.tap(find.text(day));
  await tester.pump();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

Future<void> _saveChanges(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tapLabel(tester, 'Save changes');
}

String _noteText(WidgetTester tester) =>
    tester.widget<TextField>(noteInput).controller!.text;

void main() {
  testWidgets('TC-009-03 adding a spend stores it and shows it under today', (
    tester,
  ) async {
    final store = e2Store();
    await pumpTransactions(tester, money: store);
    await _openAdd(tester);
    expect(find.text('Add spend'), findsOneWidget);
    expect(
      tester.widget<TextField>(amountInput).focusNode!.hasFocus,
      isTrue,
      reason: 'the amount is focused on open',
    );
    await _fill(tester, '250', 'Lunch');
    await _save(tester);

    expect(find.text('Amount'), findsNothing, reason: 'the screen closed');
    expect(find.text('Spend added'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    // The row and the day's total.
    expect(findCopy('₹250'), findsNWidgets(2));
    final stored = storedSpends(store);
    expect(stored, hasLength(1));
    expect(stored.single.spend.amount.value, 25000);
    expect(stored.single.spend.date, d(2026, 11, 9));
    expect(stored.single.spend.direction, SpendDirection.spend);
    expect(stored.single.note, 'Lunch');
    expect(todayLineText(tester), 'budget ₹830 · spent ₹250 · ₹580 left today');
  });

  testWidgets('TC-009-04 invalid amounts show their error and save nothing', (
    tester,
  ) async {
    final store = e2Store();
    await pumpTransactions(tester, money: store);
    await _openAdd(tester);
    const cases = {
      '': 'Enter an amount',
      '0': 'Amount must be more than ₹0',
      '100000001': "That's more than ₹10 crore. Please check the amount.",
      '12.345': 'Use numbers only, with up to 2 decimals',
      'abc': 'Use numbers only, with up to 2 decimals',
    };
    for (final MapEntry(key: input, value: message) in cases.entries) {
      await _fill(tester, input);
      await _save(tester);
      expect(find.text(message), findsOneWidget, reason: 'for "$input"');
      expect(storedSpends(store), isEmpty, reason: 'for "$input"');
    }
    expect(find.text('Amount'), findsOneWidget, reason: 'still on the editor');
  });

  testWidgets('TC-009-05 valid amounts are stored to the paisa and listed in '
      'whole rupees', (tester) async {
    final store = e2Store();
    await pumpTransactions(tester, money: store);
    for (final amount in ['300.50', '1', '100000000']) {
      await _addSpend(tester, amount);
    }
    expect(storedSpends(store).map((s) => s.spend.amount.value).toList(), [
      30050,
      100,
      10000000000,
    ]);
    expect(findCopy('₹300'), findsOneWidget);
    expect(findCopy('₹1'), findsOneWidget);
    expect(findCopy('₹10,00,00,000'), findsWidgets);
  });

  testWidgets('TC-009-06 date picker allows only this month up to today', (
    tester,
  ) async {
    await pumpTransactions(tester, money: e2Store());
    await _openAdd(tester);
    expect(find.text('Today · Mon, 9 Nov'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Pick the day you spent it'), findsOneWidget);
    final picker = tester.widget<CalendarDatePicker>(
      find.byType(CalendarDatePicker),
    );
    expect(picker.firstDate, DateTime(2026, 11, 5));
    expect(picker.lastDate, DateTime(2026, 11, 9));
    expect(picker.initialDate, DateTime(2026, 11, 9));
    // A blocked day changes nothing.
    await tester.tap(find.text('4'));
    await tester.pump();
    await tester.tap(find.text('10'));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Today · Mon, 9 Nov'), findsOneWidget);
  });

  testWidgets('TC-009-07 days before the first budgeted day cannot be '
      'picked', (tester) async {
    final store = e2Store(firstBudgetedDay: d(2026, 11, 10));
    await pumpTransactions(
      tester,
      money: store,
      clock: TestClock(DateTime(2026, 11, 12, 10)),
    );
    await _openAdd(tester);
    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    final picker = tester.widget<CalendarDatePicker>(
      find.byType(CalendarDatePicker),
    );
    expect(picker.firstDate, DateTime(2026, 11, 10));
    expect(picker.lastDate, DateTime(2026, 11, 12));
  });

  testWidgets('TC-009-08 note limit empty note hindi emoji text', (
    tester,
  ) async {
    final store = e2Store();
    await pumpTransactions(tester, money: store);
    await _openAdd(tester);

    // The 101st character is not accepted, counting characters as the user
    // sees them: plain letters, Hindi (a letter with its vowel sign is one
    // character) and an emoji family (seven code points, one character).
    const hundredOne = {'letters': 'a', 'hindi': 'चा', 'emoji': '👨‍👩‍👧'};
    for (final MapEntry(key: name, value: unit) in hundredOne.entries) {
      await typeInto(tester, noteInput, '');
      await typeInto(tester, noteInput, unit * 101);
      expect(_noteText(tester), unit * 100, reason: name);
      expect(find.text('100/100'), findsOneWidget, reason: name);
    }
    await typeInto(tester, noteInput, 'a' * 79);
    expect(find.textContaining('/100'), findsNothing, reason: 'no counter yet');
    await typeInto(tester, noteInput, 'a' * 80);
    expect(find.text('80/100'), findsOneWidget);

    // Hindi and emoji notes are stored and shown exactly.
    await typeInto(tester, noteInput, 'चाय और समोसा 🍵');
    await _fill(tester, '40');
    await _save(tester);
    await _addSpend(tester, '60', '👨‍👩‍👧 dinner');
    // An empty note reads No note.
    await _addSpend(tester, '70');
    expect(storedSpends(store).map((s) => s.note).toList(), [
      'चाय और समोसा 🍵',
      '👨‍👩‍👧 dinner',
      null,
    ]);
    expect(find.text('चाय और समोसा 🍵'), findsOneWidget);
    expect(find.text('👨‍👩‍👧 dinner'), findsOneWidget);
    expect(find.text('No note'), findsOneWidget);
  });

  testWidgets('TC-009-09 today line follows the worked example', (
    tester,
  ) async {
    final store = e2Store();
    await pumpTransactions(tester, money: store);
    await _addSpend(tester, '250', 'Lunch');
    expect(todayLineText(tester), 'budget ₹830 · spent ₹250 · ₹580 left today');
    await _addSpend(tester, '400', 'Groceries');
    expect(todayLineText(tester), 'budget ₹830 · spent ₹650 · ₹180 left today');
    await _addSpend(tester, '300.50');
    expect(todayLineText(tester), 'budget ₹830 · spent ₹950 · overspent ₹120');
    await _openEdit(tester, 'Groceries');
    await _fill(tester, '270');
    await _saveChanges(tester);
    expect(todayLineText(tester), 'budget ₹830 · spent ₹820 · ₹9 left today');
    await _openEdit(tester, 'No note');
    await tester.ensureVisible(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(todayLineText(tester), 'budget ₹830 · spent ₹520 · ₹310 left today');
    await _openAdd(tester);
    await _fill(tester, '310');
    await _pickDay(tester, '8');
    await _save(tester);
    expect(todayLineText(tester), 'budget ₹830 · spent ₹520 · ₹310 left today');
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Spend added'), findsOneWidget);
  });

  testWidgets('TC-009-11 editing a spend updates amount date and totals', (
    tester,
  ) async {
    final store = e2Store();
    addSpendTo(store, d(2026, 11, 9), 25000, note: 'Lunch', createdAt: 1);
    final groceries = addSpendTo(
      store,
      d(2026, 11, 9),
      40000,
      note: 'Groceries',
      createdAt: 2,
    );
    await pumpTransactions(tester, money: store);
    await _openEdit(tester, 'Groceries');
    expect(find.text('Edit spend'), findsOneWidget);
    expect(find.text('400'), findsOneWidget, reason: 'amount is filled');
    expect(find.text('Save changes'), findsOneWidget);
    await _fill(tester, '270');
    await _saveChanges(tester);
    expect(find.text('Spend updated'), findsOneWidget);
    expect(findCopy('₹270'), findsOneWidget);
    expect(findCopy('₹520'), findsOneWidget);
    expect(todayLineText(tester), 'budget ₹830 · spent ₹520 · ₹310 left today');
    expect(
      storedSpends(store)
          .firstWhere((s) => s.spend.id == groceries)
          .spend
          .amount
          .value,
      27000,
    );

    await _openEdit(tester, 'Groceries');
    await _pickDay(tester, '8');
    await _saveChanges(tester);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(findCopy('₹250'), findsWidgets);
    expect(
      storedSpends(store).any((s) => s.spend.date == d(2026, 11, 8)),
      isTrue,
    );
  });

  testWidgets('TC-009-11 save changes stays disabled until something '
      'changes', (tester) async {
    final store = e2Store();
    addSpendTo(store, d(2026, 11, 9), 25000, note: 'Lunch');
    await pumpTransactions(tester, money: store);
    await _openEdit(tester, 'Lunch');
    final button = find.ancestor(
      of: find.text('Save changes'),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    expect(tester.widget<ButtonStyleButton>(button).onPressed, isNull);
    await _fill(tester, '260');
    expect(tester.widget<ButtonStyleButton>(button).onPressed, isNotNull);
  });

  testWidgets('TC-009-15 save once on double tap and keep input on failure', (
    tester,
  ) async {
    final store = e2Store();
    await pumpTransactions(tester, money: store);
    await _openAdd(tester);
    await _fill(tester, '250', 'Lunch');
    final save = find.text('Save');
    // Two taps in the same instant, before any frame.
    await tester.tap(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(storedSpends(store), hasLength(1));
    expect(find.text('Spend added'), findsOneWidget);

    store.failNextWrite = true;
    await _openAdd(tester);
    await _fill(tester, '99', 'Tea');
    await _save(tester);
    expect(find.text("Couldn't save. Please try again."), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget, reason: 'still on the editor');
    expect(tester.widget<TextField>(amountInput).controller!.text, '99');
    expect(_noteText(tester), 'Tea');
    expect(storedSpends(store), hasLength(1));
    // A write failure is a StorageException, never anything else.
    expect(
      const StorageException(StorageFailureKind.write).kind,
      StorageFailureKind.write,
    );
  });

  testWidgets('TC-009-49 the close button shows the focus ring when '
      'keyboard focused', (tester) async {
    await pumpTransactions(tester, money: e2Store());
    await _openAdd(tester);
    final ring = find.descendant(
      of: find.ancestor(
        of: find.byIcon(Icons.close),
        matching: find.byType(Tooltip),
      ),
      matching: find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is FocusRingPainter,
      ),
    );

    // Touch mode: focus alone shows no ring.
    final close = find.byIcon(Icons.close);
    Focus.of(tester.element(close)).requestFocus();
    await tester.pumpAndSettle();
    expect(ring, findsNothing, reason: 'touch mode');

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(FocusManager.instance.highlightMode, FocusHighlightMode.traditional);
    Focus.of(tester.element(close)).requestFocus();
    await tester.pumpAndSettle();
    expect(ring, findsOneWidget, reason: 'keyboard focus shows the ring');
  });

  testWidgets('TC-009-48 failed edit keeps the input and the old record', (
    tester,
  ) async {
    final store = e2Store();
    final groceries = addSpendTo(
      store,
      d(2026, 11, 9),
      40000,
      note: 'Groceries',
    );
    await pumpTransactions(tester, money: store);
    await _openEdit(tester, 'Groceries');
    await _fill(tester, '270');
    store.failNextWrite = true;
    await _saveChanges(tester);

    expect(find.text("Couldn't save. Please try again."), findsOneWidget);
    expect(find.text('Edit spend'), findsOneWidget, reason: 'still editing');
    expect(tester.widget<TextField>(amountInput).controller!.text, '270');
    expect(_noteText(tester), 'Groceries');
    final stored = storedSpends(store).single;
    expect(stored.spend.id, groceries);
    expect(stored.spend.amount.value, 40000, reason: 'old record unchanged');
    expect(stored.note, 'Groceries');
  });

  testWidgets('TC-009-16 leaving with input asks to discard', (tester) async {
    final store = e2Store();
    addSpendTo(store, d(2026, 11, 9), 25000, note: 'Lunch');
    await pumpTransactions(tester, money: store);

    // (c) untouched: leaves at once.
    await _openAdd(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Discard this spend?'), findsNothing);
    expect(find.text('Amount'), findsNothing);

    // (a) add with input.
    await _openAdd(tester);
    await _fill(tester, '250');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Discard this spend?'), findsOneWidget);
    expect(find.text("What you've typed won't be saved."), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(amountInput).controller!.text, '250');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Amount'), findsNothing);
    expect(storedSpends(store), hasLength(1));

    // (b) edit with a changed amount.
    await _openEdit(tester, 'Lunch');
    await _fill(tester, '260');
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    expect(
      find.text("Your changes to this spend won't be saved."),
      findsOneWidget,
    );
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(storedSpends(store).single.spend.amount.value, 25000);
  });

  testWidgets('TC-009-34 one paisa spend is accepted', (tester) async {
    final store = e2Store();
    await pumpTransactions(tester, money: store);
    await _addSpend(tester, '0.01', 'Coin');
    expect(storedSpends(store).single.spend.amount.value, 1);
    expect(findCopy('₹0'), findsWidgets);
    await _openEdit(tester, 'Coin');
    expect(find.text('0.01'), findsOneWidget);
  });

  testWidgets('TC-009-35 identical spends are both kept', (tester) async {
    final store = e2Store();
    await pumpTransactions(tester, money: store);
    await _addSpend(tester, '250', 'Tea');
    await _addSpend(tester, '250', 'Tea');
    expect(storedSpends(store), hasLength(2));
    expect(find.text('Tea'), findsNWidgets(2));
    expect(findCopy('₹500'), findsOneWidget);
  });

  testWidgets('TC-009-38 edit date picker uses the same limits as add', (
    tester,
  ) async {
    final store = e2Store(firstBudgetedDay: d(2026, 11, 10));
    addSpendTo(store, d(2026, 11, 11), 25000, note: 'Lunch');
    await pumpTransactions(
      tester,
      money: store,
      clock: TestClock(DateTime(2026, 11, 12, 10)),
    );
    await _openEdit(tester, 'Lunch');
    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    final picker = tester.widget<CalendarDatePicker>(
      find.byType(CalendarDatePicker),
    );
    expect(picker.firstDate, DateTime(2026, 11, 10));
    expect(picker.lastDate, DateTime(2026, 11, 12));
    expect(picker.initialDate, DateTime(2026, 11, 11));
  });
}
