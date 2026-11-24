// F-014 TC-014-48: over random engine months the statement's periods add up
// to the month, and the check line holds to the paisa on ended periods and
// months (D-060: only there).

import 'dart:math';

import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

/// A random month of 1 to 10 periods, every period continued anyway so a
/// random shortfall is still a month the screens could have saved.
MonthInput _randomMonth(Random random) {
  final salaryDay = 1 + random.nextInt(31);
  final month = BudgetMonth.startIn(salaryDay, 2026, 1 + random.nextInt(12));
  final wanted = 1 + random.nextInt(10);
  final starts = <int>{0};
  while (starts.length < wanted && starts.length < month.length) {
    starts.add(random.nextInt(month.length));
  }
  final sorted = starts.toList()..sort();

  FullMonthValues values() {
    final salary = 3000000 + random.nextInt(9000000);
    return FullMonthValues(
      salary: Paise(salary),
      fixedCosts: [
        for (var i = 0; i < random.nextInt(4); i++)
          FixedCost(
            name: 'Cost $i',
            amount: Paise(random.nextInt(salary ~/ 3 + 1)),
          ),
      ],
    );
  }

  final periods = [
    for (final (i, offset) in sorted.indexed)
      period(
        month.start.addDays(offset),
        values(),
        changedAt: at(month.start.addDays(offset), 9) + i,
        continued: true,
      ),
  ];
  return MonthInput(
    month: month,
    firstBudgetedDay: month.start,
    periods: periods,
    today: month.end.addDays(1 + random.nextInt(5)),
    spends: [
      for (var i = 0; i < random.nextInt(60); i++)
        Spend(
          id: i + 1,
          date: month.start.addDays(random.nextInt(month.length)),
          amount: Paise(1 + random.nextInt(random.nextBool() ? 400000 : 4000)),
          createdAt: i,
          direction: random.nextInt(8) == 0
              ? SpendDirection.moneyIn
              : SpendDirection.spend,
        ),
    ],
    covers: [
      for (var i = 0; i < random.nextInt(4); i++)
        Cover(
          id: i + 1,
          day: month.start.addDays(random.nextInt(month.length)),
          amount: Paise(1 + random.nextInt(50000)),
          madeAt: i,
        ),
    ],
  );
}

void main() {
  test('TC-014-48 every ended period and month satisfies the check line', () {
    final random = Random(propertySeed);
    var manyPeriods = 0;
    for (var run = 0; run < 500; run++) {
      final result = computeMonth(_randomMonth(random));
      final statement = buildStatement(result);
      final why = 'run $run';
      expectPeriodsAddUp(result);
      if (statement.periods.length > 5) manyPeriods++;

      expect(statement.soFarTo, isNull, reason: why);
      expect(
        Paise.sum(statement.periods.map((x) => x.totals.budget)),
        statement.totals.moneyForMonth,
        reason: why,
      );
      expect(
        statement.periods.fold(0, (days, x) => days + x.days),
        result.month.length,
        reason: why,
      );
      for (final x in statement.periods) {
        final t = x.totals;
        expect(
          t.budget - t.netSpent,
          t.saved - t.overspent - t.covered,
          reason: why,
        );
        expect(t.netSpent + t.refunds, t.spent, reason: why);
      }
      final t = statement.totals;
      expect(
        t.moneyForMonth - t.netSpent,
        t.saved - t.overspent - t.covered,
        reason: why,
      );
      expect(t.pot, t.saved - t.covered, reason: why);
      expect(t.netSpent + t.refunds, t.spent, reason: why);
    }
    // The generator really makes months with several periods.
    expect(manyPeriods, greaterThan(50));
  });
}
