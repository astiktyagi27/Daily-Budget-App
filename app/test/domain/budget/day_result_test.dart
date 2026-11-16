import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

final CalendarDate _nov5 = d(2026, 11, 5);

void main() {
  test('TC-006-09 day result status for every case', () {
    // The §2.3 rows on days before today (12 Nov). 10 and 11 Nov are saved,
    // so the pot can pay for the two covers.
    final result = e2Month(
      today: d(2026, 11, 12),
      spends: [
        spend(_nov5, 50000),
        spend(d(2026, 11, 6), 83000),
        spend(d(2026, 11, 7), 100000),
        spend(d(2026, 11, 8), 100000),
        spend(d(2026, 11, 9), 100000),
      ],
      covers: [
        cover(1, d(2026, 11, 8), 17000, at(d(2026, 11, 11), 10)),
        cover(2, d(2026, 11, 9), 10000, at(d(2026, 11, 11), 11)),
      ],
    );
    final rows = <(int, DayStatus, int, int)>[
      (5, DayStatus.saved, 33000, 0),
      (6, DayStatus.onBudget, 0, 0),
      (7, DayStatus.overspent, -17000, 0),
      (8, DayStatus.onBudget, 0, 17000),
      (9, DayStatus.overspent, -7000, 10000),
    ];
    for (final (day, status, value, covered) in rows) {
      final row = result.dayOn(d(2026, 11, day));
      expect(row.budget, p(83000), reason: '$day Nov');
      expect(row.status, status, reason: '$day Nov');
      expect(row.result, p(value), reason: '$day Nov');
      expect(row.covered, p(covered), reason: '$day Nov');
    }
    expect(result.reductions, isEmpty);

    // ₹0 budget in a continued shortfall month: a ₹200 spend is overspent.
    final s1 = e2Month(
      today: d(2026, 11, 7),
      periods: [period(_nov5, s1Values(), continued: true)],
      spends: [spend(d(2026, 11, 6), 20000)],
    );
    final zeroDay = s1.dayOn(d(2026, 11, 6));
    expect(
      (zeroDay.budget, zeroDay.status, zeroDay.result),
      (Paise.zero, DayStatus.overspent, p(-20000)),
    );

    // W1 on 8 Nov: 9 Nov is upcoming, 8 Nov is live with 63,000 left.
    final w1 = e2Month(today: d(2026, 11, 8), spends: w1Spends());
    final nov9 = w1.dayOn(d(2026, 11, 9));
    expect((nov9.status, nov9.result), (DayStatus.upcoming, null));
    expect(nov9.budget, p(83000));
    final nov8 = w1.dayOn(d(2026, 11, 8));
    expect((nov8.status, nov8.result), (DayStatus.live, p(63000)));

    // Mid-month install on 10 Nov: 5 Nov is not budgeted and in no total.
    final mid = computeMonth(
      MonthInput(
        month: nov2026,
        firstBudgetedDay: d(2026, 11, 10),
        periods: [
          period(d(2026, 11, 10), MidMonthStartValues(moneyLeft: p(2490000))),
        ],
        today: d(2026, 11, 12),
      ),
    );
    final notBudgeted = mid.dayOn(_nov5);
    expect(notBudgeted.status, DayStatus.notBudgeted);
    expect((notBudgeted.budget, notBudgeted.result), (null, null));
    expect(mid.totals.budgeted, p(2490000));
    expect(mid.totals.saved, p(199200));
  });

  test('TC-006-10 a saving or overspend never changes the next day budget', () {
    final nov7 = d(2026, 11, 7);
    final saved = e2Month(today: nov7, spends: [spend(_nov5, 50000)]);
    final overspent = e2Month(today: nov7, spends: [spend(_nov5, 100000)]);
    final none = e2Month(today: nov7);
    for (final result in [saved, overspent, none]) {
      expect(result.dayOn(d(2026, 11, 6)).budget, p(83000));
    }
    expect(allBudgets(saved), allBudgets(none));
    expect(allBudgets(overspent), allBudgets(none));
    expect(saved.dayOn(_nov5).result, p(33000));
    expect(overspent.dayOn(_nov5).result, p(-17000));
  });

  test('TC-006-35 leap day spend belongs to its budget month', () {
    final month = BudgetMonth.containing(15, d(2028, 2, 29));
    expect((month.start, month.end), (d(2028, 2, 15), d(2028, 3, 14)));
    expect(month.length, 29);
    final result = computeMonth(
      MonthInput(
        month: month,
        firstBudgetedDay: month.start,
        // 29 days at 83,000.
        periods: [period(month.start, FullMonthValues(salary: p(2407000)))],
        today: d(2028, 3, 1),
        spends: [spend(d(2028, 2, 29), 100000)],
      ),
    );
    expect(allBudgets(result), runs([(29, 83000)]));
    final leapDay = result.dayOn(d(2028, 2, 29));
    expect(
      (leapDay.budget, leapDay.status, leapDay.result),
      (p(83000), DayStatus.overspent, p(-17000)),
    );
    expect(result.totals.spentSoFar, p(100000));
    expect(result.ignoredSpends, isEmpty);
  });

  test('TC-006-60 money in lowers the day spend and can make it negative', () {
    final nov12 = d(2026, 11, 12);
    final nov13 = d(2026, 11, 13);
    final nov14 = d(2026, 11, 14);

    // (a) + (b): a ₹300 spend and a ₹500 refund; a refund alone.
    final ab = e2Month(
      today: nov14,
      spends: [
        spend(nov12, 30000),
        spend(nov12, 50000, moneyIn: true),
        spend(nov13, 50000, moneyIn: true),
      ],
    );
    final day12 = ab.dayOn(nov12);
    expect((day12.spent, day12.moneyIn), (p(30000), p(50000)));
    expect(day12.netSpent, p(-20000));
    expect((day12.status, day12.result), (DayStatus.saved, p(103000)));
    expect(ab.dayOn(nov13).result, p(133000));
    expect(ab.totals.spentSoFar, p(30000 - 100000));
    expect(ab.totals.moneyIn, p(100000));
    // Pot: 5–11 Nov saved 7 × 83,000, plus both refund days.
    expect(ab.totals.pot, p(581000 + 103000 + 133000));

    // (c) A refund on a covered day returns the excess cover to the pot.
    final c = e2Month(
      today: d(2026, 11, 8),
      spends: [...w1Spends(), spend(d(2026, 11, 6), 10000, moneyIn: true)],
      covers: [cover(1, d(2026, 11, 6), 17000, at(d(2026, 11, 7), 9))],
    );
    final nov6 = c.dayOn(d(2026, 11, 6));
    expect((nov6.covered, nov6.result), (p(7000), Paise.zero));
    expect(c.effectiveCovers.single.amount, p(7000));
    expect(c.totals.pot, p(26000));
    expect(c.reductions, isEmpty);

    // (d) A refund dated today: more left today than the budget.
    final d14 = e2Month(
      today: nov14,
      spends: [spend(nov14, 50000, moneyIn: true)],
    );
    final today = d14.dayOn(nov14);
    expect((today.status, today.result), (DayStatus.live, p(133000)));

    // (e) Shortfall month at ₹0 a day: a refund alone is saved.
    final e = e2Month(
      today: d(2026, 11, 7),
      periods: [period(_nov5, s1Values(), continued: true)],
      spends: [spend(d(2026, 11, 6), 50000, moneyIn: true)],
    );
    final refundDay = e.dayOn(d(2026, 11, 6));
    expect(
      (refundDay.budget, refundDay.status, refundDay.result),
      (Paise.zero, DayStatus.saved, p(50000)),
    );

    // A money-in amount of ₹0 or less is invalid.
    for (final amount in [0, -1]) {
      expect(
        () => e2Month(
          today: nov14,
          spends: [spend(nov12, amount, moneyIn: true)],
        ),
        throwsArgumentError,
      );
    }
  });
}
