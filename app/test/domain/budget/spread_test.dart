import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  test('TC-006-04 spendable is target minus fixed costs', () {
    final noCosts = FullMonthValues(salary: p(4000000));
    expect(noCosts.spendable, p(4000000));
    expect(noCosts.monthlyTarget, p(4000000));
    expect(noCosts.fixedCostsTotal, Paise.zero);
    expect(e2Values().spendable, p(2490000));
    expect(e2Values().fixedCostsTotal, p(1510000));
    expect(
      FullMonthValues(salary: p(4000000), target: p(2000000)).spendable,
      p(2000000),
    );
    expect(e2Values(target: 4000000).spendable, p(2490000));
    expect(e2Values(target: 2000000).spendable, p(490000));
    expect(e2Values(target: 2000000).monthlyTarget, p(2000000));
    expect(
      MidMonthStartValues(
        moneyLeft: p(2490000),
        fixedCostsStillToPay: const [
          FixedCost(name: 'Rent', amount: Paise(490000)),
        ],
      ).spendable,
      p(2000000),
    );
  });

  test('TC-006-08 extra paise go to the first days of the spread range', () {
    MonthResult full(BudgetMonth month, PeriodValues values) => computeMonth(
      MonthInput(
        month: month,
        firstBudgetedDay: month.start,
        periods: [period(month.start, values)],
        today: month.start,
      ),
    );
    final e1 = full(nov2026, FullMonthValues(salary: p(4000000)));
    expect(datesWithBudget(e1, 133334), dates(d(2026, 11, 5), d(2026, 11, 14)));
    final e3 = full(
      nov2026,
      FullMonthValues(salary: p(4000000), target: p(2000000)),
    );
    expect(datesWithBudget(e3, 66667), dates(d(2026, 11, 5), d(2026, 11, 24)));
    final e5 = full(oct2026, e2Values());
    expect(datesWithBudget(e5, 80323), dates(d(2026, 10, 5), d(2026, 10, 22)));
    expect(datesWithBudget(e5, 80322), dates(d(2026, 10, 23), d(2026, 11, 4)));

    final example2 = computeMonth(
      MonthInput(
        month: nov2026,
        firstBudgetedDay: d(2026, 11, 11),
        periods: [
          period(d(2026, 11, 11), MidMonthStartValues(moneyLeft: p(2000000))),
        ],
        today: d(2026, 11, 11),
      ),
    );
    expect(
      datesWithBudget(example2, 83334),
      dates(d(2026, 11, 11), d(2026, 11, 18)),
    );

    final c2 = e2Month(
      today: d(2026, 11, 20),
      periods: [
        period(d(2026, 11, 5), e2Values()),
        period(d(2026, 11, 20), e2Values(rent: 1100000)),
      ],
    );
    expect(datesWithBudget(c2, 76334), dates(d(2026, 11, 20), d(2026, 11, 24)));
    expect(datesWithBudget(c2, 76333), dates(d(2026, 11, 25), d(2026, 12, 4)));
    expect(datesWithBudget(c2, 83000), dates(d(2026, 11, 5), d(2026, 11, 19)));
  });

  test('TC-006-05 readme examples are exact to the paisa', () {
    final nov = BudgetMonth.startIn(5, 2026, 11);
    final oct = BudgetMonth.startIn(5, 2026, 10);
    expect(nov.length, 30);
    expect(oct.length, 31);

    // (month, amount, expected runs)
    final examples = <String, (BudgetMonth, int, List<(int, int)>)>{
      'E1': (nov, 4000000, [(10, 133334), (20, 133333)]),
      'E2': (nov, 2490000, [(30, 83000)]),
      'E3': (nov, 2000000, [(20, 66667), (10, 66666)]),
      'E4': (oct, 4000000, [(8, 129033), (23, 129032)]),
      'E5': (oct, 2490000, [(18, 80323), (13, 80322)]),
    };
    for (final MapEntry(key: name, value: (month, amount, expected))
        in examples.entries) {
      final budgets = Paise(amount).spreadOver(month.length);
      expect(budgets, runs(expected), reason: name);
      expect(budgets, hasLength(month.length), reason: name);
      expect(Paise.sum(budgets), Paise(amount), reason: name);
    }

    // The same through the engine, from salary and fixed costs.
    final viaEngine = <String, (BudgetMonth, PeriodValues, List<(int, int)>)>{
      'E1': (nov, FullMonthValues(salary: p(4000000)), examples['E1']!.$3),
      'E2': (nov, e2Values(), examples['E2']!.$3),
      'E3': (
        nov,
        FullMonthValues(salary: p(4000000), target: p(2000000)),
        examples['E3']!.$3,
      ),
      'E4': (oct, FullMonthValues(salary: p(4000000)), examples['E4']!.$3),
      'E5': (oct, e2Values(), examples['E5']!.$3),
    };
    for (final MapEntry(key: name, value: (month, values, expected))
        in viaEngine.entries) {
      final result = computeMonth(
        MonthInput(
          month: month,
          firstBudgetedDay: month.start,
          periods: [period(month.start, values)],
          today: month.start,
        ),
      );
      expect(allBudgets(result), runs(expected), reason: name);
      expect(result.totals.budgeted, values.spendable, reason: name);
    }
  });

  test('TC-006-32 twenty eight day month spreads exactly', () {
    final month = BudgetMonth.startIn(1, 2027, 2);
    expect((month.start, month.end), (d(2027, 2, 1), d(2027, 2, 28)));
    final budgets = p(4000000).spreadOver(month.length);
    expect(budgets, runs([(4, 142858), (24, 142857)]));
    expect(Paise.sum(budgets), p(4000000));
  });

  test('TC-006-33 leap february has twenty nine days and sums exactly', () {
    final month = BudgetMonth.startIn(1, 2028, 2);
    expect((month.start, month.end), (d(2028, 2, 1), d(2028, 2, 29)));
    expect(month.length, 29);
    final budgets = p(4000000).spreadOver(month.length);
    expect(budgets, runs([(1, 137932), (28, 137931)]));
    expect(Paise.sum(budgets), p(4000000));
  });

  test('TC-006-36 tiny amounts and remainder n minus one spread exactly', () {
    expect(p(29).spreadOver(30), runs([(29, 1), (1, 0)]));
    expect(p(1).spreadOver(31), runs([(1, 1), (30, 0)]));
    expect(p(30).spreadOver(30), runs([(30, 1)]));
    expect(p(0).spreadOver(1), [p(0)]);
    expect(Paise.sum(p(29).spreadOver(30)), p(29));
  });

  test('TC-006-37 year crossing month spreads exactly', () {
    final month = BudgetMonth.startIn(25, 2026, 12);
    expect((month.start, month.end), (d(2026, 12, 25), d(2027, 1, 24)));
    final budgets = p(4000000).spreadOver(month.length);
    expect(budgets, runs([(8, 129033), (23, 129032)]));
    // The 8 days with the extra paisa are 25 Dec to 1 Jan.
    expect(month.days[7], d(2027, 1, 1));
    expect(Paise.sum(budgets), p(4000000));
  });

  test('TC-006-56 invalid engine inputs are rejected', () {
    // Spreading: no days, or a negative amount.
    expect(() => p(100).spreadOver(0), throwsArgumentError);
    expect(() => p(100).spreadOver(-1), throwsArgumentError);
    expect(() => p(-1).spreadOver(30), throwsArgumentError);

    // Salary day outside 1 to 31.
    for (final salaryDay in [0, 32, -5]) {
      expect(
        () => BudgetMonth.startIn(salaryDay, 2026, 11),
        throwsArgumentError,
      );
      expect(
        () => BudgetMonth.containing(salaryDay, d(2026, 11, 9)),
        throwsArgumentError,
      );
    }

    // Dates that do not exist.
    expect(() => d(2026, 2, 29), throwsArgumentError);
    expect(() => d(2026, 13, 1), throwsArgumentError);
    expect(() => d(2026, 0, 1), throwsArgumentError);
    expect(() => d(2026, 4, 31), throwsArgumentError);
    expect(() => d(2026, 4, 0), throwsArgumentError);

    // Negative salary, target, fixed cost or money left; target above salary.
    final nov5 = d(2026, 11, 5);
    final badValues = <PeriodValues>[
      FullMonthValues(salary: p(-1)),
      FullMonthValues(salary: p(100), target: p(-1)),
      FullMonthValues(salary: p(100), target: p(101)),
      FullMonthValues(
        salary: p(100),
        fixedCosts: [FixedCost(name: 'Rent', amount: p(-1))],
      ),
      MidMonthStartValues(moneyLeft: p(-1)),
      MidMonthStartValues(
        moneyLeft: p(100),
        fixedCostsStillToPay: [FixedCost(name: 'Rent', amount: p(-1))],
      ),
    ];
    for (final values in badValues) {
      expect(values.validate, throwsArgumentError);
      expect(
        () => e2Month(today: nov5, periods: [period(nov5, values)]),
        throwsArgumentError,
      );
    }
    // A target equal to the salary is allowed.
    FullMonthValues(salary: p(100), target: p(100)).validate();

    // planPeriod: days outside the month or before the first budgeted day,
    // or the wrong number of earlier budgets.
    void plan(CalendarDate first, CalendarDate from, int earlierDays) =>
        planPeriod(
          month: nov2026,
          firstBudgetedDay: first,
          earlierBudgets: List.filled(earlierDays, p(83000)),
          values: e2Values(),
          from: from,
        );
    expect(() => plan(d(2026, 11, 4), nov5, 0), throwsArgumentError);
    expect(() => plan(nov5, d(2026, 12, 5), 30), throwsArgumentError);
    expect(() => plan(d(2026, 11, 10), nov5, 0), throwsArgumentError);
    expect(() => plan(nov5, d(2026, 11, 10), 4), throwsArgumentError);
    plan(nov5, d(2026, 11, 10), 5);

    // computeMonth: first budgeted day, periods, spends and covers.
    expect(
      () => e2Month(today: nov5, firstBudgetedDay: d(2026, 12, 5)),
      throwsArgumentError,
    );
    expect(() => e2Month(today: nov5, periods: const []), throwsArgumentError);
    expect(
      () => e2Month(
        today: nov5,
        firstBudgetedDay: d(2026, 11, 10),
        periods: [
          period(d(2026, 11, 10), e2Values()),
          period(nov5, e2Values()),
        ],
      ),
      throwsArgumentError,
    );
    expect(
      () => e2Month(
        today: nov5,
        periods: [period(nov5, e2Values()), period(d(2026, 12, 5), e2Values())],
      ),
      throwsArgumentError,
    );
    for (final bad in [
      spend(nov5, 0),
      spend(nov5, -100),
      spend(nov5, 0, moneyIn: true),
      spend(nov5, -100, moneyIn: true),
    ]) {
      expect(() => e2Month(today: nov5, spends: [bad]), throwsArgumentError);
    }
    for (final bad in [
      cover(1, nov5, -1, 0),
      cover(1, d(2026, 12, 5), 100, 0),
      cover(1, d(2026, 11, 4), 100, 0),
    ]) {
      expect(() => e2Month(today: nov5, covers: [bad]), throwsArgumentError);
    }
    expect(
      () => e2Month(
        today: nov5,
        firstBudgetedDay: d(2026, 11, 10),
        periods: [
          period(d(2026, 11, 10), MidMonthStartValues(moneyLeft: p(100))),
        ],
        covers: [cover(1, d(2026, 11, 7), 100, 0)],
      ),
      throwsArgumentError,
    );

    // Month state: the salary day must match the last month's.
    expect(
      () => monthStateFor(salaryDay: 6, lastMonth: nov2026, today: nov5),
      throwsArgumentError,
    );
  });
}
