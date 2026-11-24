import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/phase3_fixtures.dart';
import 'fixtures.dart';

// The Home summary view model (F-010, plan T-300): the card's facts from the
// engine result, exact paise. Every expected value is a literal from
// tests/F-010-home-summary.md.

HomeSummary _of(Phase3Fixture fixture) => HomeSummary.from(fixture.result);

/// The E2 month for [today] with [spends] (paise on a date).
MonthResult _e2(
  CalendarDate today, {
  List<Spend> spends = const [],
  List<BudgetPeriod>? periods,
}) => e2Month(today: today, spends: spends, periods: periods);

void main() {
  test('TC-010-05 home summary lines are the engine values in paise', () {
    final summary = _of(a13);
    expect(summary.left, p(1937000));
    expect(summary.dailyBudget, p(83000));
    expect(summary.salary, p(4000000));
    expect(summary.fixedCosts, p(1510000));
    expect(summary.spentSoFar, p(553000));
    expect(summary.saved, p(200000));
    expect(summary.overspent, p(47000));
    expect(summary.pot, p(200000));
    expect(summary.covered, Paise.zero);
    // 5,53,000 x 1000 ~/ 24,90,000 = 222 (22.2 %).
    expect(summary.progressPermille, 222);
    expect(summary.rangeStart, d(2026, 11, 5));
    expect(summary.rangeEnd, d(2026, 12, 4));
    expect(summary.target, isNull);
    expect(summary.moneyLeftAtStart, isNull);
    expect(summary.shortfall, Paise.zero);
    expect(summary.hasShortfall, isFalse);
    expect(summary.zeroSpendable, isFalse);
    expect(summary.startedLate, isFalse);
    expect(summary.latestChangeDay, isNull);
    expect(summary.hasChanged, isFalse);
    expect(summary.hasCover, isFalse);
    expect(summary.isOver, isFalse);
    expect(summary.savedHasMark, isTrue);
    expect(summary.overspentHasMark, isTrue);
  });

  test('TC-010-10 today result words follow the exact paise', () {
    TodayResultKind kindOf(int netSpent) {
      final line = TodayLine(
        budget: p(83000),
        netSpent: p(netSpent),
        result: p(83000 - netSpent),
        shortfall: Paise.zero,
      );
      return line.kind;
    }

    expect(kindOf(0), TodayResultKind.leftToday);
    expect(kindOf(41000), TodayResultKind.leftToday);
    expect(kindOf(82999), TodayResultKind.leftUnderRupee);
    expect(kindOf(82901), TodayResultKind.leftUnderRupee); // 99 paise left
    expect(kindOf(82900), TodayResultKind.leftToday); // 100 paise: ₹1 left
    expect(kindOf(83000), TodayResultKind.onBudget);
    expect(kindOf(83001), TodayResultKind.overspentUnderRupee);
    expect(kindOf(83040), TodayResultKind.overspentUnderRupee);
    expect(kindOf(83099), TodayResultKind.overspentUnderRupee);
    expect(kindOf(83100), TodayResultKind.overspent); // 100 over: ₹1
    expect(kindOf(95050), TodayResultKind.overspent);
    final over = TodayLine(
      budget: p(83000),
      netSpent: p(95050),
      result: p(-12050),
      shortfall: Paise.zero,
    );
    expect(over.amount, p(12050));
    expect(formatRupees(over.amount), '₹120');
  });

  test('TC-010-14 shortfall lines follow D-060', () {
    final before = _of(s8);
    expect(before.left, p(-120000));
    expect(before.overspent, p(20000));
    expect(before.saved, Paise.zero);
    expect(before.shortfall, p(100000));
    expect(before.hasShortfall, isTrue);
    expect(before.dailyBudget, Paise.zero);
    expect(before.isOver, isTrue);

    final after = _of(s8Plus150);
    expect(after.left, p(-135000));
    expect(after.overspent, p(35000));
    expect(after.saved, Paise.zero);
    expect(after.spentSoFar, p(35000));
    // Nothing is budgeted: the rule is full (spent is at least the budget).
    expect(after.progressPermille, 1000);
  });

  test('TC-010-18 example M lines are exact to the paisa', () {
    final result = m20.result;
    final summary = HomeSummary.from(result);
    expect(summary.left, p(690000));
    expect(summary.salary, p(3500000));
    expect(summary.fixedCosts, p(1510000));
    expect(summary.spentSoFar, p(1300000));
    expect(summary.saved, p(211558));
    expect(summary.overspent, p(53778));
    expect(summary.covered, p(20000));
    expect(summary.pot, p(191558));
    expect(summary.hasCover, isTrue);
    expect(summary.dailyBudget, p(55222));
    // 13,00,000 x 1000 ~/ 19,90,000 = 653 (653.26).
    expect(summary.progressPermille, 653);
    expect(summary.rangeStart, d(2026, 11, 1));
    expect(summary.rangeEnd, d(2026, 11, 30));

    final today = TodayLine.from(result);
    expect(today.budget, p(55222));
    expect(today.netSpent, p(85000));
    expect(today.result, p(-29778));
    expect(today.kind, TodayResultKind.overspent);
    expect(formatRupees(today.amount), '₹297');

    final withoutCover = _of(m20nc);
    expect(withoutCover.pot, p(211558));
    expect(withoutCover.covered, Paise.zero);
    expect(withoutCover.hasCover, isFalse);
    expect(withoutCover.overspent, p(73778));
    expect(withoutCover.left, p(690000));
    expect(withoutCover.saved, p(211558));
  });

  test('TC-010-16 a change names its latest day', () {
    expect(_of(m20).latestChangeDay, d(2026, 11, 13));
    expect(_of(m20).hasChanged, isTrue);
  });

  test('TC-010-19 the latest change is the last period in force', () {
    final third = e2Month(
      today: d(2026, 11, 28),
      periods: [
        period(d(2026, 11, 5), e2Values(), changedAt: at(d(2026, 11, 4), 0)),
        period(d(2026, 11, 13), e2Values(rent: 900000)),
        period(d(2026, 11, 28), e2Values(rent: 1200000)),
      ],
    );
    expect(HomeSummary.from(third).latestChangeDay, d(2026, 11, 28));
    expect(_of(a13).latestChangeDay, isNull);

    // Two changes on one day: the replaced one has no days and is skipped,
    // the one in force still names that day.
    expect(_of(e2s).latestChangeDay, d(2026, 11, 20));
  });

  test('TC-010-20 a mid month first month shows money left at start', () {
    final summary = _of(f12);
    expect(summary.salary, isNull);
    expect(summary.target, isNull);
    expect(summary.moneyLeftAtStart, p(2490000));
    expect(summary.fixedCosts, Paise.zero);
    expect(summary.left, p(2300000));
    expect(summary.dailyBudget, p(99600));
    expect(summary.rangeStart, d(2026, 11, 10));
    expect(summary.rangeEnd, d(2026, 12, 4));
    expect(summary.startedLate, isTrue);
    expect(summary.spentSoFar, p(190000));
    expect(summary.saved, p(19600));
    expect(summary.overspent, p(10400));
  });

  test('TC-010-21 a late setup starts on its first budgeted day', () {
    final result = computeMonth(
      MonthInput(
        month: BudgetMonth.startIn(5, 2026, 12),
        firstBudgetedDay: d(2026, 12, 12),
        periods: [
          period(
            d(2026, 12, 12),
            const MidMonthStartValues(moneyLeft: Paise(3100000)),
          ),
        ],
        today: d(2026, 12, 12),
      ),
    );
    final summary = HomeSummary.from(result);
    // 31,00,000 over 24 days: 1,29,167 on the first 16 days.
    expect(summary.dailyBudget, p(129167));
    expect(summary.rangeStart, d(2026, 12, 12));
    expect(summary.rangeEnd, d(2027, 1, 4));
    expect(summary.startedLate, isTrue);
    expect(summary.moneyLeftAtStart, p(3100000));
  });

  test('TC-010-22 still to pay costs lower the daily figure', () {
    final result = computeMonth(
      MonthInput(
        month: nov2026,
        firstBudgetedDay: d(2026, 11, 10),
        periods: [
          period(
            d(2026, 11, 10),
            const MidMonthStartValues(
              moneyLeft: Paise(2490000),
              fixedCostsStillToPay: [
                FixedCost(name: 'Rent', amount: Paise(490000)),
              ],
            ),
          ),
        ],
        today: d(2026, 11, 10),
      ),
    );
    final summary = HomeSummary.from(result);
    expect(summary.moneyLeftAtStart, p(2490000));
    expect(summary.fixedCosts, p(490000));
    expect(summary.dailyBudget, p(80000));
    expect(summary.left, p(2000000));
  });

  test('TC-010-23 target row is shown when a lower target is set', () {
    final summary = HomeSummary.from(
      _e2(
        d(2026, 11, 5),
        periods: [period(d(2026, 11, 5), e2Values(target: 2000000))],
      ),
    );
    expect(summary.salary, p(4000000));
    expect(summary.target, p(2000000));
    expect(summary.dailyBudget, p(16334));
    expect(summary.left, p(490000));
  });

  test('TC-010-24 no target row without a lower target', () {
    expect(_of(a13).target, isNull);
    final equal = HomeSummary.from(
      _e2(
        d(2026, 11, 5),
        periods: [period(d(2026, 11, 5), e2Values(target: 4000000))],
      ),
    );
    expect(equal.salary, p(4000000));
    expect(equal.target, isNull);
  });

  test('TC-010-15 a zero spendable month has no shortfall', () {
    final result = computeMonth(
      MonthInput(
        month: nov2026,
        firstBudgetedDay: d(2026, 11, 5),
        periods: [
          period(
            d(2026, 11, 5),
            const FullMonthValues(
              salary: Paise(2000000),
              fixedCosts: [
                FixedCost(name: 'Rent', amount: Paise(1500000)),
                FixedCost(name: 'EMI', amount: Paise(500000)),
              ],
            ),
            continued: true,
          ),
        ],
        today: d(2026, 11, 8),
        spends: [spend(d(2026, 11, 8), 10000, id: 1)],
      ),
    );
    final summary = HomeSummary.from(result);
    expect(summary.zeroSpendable, isTrue);
    expect(summary.hasShortfall, isFalse);
    expect(summary.dailyBudget, Paise.zero);
    expect(summary.left, p(-10000));
    expect(summary.isOver, isTrue);
  });

  test('TC-010-49 a change that removes the shortfall hides the panel', () {
    final result = computeMonth(
      MonthInput(
        month: nov2026,
        firstBudgetedDay: d(2026, 11, 5),
        periods: [
          period(
            d(2026, 11, 5),
            s1Values(),
            changedAt: at(d(2026, 11, 4), 0),
            continued: true,
          ),
          period(d(2026, 11, 10), s1Values(emi: 300000)),
        ],
        today: d(2026, 11, 10),
        spends: [spend(d(2026, 11, 6), 20000, id: 1)],
      ),
    );
    final summary = HomeSummary.from(result);
    expect(summary.hasShortfall, isFalse);
    expect(summary.left, p(180000));
    expect(summary.dailyBudget, p(8000));
    expect(summary.latestChangeDay, d(2026, 11, 10));
    expect(summary.rangeStart, d(2026, 11, 5));
  });

  test('TC-010-59 outside the budgeted days the daily budget is the '
      'period first', () {
    // F12 on 8 Nov: before the first budgeted day (10 Nov).
    expect(
      HomeSummary.from(f12.current.result(d(2026, 11, 8))).dailyBudget,
      p(99600),
    );
    // A13 data on 2 Nov: before the month; on 5 Dec: after its last day.
    for (final day in [d(2026, 11, 2), d(2026, 12, 5)]) {
      final summary = HomeSummary.from(fixtureA.current.result(day));
      expect(summary.dailyBudget, p(83000), reason: day.iso);
    }
    // Future-dated spends are in no total (F-006 AC-13).
    final early = HomeSummary.from(fixtureA.current.result(d(2026, 11, 2)));
    expect(early.spentSoFar, Paise.zero);
  });

  test('TC-010-28 home amounts round toward zero', () {
    HomeSummary summaryWith(
      CalendarDate today,
      List<Spend> spends, {
      List<BudgetPeriod>? periods,
    }) => HomeSummary.from(_e2(today, spends: spends, periods: periods));

    List<Spend> on13(int last) => [
      for (final (i, (day, paise)) in const [
        (5, 50000),
        (6, 100000),
        (7, 83000),
        (8, 20000),
        (9, 62000),
        (10, 83000),
        (11, 113000),
      ].indexed)
        spend(d(2026, 11, day), paise, id: i + 1),
      spend(d(2026, 11, 13), last, id: 9),
    ];

    // Left 19,37,050: A13 with 41,950 on the 13th.
    final left = summaryWith(d(2026, 11, 13), on13(41950));
    expect(left.left, p(1937050));
    expect(formatRupees(left.left), '₹19,370');
    expect(summaryWith(d(2026, 11, 13), on13(41901)).left, p(1937099));
    expect(
      formatRupees(summaryWith(d(2026, 11, 13), on13(41901)).left),
      '₹19,370',
    );

    // Overspent 12,050 shows ₹120.
    final overspent = summaryWith(d(2026, 11, 6), [
      spend(d(2026, 11, 5), 95050, id: 1),
    ]);
    expect(overspent.overspent, p(12050));
    expect(formatRupees(overspent.overspent), '₹120');

    // Left −1,20,050 shows −₹1,200 (S8 with 20,050 spent).
    final shortfall = computeMonth(
      MonthInput(
        month: nov2026,
        firstBudgetedDay: d(2026, 11, 5),
        periods: [period(d(2026, 11, 5), s1Values(), continued: true)],
        today: d(2026, 11, 8),
        spends: [spend(d(2026, 11, 6), 20050, id: 1)],
      ),
    );
    expect(HomeSummary.from(shortfall).left, p(-120050));
    expect(formatRupees(HomeSummary.from(shortfall).left), '−⁠₹1,200');

    // Left −99 shows ₹0, no sign, and is not "over"; saved 99 shows ₹0.
    final tiny = summaryWith(d(2026, 11, 5), [
      spend(d(2026, 11, 5), 2490099, id: 1),
    ]);
    expect(tiny.left, p(-99));
    expect(formatRupees(tiny.left), '₹0');
    expect(tiny.isOver, isFalse);
    final savedTiny = summaryWith(d(2026, 11, 6), [
      spend(d(2026, 11, 5), 82901, id: 1),
    ]);
    expect(savedTiny.saved, p(99));
    expect(formatRupees(savedTiny.saved), '₹0');
    expect(savedTiny.savedHasMark, isFalse);
    expect(savedTiny.overspentHasMark, isFalse);
  });

  test('TC-010-52 progress permille is full or empty at the limits', () {
    expect(_of(a13).progressPermille, 222);
    // Spent at least the budgeted money: full.
    final all = _e2(
      d(2026, 11, 5),
      spends: [spend(d(2026, 11, 5), 2490000, id: 1)],
    );
    expect(HomeSummary.from(all).progressPermille, 1000);
    // Nothing budgeted (S8): full.
    expect(_of(s8).progressPermille, 1000);
    // Refund bigger than everything spent: empty.
    final refunded = _e2(
      d(2026, 11, 5),
      spends: [spend(d(2026, 11, 5), 30000, id: 1, moneyIn: true)],
    );
    expect(HomeSummary.from(refunded).spentSoFar, p(-30000));
    expect(HomeSummary.from(refunded).progressPermille, 0);
    // Nothing spent at all: empty.
    expect(HomeSummary.from(_e2(d(2026, 11, 5))).progressPermille, 0);
    // ₹10 crore of spend does not overflow: 10^10 x 1000 fits in an int.
    final huge = computeMonth(
      MonthInput(
        month: nov2026,
        firstBudgetedDay: d(2026, 11, 5),
        periods: [
          period(
            d(2026, 11, 5),
            const FullMonthValues(salary: Paise(10000000000)),
          ),
        ],
        today: d(2026, 11, 5),
        spends: [spend(d(2026, 11, 5), 5000000000, id: 1)],
      ),
    );
    expect(HomeSummary.from(huge).progressPermille, 500);
  });

  test('TC-010-25 today carries its money in', () {
    final result = _e2(
      d(2026, 11, 9),
      spends: [
        spend(d(2026, 11, 9), 70000, id: 1),
        spend(d(2026, 11, 9), 50000, id: 2, moneyIn: true),
      ],
    );
    final line = TodayLine.from(result);
    expect(line.netSpent, p(20000));
    expect(line.moneyIn, p(50000));
    expect(line.hasRefunds, isTrue);
    expect(line.result, p(63000));
    // A refund on another day is not today's.
    final past = TodayLine.from(
      _e2(
        d(2026, 11, 9),
        spends: [spend(d(2026, 11, 8), 50000, id: 1, moneyIn: true)],
      ),
    );
    expect(past.moneyIn, Paise.zero);
    expect(past.hasRefunds, isFalse);
  });

  test('TC-010-26 a refund beats today spends: negative net spend', () {
    final line = TodayLine.from(
      _e2(
        d(2026, 11, 9),
        spends: [
          spend(d(2026, 11, 9), 30000, id: 1),
          spend(d(2026, 11, 9), 50000, id: 2, moneyIn: true),
        ],
      ),
    );
    expect(line.netSpent, p(-20000));
    expect(line.result, p(103000));
    expect(line.kind, TodayResultKind.leftToday);
  });

  test('TC-010-51 refund larger than all spends gives negative spent so '
      'far', () {
    final summary = HomeSummary.from(
      _e2(
        d(2026, 11, 5),
        spends: [spend(d(2026, 11, 5), 30000, id: 1, moneyIn: true)],
      ),
    );
    expect(summary.spentSoFar, p(-30000));
    expect(summary.left, p(2520000));
    expect(summary.progressPermille, 0);
  });
}
