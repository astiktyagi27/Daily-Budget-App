import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

final CalendarDate _nov20 = d(2026, 11, 20);

/// E2 from 5 Nov plus a change to [values] on 20 Nov.
List<BudgetPeriod> _withChange(PeriodValues values) => [
  period(d(2026, 11, 5), e2Values()),
  period(_nov20, values),
];

void main() {
  test('TC-006-21 mid month change recalculates only the remaining days', () {
    const rotation = [50000, 100000, 83000];
    final spends = [
      for (final (i, day) in dates(d(2026, 11, 5), d(2026, 11, 19)).indexed)
        spend(day, rotation[i % 3], id: i),
    ];
    final covers = [cover(1, d(2026, 11, 6), 17000, at(d(2026, 11, 7), 21))];
    final before = e2Month(today: _nov20, spends: spends, covers: covers);
    final past = before.days.take(15).toList();
    expect(past.every((day) => day.budget == p(83000)), isTrue);

    final changes = <String, (PeriodValues, List<Paise>, int)>{
      'C1': (e2Values(rent: 1300000), runs([(15, 63000)]), 2190000),
      'C2': (e2Values(rent: 1100000), runs([(5, 76334), (10, 76333)]), 2390000),
      'C3': (
        e2Values(salary: 3500000),
        runs([(10, 49667), (5, 49666)]),
        1990000,
      ),
    };
    for (final MapEntry(key: name, value: (values, expected, spendable))
        in changes.entries) {
      final after = e2Month(
        today: _nov20,
        spends: spends,
        covers: covers,
        periods: _withChange(values),
      );
      expect(after.days.take(15).toList(), past, reason: name);
      expect(budgetsOf(after, _nov20, d(2026, 12, 4)), expected, reason: name);
      expect(Paise.sum(allBudgets(after)), p(spendable), reason: name);
      expect(values.spendable, p(spendable), reason: name);
      expect(after.effectiveCovers, before.effectiveCovers, reason: name);
      expect(after.reductions, isEmpty, reason: name);
      expect(after.ignoredSpends, isEmpty, reason: name);
    }
  });

  test('TC-006-22 decision d037 example gives 552 a day', () {
    final month = BudgetMonth.startIn(1, 2026, 11);
    expect((month.start, month.end), (d(2026, 11, 1), d(2026, 11, 30)));
    final result = computeMonth(
      MonthInput(
        month: month,
        firstBudgetedDay: d(2026, 11, 1),
        periods: [
          period(d(2026, 11, 1), e2Values()),
          period(d(2026, 11, 13), e2Values(salary: 3500000)),
        ],
        today: d(2026, 11, 13),
      ),
    );
    expect(
      budgetsOf(result, d(2026, 11, 1), d(2026, 11, 12)),
      runs([(12, 83000)]),
    );
    expect(result.periods.last.amountToSpread, p(994000));
    expect(
      budgetsOf(result, d(2026, 11, 13), d(2026, 11, 30)),
      runs([(4, 55223), (14, 55222)]),
    );
    expect(Paise.sum(allBudgets(result)), p(1990000));
  });

  test('TC-006-25 period history reports three periods with exact results', () {
    final nov28 = d(2026, 11, 28);
    final result = e2Month(
      today: d(2026, 11, 30),
      periods: [
        period(d(2026, 11, 5), e2Values()),
        period(_nov20, e2Values(rent: 1300000)),
        period(nov28, e2Values(rent: 1300000, emi: 400000)),
      ],
      spends: [
        spend(d(2026, 11, 6), 100000),
        spend(d(2026, 11, 7), 50000),
        spend(d(2026, 11, 21), 70000),
        spend(d(2026, 11, 22), 10000),
        spend(nov28, 80000),
        spend(d(2026, 11, 29), 20000),
      ],
      covers: [cover(1, d(2026, 11, 6), 10000, at(d(2026, 11, 8), 10))],
    );
    expect(result.periods, hasLength(3));
    final [p1, p2, p3] = result.periods;

    expect((p1.start, p1.end, p1.days), (d(2026, 11, 5), d(2026, 11, 19), 15));
    expect(p1.period.values.fixedCostsTotal, p(1510000));
    expect(p1.changes, isEmpty);
    expect(p1.budgets, runs([(15, 83000)]));
    expect(
      (p1.netSpent, p1.saved, p1.overspent, p1.covered, p1.shortfall),
      (p(150000), p(1112000), p(7000), p(10000), Paise.zero),
    );

    expect((p2.start, p2.end, p2.days), (_nov20, d(2026, 11, 27), 8));
    expect(p2.period.values.fixedCostsTotal, p(1810000));
    expect(p2.changes, [
      (
        field: PeriodField.fixedCost,
        name: 'Rent',
        before: p(1000000),
        after: p(1300000),
      ),
    ]);
    expect(p2.budgets, runs([(8, 63000)]));
    expect(
      (p2.netSpent, p2.saved, p2.overspent, p2.covered, p2.shortfall),
      (p(80000), p(431000), p(7000), Paise.zero, Paise.zero),
    );

    expect((p3.start, p3.end, p3.days), (nov28, d(2026, 12, 4), 7));
    expect(p3.period.values.fixedCostsTotal, p(1710000));
    expect(p3.changes, [
      (
        field: PeriodField.fixedCost,
        name: 'EMI',
        before: p(500000),
        after: p(400000),
      ),
    ]);
    expect(p3.amountToSpread, p(541000));
    expect(p3.budgets, runs([(5, 77286), (2, 77285)]));
    expect(datesWithBudget(result, 77286), dates(nov28, d(2026, 12, 2)));
    expect(
      (p3.netSpent, p3.saved, p3.overspent, p3.covered, p3.shortfall),
      (p(100000), p(57286), p(2714), Paise.zero, Paise.zero),
    );

    final totals = result.totals;
    expect(totals.spentSoFar, p(330000));
    expect(totals.saved, p(1600286));
    expect(totals.overspent, p(16714));
    expect(totals.covered, p(10000));
    expect(totals.pot, p(1590286));
    expect(totals.fixedCosts, p(1710000));
    expectPeriodsAddUp(result);
  });

  test('TC-006-26 same day changes apply the latest and keep both', () {
    final early = period(
      _nov20,
      e2Values(rent: 1300000),
      changedAt: at(_nov20, 10),
    );
    final late = period(
      _nov20,
      e2Values(rent: 1100000),
      changedAt: at(_nov20, 18),
    );
    final first = period(d(2026, 11, 5), e2Values());
    for (final order in [
      [first, early, late],
      [late, early, first],
    ]) {
      final result = e2Month(today: _nov20, periods: order);
      expect(
        budgetsOf(result, _nov20, d(2026, 12, 4)),
        runs([(5, 76334), (10, 76333)]),
      );
      expect(
        budgetsOf(result, d(2026, 11, 5), d(2026, 11, 19)),
        runs([(15, 83000)]),
      );
      expect(result.periods.map((p) => p.period), [first, early, late]);
      final [_, ten, eighteen] = result.periods;
      expect((ten.superseded, ten.days), (true, 0));
      expect(ten.budgets, isEmpty);
      expect(ten.end, d(2026, 11, 19));
      expect((eighteen.superseded, eighteen.days), (false, 15));
      expect(eighteen.changes, [
        (
          field: PeriodField.fixedCost,
          name: 'Rent',
          before: p(1300000),
          after: p(1100000),
        ),
      ]);
      expectPeriodsAddUp(result);
    }
  });

  test('TC-006-40 change on the first day respreads the whole month', () {
    final nov5 = d(2026, 11, 5);
    final original = period(nov5, e2Values());
    final change = period(
      nov5,
      e2Values(rent: 1300000),
      changedAt: at(nov5, 12),
    );
    final result = e2Month(today: nov5, periods: [original, change]);
    expect(allBudgets(result), runs([(30, 73000)]));
    expect(result.periods.map((p) => p.period), [original, change]);
    expect(result.periods.first.superseded, isTrue);
    expect(result.periods.last.superseded, isFalse);
    expect(result.totals.fixedCosts, p(1810000));
  });

  test('TC-006-41 change on the last day budgets only today', () {
    final dec4 = d(2026, 12, 4);
    final result = e2Month(
      today: dec4,
      periods: [
        period(d(2026, 11, 5), e2Values()),
        period(dec4, e2Values(rent: 900000)),
      ],
    );
    expect(
      budgetsOf(result, d(2026, 11, 5), d(2026, 12, 3)),
      runs([(29, 83000)]),
    );
    expect(result.dayOn(dec4).budget, p(183000));
    expect(Paise.sum(allBudgets(result)), p(2590000));
    expect(result.periods.last.days, 1);
  });

  test('TC-006-48 a budget change leaves the pot unchanged', () {
    final nov8 = d(2026, 11, 8);
    final covers = [cover(1, d(2026, 11, 6), 10000, at(nov8, 10))];
    final before = e2Month(today: nov8, spends: w1Spends(), covers: covers);
    final after = e2Month(
      today: nov8,
      spends: w1Spends(),
      covers: covers,
      periods: [
        period(d(2026, 11, 5), e2Values()),
        period(nov8, e2Values(rent: 1300000)),
      ],
    );
    expect(before.totals.pot, p(23000));
    expect(after.totals.pot, p(23000));
    expect(after.days.take(3).toList(), before.days.take(3).toList());
  });

  test('TC-006-54 shortfall period appears in the period history', () {
    final result = e2Month(
      today: d(2026, 11, 25),
      periods: [
        period(d(2026, 11, 5), e2Values()),
        period(_nov20, e2Values(target: 2500000), continued: true),
      ],
      spends: [spend(d(2026, 11, 10), 50000), spend(d(2026, 11, 22), 30000)],
    );
    expect(result.periods, hasLength(2));
    final p2 = result.periods.last;
    expect(p2.shortfall, p(255000));
    expect(p2.budgets, runs([(15, 0)]));
    final nov22 = result.dayOn(d(2026, 11, 22));
    expect((nov22.status, nov22.result), (DayStatus.overspent, p(-30000)));
    expect(p2.overspent, p(30000));
    expect(result.totals.shortfall, p(255000));
    expectPeriodsAddUp(result);
  });

  test('TC-006-55 three same day changes keep the latest values', () {
    final result = e2Month(
      today: _nov20,
      periods: [
        period(d(2026, 11, 5), e2Values()),
        period(_nov20, e2Values(salary: 3500000), changedAt: at(_nov20, 17)),
        period(_nov20, e2Values(rent: 1300000), changedAt: at(_nov20, 9)),
        period(
          _nov20,
          e2Values(salary: 3500000, rent: 1300000),
          changedAt: at(_nov20, 12),
        ),
      ],
    );
    expect(
      budgetsOf(result, _nov20, d(2026, 12, 4)),
      runs([(10, 49667), (5, 49666)]),
    );
    expect(
      [for (final p in result.periods.skip(1)) p.period.changedAt],
      [at(_nov20, 9), at(_nov20, 12), at(_nov20, 17)],
    );
    expect(result.periods.map((p) => p.superseded), [false, true, true, false]);
    expect(result.periods[2].changes, [
      (
        field: PeriodField.salary,
        name: null,
        before: p(4000000),
        after: p(3500000),
      ),
    ]);
    expect(result.periods[3].changes, [
      (
        field: PeriodField.fixedCost,
        name: 'Rent',
        before: p(1300000),
        after: p(1000000),
      ),
    ]);
    expect(result.totals.salary, p(3500000));
  });
}
