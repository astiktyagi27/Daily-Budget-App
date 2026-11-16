import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

MonthResult _midMonth(
  CalendarDate first,
  PeriodValues values, {
  CalendarDate? today,
  List<Spend> spends = const [],
  bool continued = false,
  List<BudgetPeriod> laterPeriods = const [],
}) => computeMonth(
  MonthInput(
    month: nov2026,
    firstBudgetedDay: first,
    periods: [
      period(first, values, continued: continued),
      ...laterPeriods,
    ],
    today: today ?? first,
    spends: spends,
  ),
);

MidMonthStartValues _moneyLeft(int paise, {int stillToPay = 0}) =>
    MidMonthStartValues(
      moneyLeft: Paise(paise),
      fixedCostsStillToPay: [
        if (stillToPay > 0) FixedCost(name: 'Rent', amount: Paise(stillToPay)),
      ],
    );

void main() {
  test('TC-006-20 mid month install spreads money left over the days left', () {
    // (a) 10 Nov, ₹24,900 left: 25 days at 99,600.
    final a = _midMonth(d(2026, 11, 10), _moneyLeft(2490000));
    expect(allBudgets(a), runs([(25, 99600)]));
    expect(Paise.sum(allBudgets(a)), p(2490000));
    for (final day in dates(d(2026, 11, 5), d(2026, 11, 9))) {
      final result = a.dayOn(day);
      expect(result.status, DayStatus.notBudgeted, reason: day.iso);
      expect(result.budget, isNull);
      expect(result.result, isNull);
    }
    expect(a.dayOn(d(2026, 11, 10)).budget, p(99600));
    expect(a.totals.salary, isNull);
    expect(a.totals.target, isNull);
    expect(a.totals.budgeted, p(2490000));

    // (b) 11 Nov, ₹20,000 left: 8 days at 83,334, then 16 at 83,333.
    final b = _midMonth(d(2026, 11, 11), _moneyLeft(2000000));
    expect(allBudgets(b), runs([(8, 83334), (16, 83333)]));
    expect(datesWithBudget(b, 83334), dates(d(2026, 11, 11), d(2026, 11, 18)));
    expect(Paise.sum(allBudgets(b)), p(2000000));
    expect(b.totals.salary, isNull);

    // (c) ₹24,900 left with ₹4,900 still to pay: ₹20,000 over 25 days.
    final c = _midMonth(
      d(2026, 11, 10),
      _moneyLeft(2490000, stillToPay: 490000),
    );
    expect(allBudgets(c), runs([(25, 80000)]));
    expect(c.totals.fixedCosts, p(490000));
    expect(c.totals.salary, isNull);

    // (d) Set up on the start day: a normal full month (E2).
    final full = _midMonth(d(2026, 11, 5), e2Values());
    expect(allBudgets(full), runs([(30, 83000)]));
    expect(full.firstBudgetedDay, d(2026, 11, 5));
    expect(full.totals.salary, p(4000000));
    expect(full.totals.target, p(4000000));
  });

  test('TC-006-38 mid month install on the last day budgets one day', () {
    final result = _midMonth(d(2026, 12, 4), _moneyLeft(50000));
    expect(allBudgets(result), [p(50000)]);
    expect(result.dayOn(d(2026, 12, 4)).budget, p(50000));
    for (final day in dates(d(2026, 11, 5), d(2026, 12, 3))) {
      expect(result.dayOn(day).status, DayStatus.notBudgeted, reason: day.iso);
    }
  });

  test(
    'TC-006-39 mid month install with costs above money left is a shortfall',
    () {
      // (a) ₹10,000 left, ₹12,000 still to pay: shortfall ₹2,000.
      final short = _moneyLeft(1000000, stillToPay: 1200000);
      final outcome = planPeriod(
        month: nov2026,
        firstBudgetedDay: d(2026, 11, 10),
        earlierBudgets: const [],
        values: short,
        from: d(2026, 11, 10),
      );
      expect(outcome, isA<Shortfall>());
      expect((outcome as Shortfall).amount, p(200000));
      expect(outcome.budgets, runs([(25, 0)]));
      // Not continued: the engine will not save it ("needs a choice").
      expect(() => _midMonth(d(2026, 11, 10), short), throwsArgumentError);
      final continued = _midMonth(d(2026, 11, 10), short, continued: true);
      expect(allBudgets(continued), runs([(25, 0)]));
      expect(continued.totals.shortfall, p(200000));

      // (b) ₹10,000 left, ₹10,000 still to pay: ₹0 to spend, no shortfall.
      final zero = _moneyLeft(1000000, stillToPay: 1000000);
      expect(
        planPeriod(
          month: nov2026,
          firstBudgetedDay: d(2026, 11, 10),
          earlierBudgets: const [],
          values: zero,
          from: d(2026, 11, 10),
        ),
        isA<ZeroSpendable>(),
      );
      final zeroMonth = _midMonth(d(2026, 11, 10), zero, continued: true);
      expect(allBudgets(zeroMonth), runs([(25, 0)]));
      expect(zeroMonth.totals.shortfall, Paise.zero);
      expect(zeroMonth.periods.single.zeroSpendable, isTrue);
      expect(zeroMonth.periods.single.shortfall, Paise.zero);
    },
  );

  test(
    'TC-006-43 spends before the first budgeted day are ignored and reported',
    () {
      final early = spend(d(2026, 11, 7), 30000, id: 7);
      final nextMonth = spend(d(2026, 12, 5), 1000, id: 8);
      final counted = spend(d(2026, 11, 11), 1000, id: 9);
      final result = _midMonth(
        d(2026, 11, 10),
        _moneyLeft(2490000),
        today: d(2026, 11, 12),
        spends: [early, nextMonth, counted],
      );
      final nov7 = result.dayOn(d(2026, 11, 7));
      expect(nov7.status, DayStatus.notBudgeted);
      expect(nov7.spent, Paise.zero);
      expect(result.totals.spentSoFar, p(1000));
      expect(result.totals.overspent, Paise.zero);
      expect(result.totals.left, p(2490000 - 1000));
      expect(result.ignoredSpends, [early, nextMonth]);
    },
  );

  test('TC-006-59 correcting money left later keeps past days', () {
    final result = _midMonth(
      d(2026, 11, 10),
      _moneyLeft(2490000),
      today: d(2026, 11, 20),
      laterPeriods: [period(d(2026, 11, 20), _moneyLeft(2640000))],
    );
    expect(
      budgetsOf(result, d(2026, 11, 10), d(2026, 11, 19)),
      runs([(10, 99600)]),
    );
    expect(
      budgetsOf(result, d(2026, 11, 20), d(2026, 12, 4)),
      runs([(15, 109600)]),
    );
    expect(Paise.sum(allBudgets(result)), p(2640000));
    expect(result.periods, hasLength(2));
    final [first, second] = result.periods;
    expect(first.period.values, isA<MidMonthStartValues>());
    expect(second.period.values, isA<MidMonthStartValues>());
    expect(second.amountToSpread, p(1644000));
    expect(second.changes, [
      (
        field: PeriodField.moneyLeft,
        name: null,
        before: p(2490000),
        after: p(2640000),
      ),
    ]);
    expect(first.changes, isEmpty);
  });
}
