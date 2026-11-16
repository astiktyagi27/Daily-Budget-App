import 'package:daily_budget/data/repositories/transaction_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/setup_harness.dart';
import '../../support/find_copy.dart';

Future<FakeMoneyStore> _openEdit(
  WidgetTester tester, {
  required CalendarDate today,
  FakeMoneyStore? store,
}) async {
  final money = store ?? storeWithMonth();
  await pumpHome(tester, money: money, clock: MovableClock(today));
  await tapText(tester, 'Edit this month');
  return money;
}

bool _saveEnabled(WidgetTester tester) => tester
    .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save changes'))
    .enabled;

Future<void> _setRent(WidgetTester tester, String text) async {
  await tester.enterText(itemAmountFields.first, text);
  await tester.pump();
}

void main() {
  testWidgets('TC-008-20 editing this month recalculates only the days left', (
    tester,
  ) async {
    final store = await _openEdit(tester, today: d(2026, 11, 20));
    // 6 and 12 Nov have spends; they do not change the budgets.
    final month = store.months.single;
    store.spendsByMonth[month.id] = [
      StoredSpend(spend: spend(d(2026, 11, 6), 100000, id: 90)),
      StoredSpend(spend: spend(d(2026, 11, 12), 50000, id: 91)),
    ];

    expect(findCopy('Edit this month'), findsWidgets);
    expect(findCopy('Salary day: 5th'), findsOneWidget);
    expect(findCopy('Set in your first month.'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(_saveEnabled(tester), isFalse);
    expect(typed(tester, amountInput('Monthly salary')), '40000');

    await _setRent(tester, '13000');
    expect(_saveEnabled(tester), isTrue);
    expect(
      findCopy(
        'From today (20 Nov): ₹630 a day for the 15 days left. Days before '
        'today keep their budget.',
      ),
      findsOneWidget,
    );
    expect(findCopy('₹40,000 − ₹18,100 fixed = ₹21,900'), findsOneWidget);
    expect(findCopy('From today'), findsOneWidget, reason: 'the dock');
    expect(findCopy('₹630 a day'), findsOneWidget, reason: 'the dock');

    await tapText(tester, 'Save changes');

    final periods = store.months.single.periods;
    expect(periods, hasLength(2));
    expect(periods.first.start, d(2026, 11, 5));
    expect(periods.last.start, d(2026, 11, 20));
    final result = storedResult(store, d(2026, 11, 20));
    expect(budgetPaise(result), [
      ...List.filled(15, 83000),
      ...List.filled(15, 63000),
    ]);
    expect(store.spendsByMonth[month.id], hasLength(2));
    expect(findCopy('5 Nov – 4 Dec · ₹630 a day'), findsOneWidget);
  });

  testWidgets('TC-008-21 salary edit shows 496 a day and stores the exact '
      'paise', (tester) async {
    final store = await _openEdit(tester, today: d(2026, 11, 20));
    await tester.enterText(amountInput('Monthly salary'), '35000');
    await tester.pump();
    expect(
      findCopy(
        'From today (20 Nov): ₹496 a day for the 15 days left. Days before '
        'today keep their budget.',
      ),
      findsOneWidget,
    );
    await tapText(tester, 'Save changes');
    expect(budgetPaise(storedResult(store, d(2026, 11, 20))), [
      ...List.filled(15, 83000),
      ...List.filled(10, 49667),
      ...List.filled(5, 49666),
    ]);
  });

  testWidgets('TC-008-40 editing below what is already spent is allowed', (
    tester,
  ) async {
    final store = await _openEdit(tester, today: d(2026, 11, 20));
    store.spendsByMonth[store.months.single.id] = [
      StoredSpend(spend: spend(d(2026, 11, 19), 2300000, id: 90)),
    ];
    await tester.enterText(amountInput('Monthly salary'), '30000');
    await tester.pump();
    expect(
      findCopy(
        'From today (20 Nov): ₹163 a day for the 15 days left. Days before '
        'today keep their budget.',
      ),
      findsOneWidget,
    );
    await tapText(tester, 'Save changes');
    expect(store.months.single.periods, hasLength(2));
    expect(findCopy('5 Nov – 4 Dec · ₹163 a day'), findsOneWidget);
  });

  testWidgets('TC-008-45 reverting an edit disables save changes again', (
    tester,
  ) async {
    await _openEdit(tester, today: d(2026, 11, 20));
    await _setRent(tester, '13000');
    expect(_saveEnabled(tester), isTrue);
    await _setRent(tester, '10000');
    expect(_saveEnabled(tester), isFalse);
    await _setRent(tester, '10000.00');
    expect(_saveEnabled(tester), isFalse, reason: '10000.00 is 10000');
  });

  testWidgets('TC-008-46 edit on the first day respreads the whole month', (
    tester,
  ) async {
    final store = await _openEdit(tester, today: d(2026, 11, 5));
    await _setRent(tester, '13000');
    expect(
      findCopy(
        'From today (5 Nov): ₹730 a day for the 30 days left. Days before '
        'today keep their budget.',
      ),
      findsOneWidget,
    );
    await tapText(tester, 'Save changes');
    expect(store.months.single.periods, hasLength(2));
    expect(
      budgetPaise(storedResult(store, d(2026, 11, 5))),
      List.filled(30, 73000),
    );
  });

  testWidgets('TC-008-47 failed edit keeps the input and adds no period', (
    tester,
  ) async {
    final store = await _openEdit(tester, today: d(2026, 11, 20));
    await _setRent(tester, '13000');
    store.failNextWrite = true;
    await tapText(tester, 'Save changes');

    expect(findCopy("Couldn't save. Please try again."), findsOneWidget);
    expect(typed(tester, itemAmountFields.first), '13000');
    expect(store.months.single.periods, hasLength(1));
    expect(_saveEnabled(tester), isTrue);
  });

  testWidgets('TC-008-28 an edit that causes a shortfall warns and can '
      'continue', (tester) async {
    final store = await _openEdit(tester, today: d(2026, 11, 20));
    await tapVisible(tester, find.byType(Switch));
    await tester.pumpAndSettle();
    await typeAmount(tester, 'Spending target', '25000');
    expect(
      findCopy(
        'This change leaves you ₹2,550 short for the rest of the month.',
      ),
      findsOneWidget,
    );

    await tapText(tester, 'Save changes');
    expect(findCopy("Your numbers don't add up"), findsOneWidget);
    expect(
      findCopy(
        'This change leaves you ₹2,550 short for the rest of the month.',
      ),
      findsNWidgets(2),
      reason: 'card and sheet',
    );
    expect(
      tester.getTopLeft(find.text('Fix my numbers')).dy,
      lessThan(tester.getTopLeft(find.text('Continue anyway')).dy),
    );
    await tester.tap(find.text('Fix my numbers'));
    await tester.pumpAndSettle();
    expect(store.months.single.periods, hasLength(1));

    await tapText(tester, 'Save changes');
    await tester.tap(find.text('Continue anyway'));
    await tester.pumpAndSettle();

    expect(store.months.single.periods, hasLength(2));
    expect(budgetPaise(storedResult(store, d(2026, 11, 20))), [
      ...List.filled(15, 83000),
      ...List.filled(15, 0),
    ]);
    expect(findCopy('−₹2,550 this month'), findsOneWidget);
  });

  testWidgets('TC-008-22 an edit with nothing changed leaves at once', (
    tester,
  ) async {
    await _openEdit(tester, today: d(2026, 11, 20));
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(findCopy('Discard changes?'), findsNothing);
    expect(findCopy('Edit this month'), findsOneWidget, reason: 'Home button');
    expect(find.text('Save changes'), findsNothing);
  });

  testWidgets('TC-008-22 an edit with a change asks to discard', (
    tester,
  ) async {
    final store = await _openEdit(tester, today: d(2026, 11, 20));
    await _setRent(tester, '13000');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(findCopy('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Save changes'), findsNothing);
    expect(store.months.single.periods, hasLength(1));
  });

  testWidgets('TC-008-20 the money left of a mid month start is edited as '
      'saved', (tester) async {
    final store = storeWithMonth(
      values: const MidMonthStartValues(moneyLeft: Paise(2490000)),
      firstBudgetedDay: d(2026, 11, 10),
    );
    await _openEdit(tester, today: d(2026, 11, 20), store: store);

    expect(findCopy('Money left on 10 Nov'), findsOneWidget);
    expect(
      findCopy(
        'What you had to spend when you started on 10 Nov. Change it if it '
        'was wrong. Days before today keep their budget.',
      ),
      findsOneWidget,
    );
    expect(findCopy('Money left now'), findsNothing);
    expect(typed(tester, amountInput('Money left on 10 Nov')), '24900');
    await typeAmount(tester, 'Money left on 10 Nov', '26400');
    expect(
      findCopy(
        'From today (20 Nov): ₹1,096 a day for the 15 days left. Days '
        'before today keep their budget.',
      ),
      findsOneWidget,
    );
  });
}
