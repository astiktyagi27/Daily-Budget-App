import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/phase3_data.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../helpers/shell.dart';
import '../../helpers/transactions_harness.dart';
import '../../support/find_copy.dart';

// F-016 T-442: the Money back switch of the Add / Edit editor, on the fake
// repositories. Literals are those of tests/F-016.

const _switchLabel = 'Money back / refund';
const _switchDescription =
    'Turn on for money paid back to you, like a refund or a friend paying '
    'you back. It lowers what you spent that day. Not for your salary.';

Future<void> _open(
  WidgetTester tester,
  Phase3Fixture fixture, {
  FakeMoneyStore? store,
  TestClock? clock,
}) => pumpTransactions(
  tester,
  money: store ?? storeFor(fixture),
  clock: clock ?? TestClock(fixture.now),
  size: const Size(400, 1800),
);

Future<void> _openAdd(WidgetTester tester) async {
  await tester.tap(addSpendButton);
  await tester.pumpAndSettle();
}

Future<void> _toggle(WidgetTester tester) async {
  await tester.tap(find.text(_switchLabel));
  await tester.pumpAndSettle();
}

Future<void> _addMoneyBack(
  WidgetTester tester,
  String amount, [
  String? note,
]) async {
  await _openAdd(tester);
  await typeInto(tester, amountInput, amount);
  if (note != null) await typeInto(tester, noteInput, note);
  await _toggle(tester);
  await tapLabel(tester, 'Save');
}

Future<void> _saveChanges(WidgetTester tester) =>
    tapLabel(tester, 'Save changes');

String _text(WidgetTester tester, Finder field) =>
    tester.widget<TextField>(field).controller!.text;

bool _switchOn(WidgetTester tester) =>
    tester.widget<Switch>(find.byType(Switch)).value;

/// The refund of AR, opened in the editor.
Future<void> _openRefundRow(WidgetTester tester) =>
    tapRow(tester, 'Amazon return');

Future<void> _tapDelete(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Delete'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Delete'));
  await tester.pumpAndSettle();
}

String? _hintOf(WidgetTester tester, String label) =>
    tester.getSemantics(find.bySemanticsLabel(label).first).hint;

void main() {
  testWidgets('TC-016-01 add spend shows the money back switch off', (
    tester,
  ) async {
    await _open(tester, fixtureA);
    await _openAdd(tester);
    expect(find.text('Add spend'), findsOneWidget);
    expect(find.text(_switchLabel), findsOneWidget);
    expect(find.text(_switchDescription), findsOneWidget);
    expect(_switchOn(tester), isFalse);
    expect(find.text('Category'), findsWidgets);
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('₹'), findsOneWidget);
    // After the Amount field, before the Date.
    final amountY = tester.getTopLeft(find.text('Amount')).dy;
    final switchY = tester.getTopLeft(find.text(_switchLabel)).dy;
    final dateY = tester.getTopLeft(find.text('Date')).dy;
    expect(amountY < switchY && switchY < dateY, isTrue);

    await _toggle(tester);
    expect(_switchOn(tester), isTrue);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await _openAdd(tester);
    expect(_switchOn(tester), isFalse, reason: 'a new Add starts off');
  });

  testWidgets('TC-016-02 the switch changes title amount note and category '
      'row', (tester) async {
    await _open(tester, fixtureA);
    await _openAdd(tester);
    await typeInto(tester, amountInput, '500');
    await tester.tap(find.text('Other').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    expect(find.text('Food'), findsOneWidget);

    await _toggle(tester);
    expect(find.text('Add money back'), findsOneWidget);
    expect(find.text('Amount back'), findsOneWidget);
    expect(find.text('How much you got back.'), findsOneWidget);
    expect(find.text('+₹'), findsOneWidget);
    expect(
      find.text('For example, "Amazon return" or "Riya paid me back".'),
      findsOneWidget,
    );
    expect(find.text('Category'), findsNothing);
    expect(_hintOf(tester, 'Save'), 'Save this money back');
    expect(_text(tester, amountInput), '500');

    await _toggle(tester);
    expect(find.text('Add spend'), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('₹'), findsOneWidget);
    expect(
      find.text('For example, "Lunch with Riya" or "Petrol".'),
      findsOneWidget,
    );
    expect(find.text('Category'), findsWidgets);
    expect(find.text('Food'), findsOneWidget, reason: 'the draft keeps it');
    expect(_text(tester, amountInput), '500');
    expect(_hintOf(tester, 'Save'), isNot('Save this money back'));
  });

  testWidgets('TC-016-07 invalid money back amounts show their error and '
      'save nothing', (tester) async {
    final store = storeFor(fixtureA);
    await _open(tester, fixtureA, store: store);
    await _openAdd(tester);
    await _toggle(tester);
    final before = storedSpends(store).length;
    const cases = {
      '': 'Enter an amount',
      '0': 'Amount must be more than ₹0',
      '100000001': "That's more than ₹10 crore. Please check the amount.",
      '12.345': 'Use numbers only, with up to 2 decimals',
      'abc': 'Use numbers only, with up to 2 decimals',
    };
    for (final MapEntry(key: input, value: message) in cases.entries) {
      await typeInto(tester, amountInput, input);
      await tapLabel(tester, 'Save');
      expect(find.text(message), findsOneWidget, reason: 'for "$input"');
      expect(storedSpends(store), hasLength(before), reason: 'for "$input"');
    }
    expect(find.text('Add money back'), findsOneWidget);
  });

  testWidgets('TC-016-08 valid money back amounts are stored to the paisa', (
    tester,
  ) async {
    final store = storeFor(fixtureA);
    await _open(tester, fixtureA, store: store);
    for (final amount in ['300.50', '1', '100000000']) {
      await _addMoneyBack(tester, amount);
    }
    final added = storedSpends(store).skip(9).toList();
    expect(
      [for (final s in added) s.spend.amount.value],
      [30050, 100, 10000000000],
    );
    expect(
      added.map((s) => s.spend.direction),
      everyElement(SpendDirection.moneyIn),
    );
    await scrollToTop(tester);
    for (final text in ['+₹300', '+₹1', '+₹10,00,00,000']) {
      expect(findCopy(text), findsOneWidget, reason: text);
    }
  });

  testWidgets('TC-016-09 money back date limits equal the spend limits', (
    tester,
  ) async {
    // (a) the E2 month on Mon 9 Nov. (b) a first month from Tue 10 Nov.
    for (final (store, now, first, last, initial) in [
      (e2Store(), DateTime(2026, 11, 9, 10), d(2026, 11, 5), 9, 9),
      (
        e2Store(firstBudgetedDay: d(2026, 11, 10)),
        DateTime(2026, 11, 12, 10),
        d(2026, 11, 10),
        12,
        12,
      ),
    ]) {
      await pumpTransactions(
        tester,
        money: store,
        clock: TestClock(now),
        size: const Size(400, 1800),
      );
      await _openAdd(tester);
      await _toggle(tester);
      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();
      final picker = tester.widget<CalendarDatePicker>(
        find.byType(CalendarDatePicker),
      );
      expect(picker.firstDate, DateTime(first.year, first.month, first.day));
      expect(picker.lastDate, DateTime(2026, 11, last));
      expect(picker.initialDate, DateTime(2026, 11, initial));
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('TC-016-10 editing a money back updates the day', (tester) async {
    final store = storeFor(fixtureAPlusRefund);
    await _open(tester, fixtureAPlusRefund, store: store);
    expect(todayLineText(tester), 'budget ₹830 · spent −₹80 · ₹910 left today');
    await _openRefundRow(tester);
    expect(find.text('Edit money back'), findsOneWidget);
    expect(_switchOn(tester), isTrue);
    expect(_text(tester, amountInput), '500');
    expect(_text(tester, noteInput), 'Amazon return');
    expect(find.text('+₹'), findsOneWidget);
    await typeInto(tester, amountInput, '300');
    await _saveChanges(tester);
    expect(find.text('Money back updated'), findsOneWidget);
    final refund = storedSpends(store).last.spend;
    expect(
      (refund.amount.value, refund.direction),
      (30000, SpendDirection.moneyIn),
    );
    expect(todayLineText(tester), 'budget ₹830 · spent ₹120 · ₹710 left today');
  });

  testWidgets('TC-016-11 switching a refund off turns it into a spend', (
    tester,
  ) async {
    final store = storeFor(fixtureAPlusRefund);
    await _open(tester, fixtureAPlusRefund, store: store);
    await _openRefundRow(tester);
    await typeInto(tester, amountInput, '300');
    await _toggle(tester);
    expect(find.text('Edit spend'), findsOneWidget);
    expect(find.text('Category'), findsWidgets, reason: 'the row returns');
    await _saveChanges(tester);
    expect(find.text('Spend updated'), findsOneWidget, reason: 'by result');
    var row = storedSpends(store).last.spend;
    expect(
      (row.amount.value, row.direction, row.category),
      (30000, SpendDirection.spend, null),
    );
    expect(todayLineText(tester), 'budget ₹830 · spent ₹720 · ₹110 left today');

    await tapRow(tester, 'Amazon return');
    expect(find.text('Edit spend'), findsOneWidget);
    await _toggle(tester);
    await _saveChanges(tester);
    expect(find.text('Money back updated'), findsOneWidget);
    row = storedSpends(store).last.spend;
    expect(row.direction, SpendDirection.moneyIn);
    expect(todayLineText(tester), 'budget ₹830 · spent ₹120 · ₹710 left today');
  });

  testWidgets('TC-016-12 turning the switch counts as a change', (
    tester,
  ) async {
    final store = storeFor(fixtureAPlusRefund);
    await _open(tester, fixtureAPlusRefund, store: store);
    await _openRefundRow(tester);
    final save = find.ancestor(
      of: find.text('Save changes'),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    expect(tester.widget<ButtonStyleButton>(save).onPressed, isNull);
    await _toggle(tester);
    expect(tester.widget<ButtonStyleButton>(save).onPressed, isNotNull);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(_switchOn(tester), isFalse, reason: 'Keep editing keeps it off');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    final stored = storedSpends(store).last.spend;
    expect(
      (stored.amount.value, stored.direction),
      (50000, SpendDirection.moneyIn),
    );
  });

  testWidgets('TC-016-13 deleting a money back asks first and restores the '
      'figures', (tester) async {
    final store = storeFor(fixtureAPlusRefund);
    await _open(tester, fixtureAPlusRefund, store: store);
    await _openRefundRow(tester);
    expect(_hintOf(tester, 'Delete'), 'Delete this money back');
    await _tapDelete(tester);
    expect(find.text('Delete this money back?'), findsOneWidget);
    expect(
      find.text("₹500 back on Fri, 13 Nov. This can't be undone."),
      findsOneWidget,
    );
    expect(_hintOf(tester, 'Cancel'), 'Keep this money back');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(storedSpends(store), hasLength(10));
    await _tapDelete(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(storedSpends(store), hasLength(10), reason: 'Back keeps it');

    await _tapDelete(tester);
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(find.text('Money back deleted'), findsOneWidget);
    expect(storedSpends(store), hasLength(9));
    expect(todayLineText(tester), 'budget ₹830 · spent ₹420 · ₹410 left today');
  });

  testWidgets('TC-016-17 pot shrink sheet names the cut cover once', (
    tester,
  ) async {
    final store = storeFor(p1);
    await _open(tester, p1, store: store);
    await tapRow(tester, 'Refund');
    await _tapDelete(tester);
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(find.text('Savings pot updated'), findsOneWidget);
    expect(
      find.text(
        'Your savings pot went down, so ₹500 of the cover on Tue, 10 Nov '
        'was taken back.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Savings pot updated'), findsNothing);
    expect(find.text('Money back deleted'), findsOneWidget);
    await tapTab(tester, 'Home');
    await tapTab(tester, 'Transactions');
    expect(find.text('Savings pot updated'), findsNothing, reason: 'once');
  });

  testWidgets('TC-016-20 money back discard double tap and save failure', (
    tester,
  ) async {
    final store = storeFor(fixtureA);
    await _open(tester, fixtureA, store: store);

    // (a) nothing typed: the switch alone leaves at once.
    await _openAdd(tester);
    await _toggle(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Add money back'), findsNothing);
    expect(find.text('Discard this money back?'), findsNothing);

    await _openAdd(tester);
    await _toggle(tester);
    await typeInto(tester, amountInput, '500');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Discard this money back?'), findsOneWidget);
    expect(find.text("What you've typed won't be saved."), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(_text(tester, amountInput), '500');

    // (c) failure keeps the input.
    store.failNextWrite = true;
    await tapLabel(tester, 'Save');
    expect(find.text("Couldn't save. Please try again."), findsOneWidget);
    expect(_text(tester, amountInput), '500');
    expect(find.text('Add money back'), findsOneWidget);
    expect(storedSpends(store), hasLength(9));

    // (b) a double tap stores one record.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    final save = find.text('Save');
    await tester.tap(save);
    await tester.tap(save, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(storedSpends(store), hasLength(10));
    expect(find.text('Money back added'), findsOneWidget);

    // Discard leaves with 0 writes.
    await _openAdd(tester);
    await _toggle(tester);
    await typeInto(tester, amountInput, '70');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(storedSpends(store), hasLength(10));
  });

  testWidgets('TC-016-21 a failed money back edit keeps the input and the old '
      'record', (tester) async {
    final store = storeFor(fixtureAPlusRefund);
    await _open(tester, fixtureAPlusRefund, store: store);
    await _openRefundRow(tester);
    await typeInto(tester, amountInput, '300');
    store.failNextWrite = true;
    await _saveChanges(tester);
    expect(find.text("Couldn't save. Please try again."), findsOneWidget);
    expect(_text(tester, amountInput), '300');
    expect(find.text('Edit money back'), findsOneWidget);
    final stored = storedSpends(store).last.spend;
    expect(
      (stored.amount.value, stored.direction),
      (50000, SpendDirection.moneyIn),
    );
  });

  testWidgets('TC-016-22 money back controls have help copy', (tester) async {
    final semantics = tester.ensureSemantics();
    final store = storeFor(fixtureAPlusRefund);
    await _open(tester, fixtureAPlusRefund, store: store);
    await _openAdd(tester);
    expect(_hintOf(tester, _switchLabel), _switchDescription);
    expect(find.text('How much you got back.'), findsNothing);
    await _toggle(tester);
    expect(find.text('How much you got back.'), findsOneWidget);
    expect(_hintOf(tester, 'Save'), 'Save this money back');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await _openRefundRow(tester);
    expect(_hintOf(tester, 'Save changes'), 'Save your changes');
    expect(_hintOf(tester, 'Delete'), 'Delete this money back');
    semantics.dispose();
  });

  testWidgets('TC-016-23 the money back switch is announced with its state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _open(tester, fixtureA);
    await _openAdd(tester);
    final node = find.bySemanticsLabel(_switchLabel).first;
    expect(
      tester.getSemantics(node),
      isSemantics(
        label: _switchLabel,
        hint: _switchDescription,
        hasToggledState: true,
        isToggled: false,
      ),
    );
    final size = tester.getSize(node);
    expect(size.height, greaterThanOrEqualTo(48));
    await _toggle(tester);
    expect(
      tester.getSemantics(find.bySemanticsLabel(_switchLabel).first),
      isSemantics(hasToggledState: true, isToggled: true),
    );
    // Reading order: Amount, the switch row, Date, Note, Save.
    final amountY = tester.getTopLeft(find.text('Amount back')).dy;
    final switchY = tester.getTopLeft(find.text(_switchLabel)).dy;
    final dateY = tester.getTopLeft(find.text('Date')).dy;
    final noteY = tester.getTopLeft(noteInput).dy;
    expect(amountY < switchY && switchY < dateY && dateY < noteY, isTrue);
    semantics.dispose();
  });

  testWidgets('TC-016-25 money back on the first budgeted day is allowed', (
    tester,
  ) async {
    final store = storeFor(fixtureF);
    await _open(tester, fixtureF, store: store, clock: TestClock(fixtureF.now));
    await _openAdd(tester);
    await _toggle(tester);
    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    final picker = tester.widget<CalendarDatePicker>(
      find.byType(CalendarDatePicker),
    );
    expect(picker.firstDate, DateTime(2026, 11, 10));
    await tester.tap(find.text('9'));
    await tester.pump();
    await tester.tap(find.text('10'));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await typeInto(tester, amountInput, '200');
    await tapLabel(tester, 'Save');
    final added = storedSpends(store).last.spend;
    expect(
      (added.date, added.direction),
      (d(2026, 11, 10), SpendDirection.moneyIn),
    );
  });

  testWidgets('TC-016-27 a salary typed as money back is accepted', (
    tester,
  ) async {
    final store = storeFor(fixtureA);
    await _open(tester, fixtureA, store: store);
    await _addMoneyBack(tester, '40000');
    expect(find.text('Money back added'), findsOneWidget);
    expect(
      todayLineText(tester),
      'budget ₹830 · spent −₹39,580 · ₹40,410 left today',
    );
  });

  testWidgets('TC-016-30 money back follows the add spend month rules', (
    tester,
  ) async {
    final store = storeFor(fixtureA);
    await _open(
      tester,
      fixtureA,
      store: store,
      clock: TestClock(DateTime(2026, 12, 5, 10)),
    );
    await tester.tap(addSpendButton);
    await tester.pumpAndSettle();
    expect(find.text('Set up your new month first'), findsWidgets);
    expect(find.text(_switchLabel), findsNothing);
    expect(storedSpends(store), hasLength(9));
  });

  testWidgets('TC-016-32 money back notes keep hindi emoji and the limit', (
    tester,
  ) async {
    final store = storeFor(fixtureA);
    await _open(tester, fixtureA, store: store);
    await _addMoneyBack(tester, '10', 'चाय वापसी 🍵');
    await _addMoneyBack(tester, '20');
    await _openAdd(tester);
    await _toggle(tester);
    await typeInto(tester, noteInput, 'a' * 101);
    expect(_text(tester, noteInput), 'a' * 100);
    expect(find.text('100/100'), findsOneWidget);
    await typeInto(tester, amountInput, '30');
    await tapLabel(tester, 'Save');
    final notes = [for (final s in storedSpends(store).skip(9)) s.note];
    expect(notes, ['चाय वापसी 🍵', null, 'a' * 100]);
    await scrollToTop(tester);
    expect(find.text('चाय वापसी 🍵'), findsOneWidget);
  });

  testWidgets('TC-016-38 identical money back entries are both kept', (
    tester,
  ) async {
    final store = storeFor(fixtureA);
    await _open(tester, fixtureA, store: store);
    await _addMoneyBack(tester, '100', 'Refund');
    await _addMoneyBack(tester, '100', 'Refund');
    final added = storedSpends(store).skip(9).toList();
    expect(added, hasLength(2));
    expect(added[0].spend.id, isNot(added[1].spend.id));
    expect(todayLineText(tester), 'budget ₹830 · spent ₹220 · ₹610 left today');
  });

  testWidgets('TC-016-42 no switch when adding is blocked', (tester) async {
    await pumpTransactions(tester, money: FakeMoneyStore());
    expect(addSpendButton, findsNothing);
    expect(find.text(_switchLabel), findsNothing);
  });

  testWidgets('TC-016-43 delete sheet shows whole rupees', (tester) async {
    final store = e2Store();
    addMoneyInTo(store, d(2026, 11, 9), 30050, note: 'Return');
    await pumpTransactions(tester, money: store);
    await tapRow(tester, 'Return');
    await _tapDelete(tester);
    expect(
      find.text("₹300 back on Mon, 9 Nov. This can't be undone."),
      findsOneWidget,
    );
  });

  testWidgets('TC-016-46 converting a categorised spend to money back clears '
      'its category in the same write', (tester) async {
    final store = storeFor(fixtureAF);
    await _open(tester, fixtureAF, store: store);
    await tester.tap(find.text('Lunch').first);
    await tester.pumpAndSettle();
    expect(find.text('Edit spend'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    await _toggle(tester);
    expect(find.text('Category'), findsNothing);
    await _saveChanges(tester);
    expect(find.text('Money back updated'), findsOneWidget, reason: 'result');
    final lunch = storedSpends(
      store,
    ).firstWhere((s) => s.note == 'Lunch' && s.spend.date == d(2026, 11, 13));
    expect(
      (lunch.spend.direction, lunch.spend.category),
      (SpendDirection.moneyIn, null),
    );
  });

  testWidgets('TC-016-03 saving money back stores a refund', (tester) async {
    final store = storeFor(fixtureA);
    await _open(tester, fixtureA, store: store);
    await tester.tap(addSpendButton);
    await tester.pumpAndSettle();
    expect(find.text('Add spend'), findsOneWidget);
    expect(find.text('Money back / refund'), findsOneWidget);
    await typeInto(tester, amountInput, '500');
    await tester.tap(find.text('Money back / refund'));
    await tester.pumpAndSettle();
    expect(find.text('Add money back'), findsOneWidget);
    expect(find.text('Amount back'), findsOneWidget);
    expect(find.text('Category'), findsNothing);
    await tapLabel(tester, 'Save');
    expect(find.text('Money back added'), findsOneWidget);
    final added = storedSpends(store).last.spend;
    expect(
      (added.amount.value, added.direction, added.category),
      (50000, SpendDirection.moneyIn, null),
    );
  });
}
