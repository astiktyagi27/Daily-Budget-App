import 'dart:math';

import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  test(
    'TC-006-02 every salary day gives valid consecutive months 2026 to 2030',
    () {
      for (var salaryDay = 1; salaryDay <= 31; salaryDay++) {
        var month = BudgetMonth.startIn(salaryDay, 2026, 1);
        final first = month.start;
        var totalDays = 0;
        for (var k = 0; k < 60; k++) {
          final reason = 'salary day $salaryDay, month ${month.start.iso}';
          expect(month.length, inInclusiveRange(28, 31), reason: reason);
          final lastDay = CalendarDate.daysInMonth(
            month.start.year,
            month.start.month,
          );
          expect(
            month.start.day,
            salaryDay < lastDay ? salaryDay : lastDay,
            reason: reason,
          );
          final next = month.next;
          expect(next.start, month.end.addDays(1), reason: reason);
          totalDays += month.length;
          month = next;
        }
        // 1 Jan 2026 start to the day before the Jan 2031 start: 5 years.
        expect(totalDays, 1826, reason: 'salary day $salaryDay');
        expect(first.daysUntil(month.start), 1826);
      }

      // Leap year: 29, 30 and 31 all start on 29 Feb 2028.
      for (final salaryDay in [29, 30, 31]) {
        expect(BudgetMonth.startIn(salaryDay, 2028, 2).start, d(2028, 2, 29));
      }
      // Day 29 does not stick to the 28th after Feb 2027.
      expect(BudgetMonth.startIn(29, 2027, 2).next.start, d(2027, 3, 29));

      // TC-006-58: US daylight-saving weeks (Nov 2026, Mar 2027) are plain
      // days; run under TZ=PST8PDT by tool/tz_matrix.ps1 (TC-006-27).
      expect(BudgetMonth.startIn(5, 2026, 10).length, 31);
      expect(BudgetMonth.startIn(5, 2027, 3).length, 31);
      expect(d(2026, 11, 1).daysUntil(d(2026, 11, 2)), 1);
      expect(d(2027, 3, 14).daysUntil(d(2027, 3, 15)), 1);
    },
  );

  test('TC-006-03 every date belongs to exactly one budget month', () {
    final firstDate = d(2026, 1, 1);
    final lastDate = d(2030, 12, 31);
    expect(firstDate.daysUntil(lastDate) + 1, 1826);
    for (var salaryDay = 1; salaryDay <= 31; salaryDay++) {
      for (
        var date = firstDate;
        !date.isAfter(lastDate);
        date = date.addDays(1)
      ) {
        final month = BudgetMonth.containing(salaryDay, date);
        if (month.start.isAfter(date) || month.end.isBefore(date)) {
          fail(
            'salary day $salaryDay: ${date.iso} not in '
            '${month.start.iso} to ${month.end.iso}',
          );
        }
        final after = BudgetMonth.containing(salaryDay, month.end.addDays(1));
        if (after.start != month.end.addDays(1)) {
          fail('salary day $salaryDay: gap after ${month.end.iso}');
        }
      }
    }

    // 29 Feb 2028 belongs to these months.
    final leapDay = d(2028, 2, 29);
    final expected = <int, (CalendarDate, CalendarDate)>{
      1: (d(2028, 2, 1), d(2028, 2, 29)),
      15: (d(2028, 2, 15), d(2028, 3, 14)),
      29: (d(2028, 2, 29), d(2028, 3, 28)),
      30: (d(2028, 2, 29), d(2028, 3, 29)),
      31: (d(2028, 2, 29), d(2028, 3, 30)),
    };
    for (final MapEntry(key: salaryDay, value: (start, end))
        in expected.entries) {
      final month = BudgetMonth.containing(salaryDay, leapDay);
      expect((month.start, month.end), (start, end), reason: '$salaryDay');
    }

    // Month state (F-008 §2.11) finds the month that contains today.
    final nov = BudgetMonth.startIn(5, 2026, 11);
    final none = monthStateFor(
      salaryDay: 5,
      lastMonth: null,
      today: d(2026, 11, 9),
    );
    expect(none, isA<NoMonthYet>());
    expect(none.month.start, d(2026, 11, 5));
    for (final today in [d(2026, 11, 5), d(2026, 12, 4), d(2026, 11, 1)]) {
      final state = monthStateFor(salaryDay: 5, lastMonth: nov, today: today);
      expect(state, isA<CurrentMonth>(), reason: today.iso);
      expect(state.month, same(nov));
    }
    final missed = <CalendarDate, (CalendarDate, int)>{
      d(2026, 12, 5): (d(2026, 12, 5), 0),
      d(2027, 1, 4): (d(2026, 12, 5), 0),
      d(2027, 1, 5): (d(2027, 1, 5), 1),
      d(2027, 2, 10): (d(2027, 2, 5), 2),
    };
    for (final MapEntry(key: today, value: (start, count)) in missed.entries) {
      final state = monthStateFor(salaryDay: 5, lastMonth: nov, today: today);
      expect(
        state,
        isA<NewMonthStarted>()
            .having((s) => s.month.start, 'start', start)
            .having((s) => s.missedMonths, 'missed', count),
        reason: today.iso,
      );
    }
  });

  test(
    'TC-006-06 spreading always sums exactly and puts extra paise first',
    () {
      const tenCrore = 10000000000;
      final random = Random(propertySeed);
      var cases = 0;
      void check(int amount, int days) {
        cases++;
        final why = 'seed $propertySeed: $amount paise over $days days';
        final budgets = Paise(amount).spreadOver(days);
        expectFairSpread(budgets, amount, days, why);
        var low = budgets.first.value;
        var high = low;
        for (final budget in budgets) {
          if (budget.isNegative) fail('$why: negative day');
          low = budget.value < low ? budget.value : low;
          high = budget.value > high ? budget.value : high;
        }
        if (high - low > 1) fail('$why: days differ by more than 1 paisa');
      }

      // Fixed boundary rows for every range length.
      for (var days = 1; days <= 31; days++) {
        for (final amount in [
          0,
          1,
          days - 1,
          days,
          days + 1,
          2 * days - 1,
          tenCrore,
        ]) {
          check(amount, days);
        }
      }
      // 5,000 uniform amounts up to ten crore, 5,000 log-uniform (small ones
      // appear often).
      for (var i = 0; i < 5000; i++) {
        check(uniformUpTo(random, tenCrore), random.nextInt(31) + 1);
        final digits = random.nextInt(11);
        var limit = 1;
        for (var k = 0; k < digits; k++) {
          limit *= 10;
        }
        check(uniformUpTo(random, limit), random.nextInt(31) + 1);
      }
      expect(cases, greaterThanOrEqualTo(10000));
    },
  );

  test('TC-006-07 every generated month sums exactly to its spendable', () {
    const tenCrore = 10000000000;
    final random = Random(propertySeed);
    for (var i = 0; i < 2000; i++) {
      final month = BudgetMonth.startIn(
        random.nextInt(31) + 1,
        2026 + random.nextInt(5),
        random.nextInt(12) + 1,
      );
      final salary = uniformUpTo(random, tenCrore - 1) + 1;
      final target = random.nextBool()
          ? null
          : uniformUpTo(random, salary - 1) + 1;
      final count = random.nextInt(31);
      // Half the cases keep the costs under the salary, so both outcomes
      // appear often.
      final costLimit = random.nextBool() ? tenCrore : salary ~/ (count + 1);
      final costs = [
        for (var k = 0; k < count; k++) uniformUpTo(random, costLimit),
      ];
      final values = FullMonthValues(
        salary: p(salary),
        target: target == null ? null : p(target),
        fixedCosts: [
          for (final (k, cost) in costs.indexed)
            FixedCost(name: 'Cost $k', amount: p(cost)),
        ],
      );
      final spendable =
          (target ?? salary) - costs.fold<int>(0, (a, b) => a + b);
      final why =
          'seed $propertySeed, case $i: ${month.start.iso}, '
          'target ${target ?? salary}, costs $costs';
      final result = computeMonth(
        MonthInput(
          month: month,
          firstBudgetedDay: month.start,
          periods: [period(month.start, values, continued: true)],
          today: month.start,
        ),
      );
      final budgets = allBudgets(result);
      expect(budgets, hasLength(month.length), reason: why);
      if (budgets.any((budget) => budget.isNegative)) fail('$why: negative');
      if (spendable >= 0) {
        expect(Paise.sum(budgets), p(spendable), reason: why);
        expect(result.totals.shortfall, Paise.zero, reason: why);
      } else {
        expect(result.totals.shortfall, p(-spendable), reason: why);
        expect(Paise.sum(budgets), Paise.zero, reason: why);
      }
    }
  });

  test(
    'TC-006-23 any change keeps past days and sums to the new spendable',
    () {
      const tenCrore = 10000000000;
      final random = Random(propertySeed);
      for (var i = 0; i < 2000; i++) {
        final month = BudgetMonth.startIn(
          random.nextInt(31) + 1,
          2026 + random.nextInt(5),
          random.nextInt(12) + 1,
        );
        final salary = uniformUpTo(random, tenCrore - 1) + 1;
        final rent = uniformUpTo(random, salary);
        final original = FullMonthValues(
          salary: p(salary),
          fixedCosts: [FixedCost(name: 'Rent', amount: p(rent))],
        );
        final changeDay = month.start.addDays(random.nextInt(month.length));
        final before = computeMonth(
          MonthInput(
            month: month,
            firstBudgetedDay: month.start,
            periods: [period(month.start, original, continued: true)],
            today: changeDay,
          ),
        );
        final pastDays = month.start.daysUntil(changeDay);
        final past = allBudgets(before).take(pastDays).toList();
        final pastSum = Paise.sum(past).value;
        // New values that leave ₹0 or more to spread.
        final newRent = uniformUpTo(random, tenCrore);
        final newSalary = pastSum + newRent + uniformUpTo(random, tenCrore);
        final changed = FullMonthValues(
          salary: p(newSalary),
          fixedCosts: [FixedCost(name: 'Rent', amount: p(newRent))],
        );
        final after = computeMonth(
          MonthInput(
            month: month,
            firstBudgetedDay: month.start,
            periods: [
              period(month.start, original, continued: true),
              period(changeDay, changed, continued: true),
            ],
            today: changeDay,
          ),
        );
        final why =
            'seed $propertySeed, case $i: ${month.start.iso}, '
            'change ${changeDay.iso}';
        final budgets = allBudgets(after);
        expect(budgets.take(pastDays).toList(), past, reason: why);
        expectFairSpread(
          budgets.skip(pastDays).toList(),
          newSalary - newRent - pastSum,
          month.length - pastDays,
          why,
        );
        expect(Paise.sum(budgets), changed.spendable, reason: why);
      }
    },
  );

  test(
    'TC-006-47 pot never goes negative under random spends covers and edits',
    () {
      final random = Random(propertySeed);
      final spendable = e2Values().spendable;
      var steps = 0;
      for (var sequence = 0; sequence < 1000; sequence++) {
        final today = nov2026.start.addDays(random.nextInt(nov2026.length));
        final daysSoFar = nov2026.start.daysUntil(today) + 1;
        CalendarDate randomDay() =>
            nov2026.start.addDays(random.nextInt(daysSoFar));
        var nextId = 0;
        final spends = [
          for (var k = random.nextInt(60) + 1; k > 0; k--)
            spend(randomDay(), random.nextInt(300000) + 1, id: nextId++),
        ];
        var covers = <Cover>[];
        final why = 'seed $propertySeed, sequence $sequence';

        MonthResult step() {
          steps++;
          final result = e2Month(today: today, spends: spends, covers: covers);
          _expectPotRules(result, spendable, '$why, step $steps');
          // The repository stores reductions and clamps (D-048).
          covers = [
            for (final (k, effective) in result.effectiveCovers.indexed)
              cover(
                effective.coverId,
                effective.day,
                effective.amount.value,
                covers[k].madeAt,
              ),
          ];
          return result;
        }

        var result = step();
        for (var k = random.nextInt(8); k > 0; k--) {
          final day = randomDay();
          final amount = random.nextInt(60000) + 1;
          if (checkCover(result, day, p(amount)) is CoverAllowed) {
            // Ids rise with the time a cover is made.
            covers = [...covers, cover(nextId, day, amount, nextId++)];
            result = step();
          }
        }
        for (var k = random.nextInt(6); k > 0 && spends.isNotEmpty; k--) {
          final index = random.nextInt(spends.length);
          if (random.nextBool()) {
            spends.removeAt(index);
          } else {
            final old = spends[index];
            spends[index] = spend(
              old.date,
              random.nextInt(300000) + 1,
              id: old.id,
            );
          }
          result = step();
        }
      }
      expect(steps, greaterThanOrEqualTo(1000));
    },
  );
}

void _expectPotRules(MonthResult result, Paise spendable, String why) {
  final totals = result.totals;
  if (totals.pot.isNegative) fail('$why: pot ${totals.pot.value}');
  if (totals.covered > totals.saved) fail('$why: covers above saved');
  if (Paise.sum(allBudgets(result)) != spendable) fail('$why: budgets');
  for (final day in result.days) {
    final overspend = (day.netSpent - day.budget!).orZero;
    if (day.covered > overspend) fail('$why: ${day.date.iso} over-covered');
  }
  // Ids rise with cover time here, so newest first means falling ids.
  final ids = [for (final r in result.reductions) r.coverId];
  for (var k = 1; k < ids.length; k++) {
    if (ids[k] > ids[k - 1]) fail('$why: reductions not newest first');
  }
}
