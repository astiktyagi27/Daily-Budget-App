import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

// Gate 3 hardening (T-226, docs/reviews/code-phase-2.md): the current period,
// duplicate cover ids, dates outside the month and the day's net spend.

void main() {
  test('TC-006-21 currentPeriod is the period in force today', () {
    final nov20 = d(2026, 11, 20);
    final periods = [
      period(d(2026, 11, 5), e2Values()),
      period(nov20, e2Values(rent: 1100000), changedAt: at(nov20, 9)),
      period(nov20, e2Values(rent: 1200000), changedAt: at(nov20, 12)),
    ];
    MonthResult on(CalendarDate today) =>
        e2Month(today: today, periods: periods);

    // Before the month: the first period. After it: the last effective one.
    expect(on(d(2026, 11, 4)).currentPeriodIndex, 0);
    expect(on(d(2026, 11, 19)).currentPeriodIndex, 0);
    // The same-day change at 09:00 is superseded and never current.
    final onChangeDay = on(nov20);
    expect(onChangeDay.periods[1].superseded, isTrue);
    expect(onChangeDay.currentPeriodIndex, 2);
    expect(onChangeDay.currentPeriod.period, periods[2]);
    expect(on(d(2026, 12, 10)).currentPeriodIndex, 2);
  });

  test('TC-006-43 currentPeriod carries the zero-spendable flag', () {
    final zero = e2Month(
      today: d(2026, 11, 6),
      periods: [
        period(
          d(2026, 11, 5),
          const FullMonthValues(
            salary: Paise(100000),
            target: Paise(100000),
            fixedCosts: [FixedCost(name: 'Rent', amount: Paise(100000))],
          ),
          continued: true,
        ),
      ],
    );
    expect(zero.currentPeriod.zeroSpendable, isTrue);
    expect(zero.currentPeriod.shortfall, Paise.zero);
  });

  test('TC-006-56 duplicate cover ids are rejected', () {
    final twin = cover(1, d(2026, 11, 7), 5000, at(d(2026, 11, 8), 9));
    expect(
      () => e2Month(
        today: d(2026, 11, 9),
        spends: [spend(d(2026, 11, 7), 100000)],
        covers: [twin, cover(1, d(2026, 11, 7), 5000, at(d(2026, 11, 8), 9))],
      ),
      throwsArgumentError,
    );
  });

  test('TC-006-56 dayOn rejects a date outside the month', () {
    final result = e2Month(today: d(2026, 11, 9));
    expect(() => result.dayOn(d(2026, 11, 4)), throwsArgumentError);
    expect(() => result.dayOn(d(2026, 12, 5)), throwsArgumentError);
    expect(result.dayOn(d(2026, 12, 4)).date, d(2026, 12, 4));
  });

  test('TC-006-60 day netSpent is spends minus money in', () {
    final result = e2Month(
      today: d(2026, 11, 14),
      spends: [
        spend(d(2026, 11, 12), 30000),
        spend(d(2026, 11, 12), 50000, moneyIn: true),
        spend(d(2026, 11, 13), 20000),
      ],
    );
    expect(result.dayOn(d(2026, 11, 12)).spent, p(30000));
    expect(result.dayOn(d(2026, 11, 12)).netSpent, p(-20000));
    expect(result.dayOn(d(2026, 11, 13)).netSpent, p(20000));
    expect(result.dayOn(d(2026, 11, 8)).netSpent, Paise.zero);
    expect(result.periods.first.netSpent, p(0));
  });
}
