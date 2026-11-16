import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

final CalendarDate _nov5 = d(2026, 11, 5);
final CalendarDate _nov20 = d(2026, 11, 20);

SpreadOutcome _planStart(PeriodValues values) => planPeriod(
  month: nov2026,
  firstBudgetedDay: _nov5,
  earlierBudgets: const [],
  values: values,
  from: _nov5,
);

void main() {
  test('TC-006-17 zero amounts never divide by zero', () {
    // (a) Spendable exactly ₹0: every day ₹0, no shortfall (D-043).
    final zero = FullMonthValues(salary: p(1510000), fixedCosts: e2Costs());
    expect(zero.spendable, Paise.zero);
    final outcome = _planStart(zero);
    expect(outcome, isA<ZeroSpendable>());
    expect(outcome.budgets, runs([(30, 0)]));
    expect(outcome.amountToSpread, Paise.zero);
    final a = e2Month(
      today: d(2026, 11, 7),
      periods: [period(_nov5, zero, continued: true)],
      spends: [spend(d(2026, 11, 6), 100)],
    );
    expect(allBudgets(a), runs([(30, 0)]));
    expect(a.totals.shortfall, Paise.zero);
    expect(a.periods.single.zeroSpendable, isTrue);
    final nov6 = a.dayOn(d(2026, 11, 6));
    expect((nov6.status, nov6.result), (DayStatus.overspent, p(-100)));

    // (b) A ₹0 fixed cost changes nothing but is listed as added.
    final withGym = FullMonthValues(
      salary: p(4000000),
      fixedCosts: [
        ...e2Costs(),
        const FixedCost(name: 'Gym', amount: Paise.zero),
      ],
    );
    final b = e2Month(today: _nov5, periods: [period(_nov5, withGym)]);
    expect(allBudgets(b), runs([(30, 83000)]));
    expect(b.totals.fixedCosts, p(1510000));
    expect(withGym.changesFrom(e2Values()), [
      (field: PeriodField.fixedCost, name: 'Gym', before: null, after: p(0)),
    ]);
    expect(e2Values().changesFrom(withGym), [
      (field: PeriodField.fixedCost, name: 'Gym', before: p(0), after: null),
    ]);

    // (c) Past days with no spends are saved in full.
    final c = e2Month(today: d(2026, 11, 8));
    for (final day in dates(_nov5, d(2026, 11, 7))) {
      final result = c.dayOn(day);
      expect((result.status, result.result), (DayStatus.saved, p(83000)));
    }
    expect(c.totals.pot, p(249000));
  });

  test('TC-006-18 shortfall at month start is reported '
      'and can be continued at zero', () {
    // 1. Not continued: a shortfall of ₹1,000, no negative day, not saved.
    final outcome = _planStart(s1Values());
    expect(outcome, isA<Shortfall>());
    expect((outcome as Shortfall).amount, p(100000));
    expect(outcome.budgets.any((budget) => budget.isNegative), isFalse);
    expect(
      () =>
          e2Month(today: d(2026, 11, 6), periods: [period(_nov5, s1Values())]),
      throwsArgumentError,
    );

    // 2. Continued anyway: ₹0 a day, a ₹200 spend is overspent.
    final s1 = [period(_nov5, s1Values(), continued: true)];
    final spends = [spend(d(2026, 11, 6), 20000)];
    final onNov6 = e2Month(today: d(2026, 11, 6), periods: s1, spends: spends);
    expect(allBudgets(onNov6), runs([(30, 0)]));
    final nov6 = onNov6.dayOn(d(2026, 11, 6));
    expect((nov6.status, nov6.result), (DayStatus.live, p(-20000)));
    expect(onNov6.totals.overspent, p(20000));
    expect(onNov6.totals.shortfall, p(100000));
    expect(onNov6.totals.left, p(-120000));
    final onNov7 = e2Month(today: d(2026, 11, 7), periods: s1, spends: spends);
    expect(onNov7.dayOn(d(2026, 11, 6)).status, DayStatus.overspent);
  });

  test(
    'TC-006-24 change causing a shortfall reports it and continues at zero',
    () {
      final c4 = e2Values(target: 2500000);
      final outcome = planPeriod(
        month: nov2026,
        firstBudgetedDay: _nov5,
        earlierBudgets: runs([(15, 83000)]),
        values: c4,
        from: _nov20,
      );
      expect(outcome, isA<Shortfall>());
      expect((outcome as Shortfall).amount, p(255000));
      expect(outcome.budgets, runs([(15, 0)]));
      expect(
        () => e2Month(
          today: _nov20,
          periods: [period(_nov5, e2Values()), period(_nov20, c4)],
        ),
        throwsArgumentError,
      );

      final result = e2Month(
        today: d(2026, 11, 22),
        periods: [
          period(_nov5, e2Values()),
          period(_nov20, c4, continued: true),
        ],
        spends: [spend(d(2026, 11, 10), 50000)],
      );
      expect(budgetsOf(result, _nov20, d(2026, 12, 4)), runs([(15, 0)]));
      expect(budgetsOf(result, _nov5, d(2026, 11, 19)), runs([(15, 83000)]));
      expect(result.totals.shortfall, p(255000));
      // Left = 12,45,000 − 50,000 − 2,55,000.
      expect(result.totals.left, p(940000));
    },
  );

  test(
    'TC-006-42 lowering costs after a shortfall gives days a budget again',
    () {
      final result = e2Month(
        today: d(2026, 11, 22),
        periods: [
          period(_nov5, s1Values(), continued: true),
          period(_nov20, s1Values(emi: 0)),
        ],
        spends: [spend(d(2026, 11, 6), 20000)],
      );
      expect(budgetsOf(result, _nov5, d(2026, 11, 19)), runs([(15, 0)]));
      expect(
        budgetsOf(result, _nov20, d(2026, 12, 4)),
        runs([(5, 33334), (10, 33333)]),
      );
      expect(result.periods.last.amountToSpread, p(500000));
      expect(result.periods.last.shortfall, Paise.zero);
      expect(result.periods.first.shortfall, p(100000));
      expect(result.totals.shortfall, Paise.zero);
      // Left = current spendable 5,00,000 − spent 20,000.
      expect(result.totals.left, p(480000));
    },
  );

  test('TC-006-51 thirty ten crore costs give an exact shortfall', () {
    const tenCrore = 10000000000;
    final values = FullMonthValues(
      salary: p(tenCrore),
      fixedCosts: [
        for (var i = 0; i < 30; i++)
          FixedCost(name: 'Cost $i', amount: p(tenCrore)),
      ],
    );
    expect(values.fixedCostsTotal, p(300000000000));
    final outcome = _planStart(values);
    expect((outcome as Shortfall).amount, p(290000000000));
    final result = e2Month(
      today: _nov5,
      periods: [period(_nov5, values, continued: true)],
    );
    expect(result.totals.fixedCosts, p(300000000000));
    expect(result.totals.shortfall, p(290000000000));
    expect(result.totals.left, p(-290000000000));
  });
}
