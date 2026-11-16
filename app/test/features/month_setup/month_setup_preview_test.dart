import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/setup_harness.dart';
import '../../support/find_copy.dart';

Future<FakeMoneyStore> _open(
  WidgetTester tester, {
  CalendarDate? today,
  int? salaryDay = 5,
}) async {
  final store = FakeMoneyStore();
  await pumpHome(
    tester,
    money: store,
    clock: MovableClock(today ?? d(2026, 11, 5)),
  );
  await tapText(tester, 'Set up your month');
  if (salaryDay != null) await pickSalaryDay(tester, salaryDay);
  return store;
}

void main() {
  testWidgets('TC-008-10 preview shows the readme daily budgets', (
    tester,
  ) async {
    // (target, with the E2 costs, spendable line, daily budget, exact paise)
    final rows = <(String?, bool, String, String, List<(int, int)>?)>[
      (
        null,
        false,
        '₹40,000 − ₹0 fixed = ₹40,000',
        '₹1,333 a day',
        [(10, 133334), (20, 133333)],
      ),
      (null, true, '₹40,000 − ₹15,100 fixed = ₹24,900', '₹830 a day', null),
      ('20000', false, '₹20,000 − ₹0 fixed = ₹20,000', '₹666 a day', null),
      (
        '20000',
        true,
        '₹20,000 − ₹15,100 fixed = ₹4,900',
        '₹163 a day',
        [(10, 16334), (20, 16333)],
      ),
    ];
    for (final (target, costs, line, daily, exact) in rows) {
      await tester.pumpWidget(const SizedBox());
      final store = await _open(tester);
      await typeAmount(tester, 'Monthly salary', '40000');
      if (costs) {
        await tester.enterText(itemAmountFields.at(0), '10000');
        await tester.enterText(itemAmountFields.at(1), '5000');
        await tester.enterText(itemAmountFields.at(2), '100');
      }
      if (target != null) {
        await tapVisible(tester, find.byType(Switch));
        await tester.pumpAndSettle();
        await typeAmount(tester, 'Spending target', target);
      }
      await tester.pump();
      final why = line;
      expect(findCopy('5 Nov – 4 Dec · 30 days'), findsOneWidget, reason: why);
      expect(findCopy(line), findsOneWidget, reason: why);
      expect(findCopy(daily), findsWidgets, reason: why);
      expect(findCopy('Daily budget'), findsWidgets, reason: why);

      if (exact != null) {
        await tapText(tester, 'Start my month');
        expect(budgetPaise(storedResult(store, d(2026, 11, 5))), [
          for (final (count, paise) in exact) ...List.filled(count, paise),
        ]);
      }
    }
  });

  testWidgets('TC-008-23 preview shows clamped month dates for salary days '
      '29 to 31', (tester) async {
    for (final (today, day, line) in [
      (d(2027, 1, 31), 31, '31 Jan – 27 Feb · 28 days'),
      (d(2028, 1, 30), 30, '30 Jan – 28 Feb · 30 days'),
      (d(2027, 2, 28), 31, '28 Feb – 30 Mar · 31 days'),
      (d(2028, 2, 29), 29, '29 Feb – 28 Mar · 29 days'),
    ]) {
      await tester.pumpWidget(const SizedBox());
      await _open(tester, today: today, salaryDay: day);
      expect(findCopy(line), findsOneWidget, reason: '$day on ${today.iso}');
      expect(findCopy('Monthly salary'), findsOneWidget, reason: line);
      expect(findCopy('Money left now'), findsNothing, reason: line);
    }
  });

  testWidgets('TC-008-48 mid month setup on the last day shows one day', (
    tester,
  ) async {
    await _open(tester, today: d(2026, 12, 4));
    expect(findCopy('4 Dec · 1 day left'), findsOneWidget);
    expect(
      findCopy(
        "You're starting on the last day of this budget month, so all the "
        'money you have left is for today.',
      ),
      findsOneWidget,
    );
    await typeAmount(tester, 'Money left now', '500');
    expect(findCopy('₹500 a day'), findsWidgets);
  });

  testWidgets('TC-008-33 thirty ten crore costs show an exact shortfall '
      'without overflow', (tester) async {
    await _open(tester);
    await typeAmount(tester, 'Monthly salary', '100000000');
    for (var i = 0; i < 27; i++) {
      await tapText(tester, '+ Add item');
    }
    expect(itemAmountFields, findsNWidgets(30));
    for (var i = 0; i < 30; i++) {
      await tester.enterText(itemAmountFields.at(i), '100000000');
    }
    await tester.pump();

    expect(findCopy('₹3,00,00,00,000'), findsOneWidget);
    expect(
      findCopy('₹10,00,00,000 − ₹3,00,00,00,000 fixed = −₹2,90,00,00,000'),
      findsOneWidget,
    );
    expect(findCopy('₹2,90,00,00,000 short'), findsOneWidget);
    expect(findCopy('₹0 a day'), findsOneWidget);
    expect(
      findCopy('Your fixed costs are ₹2,90,00,00,000 more than your salary.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
