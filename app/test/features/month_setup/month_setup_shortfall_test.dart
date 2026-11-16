import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/setup_harness.dart';
import '../../support/app_lifecycle.dart';
import '../../support/find_copy.dart';

Future<({FakeMoneyStore store, MovableClock clock})> _open(
  WidgetTester tester, {
  CalendarDate? today,
  int? salaryDay = 5,
}) async {
  final store = FakeMoneyStore();
  final clock = MovableClock(today ?? d(2026, 11, 5));
  await pumpHome(tester, money: store, clock: clock);
  await tapText(tester, 'Set up your month');
  if (salaryDay != null) await pickSalaryDay(tester, salaryDay);
  return (store: store, clock: clock);
}

/// S1: salary 20000, Rent 15000, EMI 6000 (Subscriptions empty).
Future<void> _enterS1(WidgetTester tester) async {
  await typeAmount(tester, 'Monthly salary', '20000');
  await tester.enterText(itemAmountFields.at(0), '15000');
  await tester.enterText(itemAmountFields.at(1), '6000');
  await tester.pump();
}

/// Moves the phone to [day], as if the app came back the next morning.
Future<void> _moveTo(
  WidgetTester tester,
  MovableClock clock,
  CalendarDate day,
) async {
  clock.moveTo(day);
  sendToBackground(tester);
  bringToForeground(tester);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TC-008-12 shortfall shows a warning and lets the user fix or '
      'continue', (tester) async {
    final (:store, :clock) = await _open(tester);
    await _enterS1(tester);

    expect(findCopy('₹0 a day'), findsOneWidget);
    expect(findCopy('₹1,000 short'), findsOneWidget);
    expect(
      findCopy('Your fixed costs are ₹1,000 more than your salary.'),
      findsOneWidget,
    );
    expect(findCopy('₹20,000 − ₹21,000 fixed = −₹1,000'), findsOneWidget);
    expect(findCopy('◆ ₹1,000 short'), findsOneWidget, reason: 'the dock');

    await tapText(tester, 'Start my month');
    expect(findCopy("Your numbers don't add up"), findsOneWidget);
    expect(
      findCopy('Your fixed costs are ₹1,000 more than your salary.'),
      findsNWidgets(2),
      reason: 'card and sheet',
    );
    expect(
      tester.getTopLeft(find.text('Fix my numbers')).dy,
      lessThan(tester.getTopLeft(find.text('Continue anyway')).dy),
    );
    expect(
      findCopy(
        'Recommended. Change your costs or target so the month adds up.',
      ),
      findsOneWidget,
    );
    expect(
      findCopy(
        'Start with ₹0 a day. Every spend this month will count as '
        'overspent.',
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Fix my numbers'),
      ),
      isNotNull,
      reason: 'Fix my numbers is the primary button',
    );

    await tester.tap(find.text('Fix my numbers'));
    await tester.pumpAndSettle();
    expect(findCopy("Your numbers don't add up"), findsNothing);
    expect(store.months, isEmpty);
    expect(
      tester.widget<TextField>(itemAmountFields.first).focusNode!.hasFocus,
      isTrue,
      reason: 'focus goes to the first fixed-cost amount',
    );

    await tapText(tester, 'Start my month');
    await tester.tap(find.text('Continue anyway'));
    await tester.pumpAndSettle();
    final stored = store.months.single;
    expect(stored.periods.single.continuedWithShortfall, isTrue);
    expect(budgetPaise(storedResult(store, d(2026, 11, 5))), [
      ...List.filled(30, 0),
    ]);

    for (final day in [d(2026, 11, 5), d(2026, 11, 20), d(2026, 12, 4)]) {
      await _moveTo(tester, clock, day);
      expect(findCopy('−₹1,000 this month'), findsOneWidget, reason: day.iso);
      expect(
        findCopy('Every spend this month counts as overspent.'),
        findsOneWidget,
        reason: day.iso,
      );
      expect(findCopy('5 Nov – 4 Dec · ₹0 a day'), findsOneWidget);
    }
  });

  testWidgets('TC-008-13 shortfall text names the target and the equal case '
      'warns too', (tester) async {
    final (:store, clock: _) = await _open(tester);
    await _enterS1(tester);
    await tapVisible(tester, find.byType(Switch));
    await tester.pumpAndSettle();
    await typeAmount(tester, 'Spending target', '19000');
    expect(findCopy('₹2,000 short'), findsOneWidget);
    expect(
      findCopy('Your fixed costs are ₹2,000 more than your spending target.'),
      findsOneWidget,
    );
    await tapText(tester, 'Start my month');
    expect(
      findCopy('Your fixed costs are ₹2,000 more than your spending target.'),
      findsNWidgets(2),
      reason: 'card and sheet',
    );
    await tester.tap(find.text('Fix my numbers'));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.enterText(itemAmountFields.at(1), '5000');
    await tester.pump();
    expect(findCopy('₹0 left for daily spending'), findsOneWidget);
    expect(
      findCopy('Your fixed costs take up all of your salary.'),
      findsOneWidget,
    );
    expect(findCopy('○ ₹0 a day'), findsOneWidget, reason: 'the dock');

    await tapText(tester, 'Start my month');
    expect(findCopy('Nothing left for daily spending'), findsOneWidget);
    expect(
      findCopy(
        "Your fixed costs take up all of your salary, so there's ₹0 a day to "
        'spend.',
      ),
      findsOneWidget,
    );
    expect(find.text('Fix my numbers'), findsOneWidget);
    expect(find.text('Continue anyway'), findsOneWidget);
    await tester.tap(find.text('Continue anyway'));
    await tester.pumpAndSettle();
    final result = storedResult(store, d(2026, 11, 5));
    expect(budgetPaise(result), List.filled(30, 0));
    expect(result.totals.shortfall, Paise.zero);
  });

  testWidgets('TC-008-44 mid month shortfall names the money left', (
    tester,
  ) async {
    final (:store, clock: _) = await _open(tester, today: d(2026, 11, 10));
    await typeAmount(tester, 'Money left now', '10000');
    await tapText(tester, '+ Add item');
    await tester.enterText(itemNameFields.first, 'Rent');
    await tester.enterText(itemAmountFields.first, '12000');
    await tester.pump();
    expect(findCopy('₹2,000 short'), findsOneWidget);
    expect(
      findCopy(
        'Your fixed costs are ₹2,000 more than the money you have left.',
      ),
      findsOneWidget,
    );

    await tapText(tester, 'Start my month');
    expect(
      findCopy('Your fixed costs are ₹2,000 more than your money left.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Continue anyway'));
    await tester.pumpAndSettle();
    final result = storedResult(store, d(2026, 11, 10));
    expect(budgetPaise(result), List.filled(25, 0));
    expect(result.totals.shortfall, p(200000));
    expect(store.months.single.firstBudgetedDay, d(2026, 11, 10));
  });

  testWidgets('TC-008-53 back on the shortfall dialog saves nothing', (
    tester,
  ) async {
    final (:store, clock: _) = await _open(tester);
    await _enterS1(tester);
    await tapText(tester, 'Start my month');
    expect(findCopy("Your numbers don't add up"), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(findCopy("Your numbers don't add up"), findsNothing);
    expect(find.text('Start my month'), findsOneWidget);
    expect(store.months, isEmpty);
    expect(typed(tester, amountInput('Monthly salary')), '20000');
  });
}
