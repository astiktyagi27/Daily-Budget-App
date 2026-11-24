import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../data/repositories/repository_setup.dart';
import '../../domain/budget/fixtures.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/shell.dart';
import '../../helpers/transactions_harness.dart';

/// 5 Nov ₹500 (saved ₹330), 6 Nov ₹1,000 covered ₹170, 7 Nov ₹830, pot ₹160;
/// today Sun 8 Nov (TC-009-25).
(FakeMoneyStore, int) _seedCovered() {
  final store = e2Store();
  final nov5 = addSpendTo(store, d(2026, 11, 5), 50000, note: 'Rent share');
  addSpendTo(store, d(2026, 11, 6), 100000, note: 'Trip');
  addSpendTo(store, d(2026, 11, 7), 83000, note: 'Party');
  addCoverTo(store, d(2026, 11, 6), 17000);
  return (store, nov5);
}

Future<void> _edit(WidgetTester tester, String row, String amount) async {
  await tapRow(tester, row);
  await tester.enterText(amountInput, amount);
  await tester.pump();
  await tapLabel(tester, 'Save changes');
}

void main() {
  testWidgets('TC-009-25 cover taken back after an edit shows one note', (
    tester,
  ) async {
    final (store, _) = _seedCovered();
    await pumpTransactions(
      tester,
      money: store,
      clock: TestClock(DateTime(2026, 11, 8, 10)),
    );
    await _edit(tester, 'Rent share', '830');

    expect(find.text('Savings pot updated'), findsOneWidget);
    expect(
      find.text(
        'Your savings pot went down, so the ₹170 that covered Fri, 6 Nov was '
        'taken back. 6 Nov is overspent again.',
      ),
      findsOneWidget,
    );
    expect(store.coversByMonth[store.months.first.id]!.single.amount.value, 0);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Savings pot updated'), findsNothing);
    expect(find.text('Spend updated'), findsOneWidget);

    // Shown once: not again when the tab is shown again.
    await tapTab(tester, 'Home');
    await tapTab(tester, 'Transactions');
    expect(find.text('Savings pot updated'), findsNothing);
  });

  testWidgets('TC-009-26 no cover note when no cover changes', (tester) async {
    final (store, _) = _seedCovered();
    await pumpTransactions(
      tester,
      money: store,
      clock: TestClock(DateTime(2026, 11, 8, 10)),
    );
    await _edit(tester, 'Party', '800');
    expect(find.text('Savings pot updated'), findsNothing);
    expect(find.text('Spend updated'), findsOneWidget);

    await tester.tap(addSpendButton);
    await tester.pumpAndSettle();
    await tester.enterText(amountInput, '100');
    await tester.pump();
    await tapLabel(tester, 'Save');
    expect(find.text('Savings pot updated'), findsNothing);
    expect(find.text('Spend added'), findsOneWidget);
  });

  testWidgets('TC-009-27 partial cover cut shows the partial note', (
    tester,
  ) async {
    // 5 Nov ₹500 (saved ₹330); 6 and 7 Nov overspent ₹170 and covered; 8 Nov
    // ₹200 (saved ₹630); 9 Nov on budget. Today Tue 10 Nov. Raising 8 Nov to
    // ₹830 removes its ₹630 saving and leaves the pot ₹10 short.
    final store = e2Store();
    addSpendTo(store, d(2026, 11, 5), 50000);
    addSpendTo(store, d(2026, 11, 6), 100000);
    addSpendTo(store, d(2026, 11, 7), 100000);
    addSpendTo(store, d(2026, 11, 8), 20000, note: 'Quiet day');
    addSpendTo(store, d(2026, 11, 9), 83000);
    addCoverTo(store, d(2026, 11, 6), 17000);
    addCoverTo(store, d(2026, 11, 7), 17000);
    await pumpTransactions(
      tester,
      money: store,
      clock: TestClock(DateTime(2026, 11, 10, 10)),
    );
    await _edit(tester, 'Quiet day', '830');
    expect(
      find.text(
        'Your savings pot went down, so ₹10 of the cover on Sat, 7 Nov was '
        'taken back.',
      ),
      findsOneWidget,
    );
    expect(find.text('OK'), findsOneWidget);
  });

  testWidgets('TC-009-28 cutting two covers explains both', (tester) async {
    // 5 Nov ₹10 (saved ₹820); 6 and 7 Nov overspent ₹170 and covered. Raising
    // 5 Nov to ₹830 empties the pot, so both covers go, newest first.
    final store = e2Store();
    addSpendTo(store, d(2026, 11, 5), 1000, note: 'Quiet day');
    addSpendTo(store, d(2026, 11, 6), 100000);
    addSpendTo(store, d(2026, 11, 7), 100000);
    addCoverTo(store, d(2026, 11, 6), 17000);
    addCoverTo(store, d(2026, 11, 7), 17000);
    await pumpTransactions(
      tester,
      money: store,
      clock: TestClock(DateTime(2026, 11, 8, 10)),
    );
    await _edit(tester, 'Quiet day', '830');
    expect(find.text('Savings pot updated'), findsOneWidget);
    const sat =
        'Your savings pot went down, so the ₹170 that covered Sat, 7 Nov was '
        'taken back. 7 Nov is overspent again.';
    const fri =
        'Your savings pot went down, so the ₹170 that covered Fri, 6 Nov was '
        'taken back. 6 Nov is overspent again.';
    expect(find.text(sat), findsOneWidget);
    expect(find.text(fri), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(sat)).dy,
      lessThan(tester.getTopLeft(find.text(fri)).dy),
      reason: 'newest cover first',
    );
    expect(find.text('OK'), findsOneWidget);
  });

  test('TC-009-14 reducing an over covered spend returns the extra cover to '
      'the pot', () async {
    final repos = openMemoryRepos();
    final month = await repos.months.confirmMonth(e2NewMonth());
    final today = d(2026, 11, 8);
    var tick = 0;
    Future<int> add(CalendarDate day, int paise) async =>
        (await repos.spends.add(
          month.id,
          fields(day, paise),
          today: today,
          now: at(day, 8, tick++),
        )).id;
    await add(d(2026, 11, 5), 50000);
    final nov6 = await add(d(2026, 11, 6), 100000);
    await add(d(2026, 11, 7), 83000);
    await repos.savings.cover(
      month.id,
      d(2026, 11, 6),
      const Paise(17000),
      today: today,
      now: at(today, 9),
    );

    final outcome = await repos.spends.update(
      nov6,
      fields(d(2026, 11, 6), 90000),
      today: today,
      now: at(today, 10),
    );
    expect(outcome.reductions, isEmpty, reason: 'no cover-taken-back note');

    final stored = (await repos.months.watchMonth(month.id).first)!;
    final input = MonthInput(
      month: stored.month,
      firstBudgetedDay: stored.firstBudgetedDay,
      periods: stored.periods,
      today: today,
      spends: [
        for (final s in await repos.spends.watchMonthSpends(month.id).first)
          s.spend,
      ],
      covers: await repos.savings.watchCovers(month.id).first,
    );
    final result = computeMonth(input);
    final nov6Result = result.dayOn(d(2026, 11, 6));
    expect(nov6Result.status, DayStatus.onBudget);
    expect(result.effectiveCovers.single.amount.value, 7000);
    expect(result.totals.pot.value, 26000);
  });
}
