import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/phase3_fixtures.dart';
import 'fixtures.dart';

// F-011 plan §1.1: the month grid, from the engine's result.

/// A month of E2 values from its first day, computed for [today].
MonthResult _monthResult(
  BudgetMonth month,
  CalendarDate today, {
  List<Spend> spends = const [],
}) => computeMonth(
  MonthInput(
    month: month,
    firstBudgetedDay: month.start,
    periods: [period(month.start, e2Values(salary: 40000000))],
    today: today,
    spends: spends,
  ),
);

CalendarGrid _grid(BudgetMonth month, CalendarDate today) =>
    CalendarGrid.of(_monthResult(month, today));

int _outsideBefore(CalendarGrid g) =>
    g.cells.takeWhile((c) => c.kind == CellKind.outside).length;

int _budgetCells(CalendarGrid g) =>
    g.cells.where((c) => c.kind != CellKind.outside).length;

CalendarCell _cell(Phase3Fixture f, CalendarDate date) =>
    CalendarGrid.of(f.result).cells.singleWhere((c) => c.date == date);

void main() {
  test('TC-011-02 salary day 5: Mon 2 Nov to Sun 6 Dec, 35 cells', () {
    final grid = CalendarGrid.of(fixtureA.result);
    expect(grid.weeks, hasLength(5));
    expect(grid.cells, hasLength(35));
    expect(grid.cells.first.date, d(2026, 11, 2));
    expect(grid.cells.last.date, d(2026, 12, 6));
    expect(grid.cells.first.date.weekdayIndex, 0);
    expect(grid.cells.last.date.weekdayIndex, 6);
    final outside = [
      for (final c in grid.cells)
        if (c.kind == CellKind.outside) c.date.iso,
    ];
    expect(outside, [
      '2026-11-02',
      '2026-11-03',
      '2026-11-04',
      '2026-12-05',
      '2026-12-06',
    ]);
    expect(_budgetCells(grid), 30);
    final dec1 = grid.cells.singleWhere((c) => c.date == d(2026, 12, 1));
    expect(dec1.isMonthFirstDay, isTrue);
    expect(grid.cells.where((c) => c.isMonthFirstDay).map((c) => c.date.iso), [
      '2026-12-01',
    ]);
    // Outside cells are never tappable; budget cells are.
    expect(grid.cells.first.isTappable, isFalse);
    expect(
      grid.cells.singleWhere((c) => c.date == d(2026, 11, 5)).isTappable,
      isTrue,
    );
  });

  test('TC-011-02 the F-006 months, also TC-011-03, TC-011-04, TC-011-05, '
      'TC-011-06, TC-011-07 and TC-011-40: Feb 2027, 31 Jan, the leap days, '
      'the year crossing', () {
    // Salary day 1, 1 - 28 Feb 2027: exactly 4 rows.
    final feb = _grid(BudgetMonth.startIn(1, 2027, 2), d(2027, 2, 10));
    expect(feb.weeks, hasLength(4));
    expect(_budgetCells(feb), 28);
    expect(_outsideBefore(feb), 0);

    // Salary day 31, 31 Jan - 27 Feb 2027: starts on a Sunday, 6 outside.
    final jan31Month = BudgetMonth.startIn(31, 2027, 1);
    expect(jan31Month.start, d(2027, 1, 31));
    expect(jan31Month.end, d(2027, 2, 27));
    final jan31 = _grid(jan31Month, d(2027, 2, 5));
    expect(_outsideBefore(jan31), 6);
    expect(_budgetCells(jan31), 28);
    expect(jan31.weeks, hasLength(5));

    // Salary day 30 in 2028: 30 Jan - 28 Feb has 30 days and no 29 Feb; the
    // leap day is the first cell of the next month (D-075).
    final jan30 = BudgetMonth.startIn(30, 2028, 1);
    expect(jan30.end, d(2028, 2, 28));
    final jan30Grid = _grid(jan30, d(2028, 2, 10));
    expect(_budgetCells(jan30Grid), 30);
    expect(
      jan30Grid.cells.any(
        (c) => c.date == d(2028, 2, 29) && c.kind != CellKind.outside,
      ),
      isFalse,
    );
    final leap = BudgetMonth.startIn(30, 2028, 2);
    expect(leap.start, d(2028, 2, 29));
    expect(leap.end, d(2028, 3, 29));
    final leapGrid = _grid(leap, d(2028, 3, 1));
    expect(_budgetCells(leapGrid), 30);
    final first = leapGrid.cells.firstWhere((c) => c.kind != CellKind.outside);
    expect(first.date, d(2028, 2, 29));
    expect(first.isMonthFirstDay, isFalse);

    // Salary day 29, 31-day month in a leap year: 29 Jan - 28 Feb 2028.
    final jan29 = _grid(BudgetMonth.startIn(29, 2028, 1), d(2028, 2, 10));
    expect(_budgetCells(jan29), 31);

    // A month crossing the year: 25 Dec - 24 Jan, `1 Jan` is a month first.
    final crossing = _grid(BudgetMonth.startIn(25, 2026, 12), d(2027, 1, 2));
    expect(
      crossing.cells.singleWhere((c) => c.isMonthFirstDay).date,
      d(2027, 1, 1),
    );
  });

  test('TC-011-39 grid layout for every salary day and month 2026 to 2030', () {
    for (var salaryDay = 1; salaryDay <= 31; salaryDay++) {
      var month = BudgetMonth.startIn(salaryDay, 2026, 1);
      for (var k = 0; k < 60; k++) {
        final grid = _grid(month, month.start);
        final reason = 'salary day $salaryDay, ${month.start.iso}';
        expect(grid.cells.length % 7, 0, reason: reason);
        expect(grid.weeks.length, inInclusiveRange(4, 6), reason: reason);
        expect(grid.cells.first.date.weekdayIndex, 0, reason: reason);
        expect(grid.cells.last.date.weekdayIndex, 6, reason: reason);
        expect(_budgetCells(grid), month.length, reason: reason);
        // Consecutive days, no gaps.
        var expected = grid.cells.first.date;
        for (final cell in grid.cells) {
          expect(cell.date, expected, reason: reason);
          expected = expected.addDays(1);
        }
        // At most 6 outside cells at each end.
        expect(_outsideBefore(grid), lessThan(7), reason: reason);
        month = month.next;
      }
    }
  });

  test('TC-011-41 a month starting on the 1st shows a plain 1', () {
    final grid = CalendarGrid.of(m20.result);
    expect(grid.weeks, hasLength(6));
    expect(grid.cells.first.date, d(2026, 10, 26));
    expect(grid.cells.last.date, d(2026, 12, 6));
    final nov1 = grid.cells.singleWhere((c) => c.date == d(2026, 11, 1));
    expect(nov1.isMonthFirstDay, isFalse);
    expect(
      grid.cells.singleWhere((c) => c.date == d(2026, 12, 1)).kind,
      CellKind.outside,
    );
    expect(
      grid.cells.singleWhere((c) => c.date == d(2026, 12, 1)).isMonthFirstDay,
      isFalse,
      reason: 'an outside cell never shows a month name',
    );
  });

  test('TC-011-10 cells for every engine status (example A)', () {
    final saved = _cell(fixtureA, d(2026, 11, 5));
    expect(saved.kind, CellKind.saved);
    expect(saved.netSpent, p(50000));
    expect(saved.result, p(33000));
    expect(saved.resultKind, DayResultKind.saved);
    expect(saved.todayFill, isNull);
    expect(saved.isTappable, isTrue);

    expect(_cell(fixtureA, d(2026, 11, 6)).kind, CellKind.overspent);
    expect(_cell(fixtureA, d(2026, 11, 6)).result, p(-17000));
    final onBudget = _cell(fixtureA, d(2026, 11, 10));
    expect(onBudget.kind, CellKind.onBudget);
    expect(onBudget.resultKind, DayResultKind.onBudget);
    expect(_cell(fixtureA, d(2026, 11, 12)).netSpent, Paise.zero);
    expect(_cell(fixtureA, d(2026, 11, 12)).kind, CellKind.saved);

    // Live: saved so far, with and without spends; overspent so far.
    final today = _cell(fixtureA, d(2026, 11, 13));
    expect(today.kind, CellKind.today);
    expect(today.netSpent, p(42000));
    expect(today.result, p(41000));
    expect(today.todayFill, TodayFill.saved);
    expect(_cell(a13o, d(2026, 11, 13)).todayFill, TodayFill.overspent);
    final empty = fixtureA.mapEntries(
      'A-',
      (e) => e.date == d(2026, 11, 13) ? e.copyWith(paise: 1) : e,
    );
    expect(_cell(empty, d(2026, 11, 13)).todayFill, TodayFill.saved);
    final none = fixtureA.copyWith(
      name: 'A14none',
      entries: [
        for (final e in fixtureA.current.entries)
          if (e.date != d(2026, 11, 13)) e,
      ],
    );
    expect(_cell(none, d(2026, 11, 13)).todayFill, TodayFill.nothingSpent);
    // Overspent by less than ₹1 today still fills as overspent.
    final tiny = fixtureA.mapEntries(
      'A-tiny',
      (e) => e.date == d(2026, 11, 13) ? e.copyWith(paise: 83040) : e,
    );
    expect(_cell(tiny, d(2026, 11, 13)).todayFill, TodayFill.overspent);
    expect(
      _cell(tiny, d(2026, 11, 13)).resultKind,
      DayResultKind.overspentUnderRupee,
    );
    // Exactly on budget today.
    final exact = fixtureA.mapEntries(
      'A-exact',
      (e) => e.date == d(2026, 11, 13) ? e.copyWith(paise: 83000) : e,
    );
    expect(_cell(exact, d(2026, 11, 13)).todayFill, TodayFill.onBudget);
    expect(_cell(exact, d(2026, 11, 13)).resultKind, DayResultKind.onBudget);

    // Upcoming: no money, no result.
    final upcoming = _cell(fixtureA, d(2026, 11, 14));
    expect(upcoming.kind, CellKind.upcoming);
    expect(upcoming.netSpent, isNull);
    expect(upcoming.result, isNull);
    expect(upcoming.resultKind, isNull);
    expect(upcoming.isTappable, isTrue);

    // Not budgeted (example F).
    final notBudgeted = _cell(f12, d(2026, 11, 7));
    expect(notBudgeted.kind, CellKind.notBudgeted);
    expect(notBudgeted.netSpent, isNull);
    expect(notBudgeted.isTappable, isFalse);
    expect(CalendarGrid.of(f12.result).hasNotBudgeted, isTrue);
    expect(CalendarGrid.of(fixtureA.result).hasNotBudgeted, isFalse);
  });

  test('TC-011-14 covered days: fully on budget, partly still overspent', () {
    final full = _cell(a13c300, d(2026, 11, 11));
    expect(full.kind, CellKind.onBudget);
    expect(full.netSpent, p(113000), reason: 'covers are not spends');
    expect(full.covered, p(30000));
    final partly = fixtureA.plus(
      name: 'A+100',
      covers: [
        FixtureCover(
          day: d(2026, 11, 11),
          paise: 10000,
          madeAt: at(d(2026, 11, 13), 9),
        ),
      ],
    );
    final cell = _cell(partly, d(2026, 11, 11));
    expect(cell.kind, CellKind.overspent);
    expect(cell.result, p(-20000));
    expect(cell.covered, p(10000));
  });

  test('TC-011-16 shortfall month: ₹0 days are on budget', () {
    expect(_cell(s8, d(2026, 11, 5)).kind, CellKind.onBudget);
    expect(_cell(s8, d(2026, 11, 7)).kind, CellKind.onBudget);
    expect(_cell(s8, d(2026, 11, 6)).kind, CellKind.overspent);
    expect(_cell(s8, d(2026, 11, 8)).kind, CellKind.today);
    expect(_cell(s8, d(2026, 11, 8)).todayFill, TodayFill.nothingSpent);
  });

  test('TC-011-18 the change tick is on 13 Nov only', () {
    final grid = CalendarGrid.of(m20.result);
    expect(
      [
        for (final c in grid.cells)
          if (c.isChangeDay) c.date.iso,
      ],
      ['2026-11-13'],
    );
    expect(grid.hasChangeDay, isTrue);
    expect(CalendarGrid.of(fixtureA.result).hasChangeDay, isFalse);
  });

  test('TC-011-17 each day is judged against its own budget', () {
    expect(_cell(m20, d(2026, 11, 12)).result, p(83000 - 83000));
    final nov18 = m20.mapEntries(
      'M20-18',
      (e) => e.date == d(2026, 11, 18) ? e.copyWith(paise: 60000) : e,
    );
    final cell = _cell(nov18, d(2026, 11, 18));
    expect(cell.kind, CellKind.overspent);
    expect(cell.result, p(-4778));
    expect(cell.resultKind, DayResultKind.overspent);
  });

  test('TC-011-19 a same day replaced change gives no second tick', () {
    final nov13 = d(2026, 11, 13);
    final base = m20.current;
    final replaced = m20.copyWith(
      name: 'M20-twice',
      periods: [
        ...base.periods,
        period(nov13, e2Values(salary: 3600000), changedAt: at(nov13, 15)),
      ],
    );
    final grid = CalendarGrid.of(replaced.result);
    expect(
      [
        for (final c in grid.cells)
          if (c.isChangeDay) c.date.iso,
      ],
      ['2026-11-13'],
    );
  });

  test('TC-011-19 a change made on the first day draws no tick on day 1', () {
    final day1 = d(2026, 11, 1);
    final day13 = d(2026, 11, 13);
    MonthResult month(List<BudgetPeriod> periods) => computeMonth(
      MonthInput(
        month: BudgetMonth.startIn(1, 2026, 11),
        firstBudgetedDay: day1,
        periods: periods,
        today: d(2026, 11, 20),
      ),
    );
    List<String> ticks(MonthResult result) => [
      for (final c in CalendarGrid.of(result).cells)
        if (c.isChangeDay) c.date.iso,
    ];
    // The month's first period is replaced the same day: it is superseded and
    // the kept one is still the month's start, not a change.
    final replaced = month([
      period(day1, e2Values(), changedAt: at(day1, 9)),
      period(day1, e2Values(salary: 3500000), changedAt: at(day1, 15)),
    ]);
    expect(replaced.periods.first.superseded, isTrue);
    expect(ticks(replaced), isEmpty);
    expect(CalendarGrid.of(replaced).hasChangeDay, isFalse);
    // A real change later in the month still draws its one tick.
    final later = month([
      period(day1, e2Values(), changedAt: at(day1, 9)),
      period(day1, e2Values(salary: 3500000), changedAt: at(day1, 15)),
      period(day13, e2Values(salary: 3600000), changedAt: at(day13, 9)),
    ]);
    expect(ticks(later), ['2026-11-13']);
  });

  test('TC-011-38 the under one rupee boundary is 99 and 100 paise', () {
    // (result in paise, kind): under 100 paise is under ₹1 on both sides.
    const cases = <(int, DayResultKind)>[
      (0, DayResultKind.onBudget),
      (1, DayResultKind.savedUnderRupee),
      (99, DayResultKind.savedUnderRupee),
      (100, DayResultKind.saved),
      (101, DayResultKind.saved),
      (-1, DayResultKind.overspentUnderRupee),
      (-99, DayResultKind.overspentUnderRupee),
      (-100, DayResultKind.overspent),
      (-101, DayResultKind.overspent),
    ];
    for (final (paise, kind) in cases) {
      expect(dayResultKind(Paise(paise)), kind, reason: '$paise paise');
    }
    // The same on the grid: A's day is ₹830, so spends of ₹830 minus or plus
    // the paise give those results.
    for (final (paise, kind) in cases.where((c) => c.$1 != 0)) {
      final f = fixtureA.plus(
        name: 'A$paise',
        entries: [fixtureSpend(d(2026, 11, 12), 83000 - paise)],
      );
      final cell = _cell(f, d(2026, 11, 12));
      expect(cell.result, p(paise), reason: '$paise paise');
      expect(cell.resultKind, kind, reason: '$paise paise');
    }
  });

  test('TC-011-22 refund days: net spent can be negative', () {
    final a = fixtureA.plus(
      name: 'A-refund-big',
      entries: [
        fixtureSpend(d(2026, 11, 12), 20000),
        fixtureMoneyIn(d(2026, 11, 12), 150000),
      ],
    );
    final cell = _cell(a, d(2026, 11, 12));
    expect(cell.netSpent, p(-130000));
    expect(cell.result, p(213000));
    expect(cell.kind, CellKind.saved);
    expect(cell.hasRefunds, isTrue);
    expect(_cell(a, d(2026, 11, 11)).hasRefunds, isFalse);
  });

  test('TC-011-44 a spend dated in the future is not on upcoming cells', () {
    final a = fixtureA.plus(
      name: 'A+future',
      entries: [fixtureSpend(d(2026, 11, 15), 50000)],
    );
    final cell = _cell(a, d(2026, 11, 15));
    expect(cell.kind, CellKind.upcoming);
    expect(cell.netSpent, isNull);
  });

  test('TC-011-46 on day one the ring is the only cell with money', () {
    final result = computeMonth(
      MonthInput(
        month: nov2026,
        firstBudgetedDay: d(2026, 11, 5),
        periods: [period(d(2026, 11, 5), e2Values())],
        today: d(2026, 11, 5),
      ),
    );
    final cells = CalendarGrid.of(result).cells.toList();
    expect(cells.where((c) => c.kind == CellKind.today), hasLength(1));
    expect(cells.where((c) => c.kind == CellKind.upcoming), hasLength(29));
  });

  test('TC-011-55 a past month: every day is final', () {
    final october = octNov.months.first.result(d(2026, 11, 13));
    final kinds = {for (final c in CalendarGrid.of(october).cells) c.kind};
    expect(kinds, isNot(contains(CellKind.today)));
    expect(kinds, isNot(contains(CellKind.upcoming)));
    expect(kinds, isNot(contains(CellKind.notBudgeted)));
  });

  test('TC-011-10 today before the first budgeted day has no ring', () {
    final early = f12.copyWith(name: 'F-early', today: d(2026, 11, 7));
    final kinds = {for (final c in CalendarGrid.of(early.result).cells) c.kind};
    expect(kinds, isNot(contains(CellKind.today)));
    expect(kinds, contains(CellKind.notBudgeted));
    expect(kinds, contains(CellKind.upcoming));
  });
}
