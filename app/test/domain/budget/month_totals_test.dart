import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

final CalendarDate _nov8 = d(2026, 11, 8);
final CalendarDate _nov20 = d(2026, 11, 20);

void main() {
  test('TC-006-15 month totals match the worked example', () {
    final future = spend(d(2026, 11, 10), 40000, id: 10);
    final result = e2Month(today: _nov8, spends: [...w1Spends(), future]);
    expect(result.totals, (
      salary: p(4000000),
      target: p(4000000),
      fixedCosts: p(1510000),
      budgeted: p(2490000),
      spentSoFar: p(253000),
      moneyIn: Paise.zero,
      saved: p(33000),
      covered: Paise.zero,
      overspent: p(17000),
      pot: p(33000),
      shortfall: Paise.zero,
      left: p(2237000),
    ));
    // The future spend stays on its day but is in no total.
    final nov10 = result.dayOn(d(2026, 11, 10));
    expect((nov10.status, nov10.spent), (DayStatus.upcoming, p(40000)));
    expect(result.ignoredSpends, isEmpty);
    expectPeriodsAddUp(result);
  });

  test('TC-006-16 left can go negative without error', () {
    final result = e2Month(
      today: _nov20,
      spends: [
        for (final day in dates(d(2026, 11, 5), _nov20)) spend(day, 156250),
      ],
    );
    expect(result.totals.spentSoFar, p(2500000));
    expect(result.totals.left, p(-10000));
    // 16 days, each 1,56,250 − 83,000 = 73,250 over; nothing saved.
    expect(result.totals.overspent, p(1172000));
    expect(result.totals.saved, Paise.zero);
    expect(result.totals.pot, Paise.zero);
  });

  test('TC-006-19 ten crore amounts stay exact', () {
    const tenCrore = 10000000000;
    final result = computeMonth(
      MonthInput(
        month: oct2026,
        firstBudgetedDay: oct2026.start,
        periods: [period(oct2026.start, FullMonthValues(salary: p(tenCrore)))],
        today: d(2026, 11, 4),
        spends: [for (final day in oct2026.days) spend(day, tenCrore)],
      ),
    );
    expect(allBudgets(result), runs([(5, 322580646), (26, 322580645)]));
    expect(
      datesWithBudget(result, 322580646),
      dates(d(2026, 10, 5), d(2026, 10, 9)),
    );
    final totals = result.totals;
    expect(totals.budgeted, p(tenCrore));
    expect(totals.spentSoFar, p(310000000000));
    expect(totals.overspent, p(300000000000));
    expect(totals.left, p(-300000000000));
    expect(totals.pot, Paise.zero);
    // Integers all the way through.
    expect(totals.left.value, isA<int>());
    expect(totals.spentSoFar.value, isA<int>());
  });

  test('TC-006-49 engine uses only the today it is given', () {
    final spends = [
      ...w1Spends(),
      for (final day in dates(d(2026, 11, 9), _nov20)) spend(day, 50000),
    ];
    final first = e2Month(today: _nov20, spends: spends);
    final back = e2Month(today: _nov8, spends: spends);
    final again = e2Month(today: _nov20, spends: spends);

    expect(back.totals.spentSoFar, p(253000));
    expect(back.totals.left, p(2237000));
    for (final day in dates(d(2026, 11, 9), _nov20)) {
      final result = back.dayOn(day);
      expect((result.status, result.result), (DayStatus.upcoming, null));
    }
    expect(dump(again), dump(first));
    expect(first.dayOn(_nov20).status, DayStatus.live);
    expect(first.totals.spentSoFar, p(253000 + 12 * 50000));
  });

  test('TC-006-50 today outside the month does not throw', () {
    final spends = [spend(d(2026, 11, 6), 50000)];

    // Before the month: everything upcoming, every running total 0.
    final before = e2Month(today: d(2026, 11, 4), spends: spends);
    expect(
      before.days.every((day) => day.status == DayStatus.upcoming),
      isTrue,
    );
    final t = before.totals;
    expect(
      (t.spentSoFar, t.saved, t.overspent, t.covered, t.pot),
      (Paise.zero, Paise.zero, Paise.zero, Paise.zero, Paise.zero),
    );
    expect(t.left, p(2490000));
    expect(t.salary, p(4000000));

    // After the month: every day final, 4 Dec's leftover in the pot.
    final after = e2Month(today: d(2026, 12, 5), spends: spends);
    expect(
      after.days.any(
        (day) =>
            day.status == DayStatus.live || day.status == DayStatus.upcoming,
      ),
      isFalse,
    );
    expect(after.dayOn(d(2026, 12, 4)).status, DayStatus.saved);
    expect(after.totals.pot, p(29 * 83000 + 33000));
    expect(after.totals.spentSoFar, p(50000));
    expect(after.totals.left, p(2440000));
  });

  test('TC-006-52 many spends on one day add up exactly', () {
    final nov9 = d(2026, 11, 9);
    final result = e2Month(
      today: nov9,
      spends: [for (var i = 0; i < 60; i++) spend(nov9, 1001, id: i)],
    );
    final day = result.dayOn(nov9);
    expect(
      (day.spent, day.status, day.result),
      (p(60060), DayStatus.live, p(22940)),
    );
    expect(result.totals.spentSoFar, p(60060));
    expect(result.totals.saved, p(332000));
    expect(result.totals.left, p(2429940));
  });
}
