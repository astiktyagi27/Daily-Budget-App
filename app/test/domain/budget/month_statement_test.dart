// F-014 T-400: the statement model, pure. Every expected number is a literal
// of tests/F-014 (section 0 and the cases), never computed here.

import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/phase3_fixtures.dart';
import 'fixtures.dart';

MonthStatement _of(Phase3Fixture fixture) => buildStatement(fixture.result);

/// The statement of a salary-day-1 November (1 - 30 Nov 2026) with [periods].
MonthStatement _november(
  List<BudgetPeriod> periods, {
  required CalendarDate today,
  List<Spend> spends = const [],
}) => buildStatement(
  computeMonth(
    MonthInput(
      month: BudgetMonth.startIn(1, 2026, 11),
      firstBudgetedDay: d(2026, 11, 1),
      periods: periods,
      today: today,
      spends: spends,
    ),
  ),
);

/// The statement of the E2 month (5 Nov - 4 Dec) with [periods].
MonthStatement _e2(List<BudgetPeriod> periods, {CalendarDate? today}) =>
    buildStatement(e2Month(today: today ?? d(2026, 12, 5), periods: periods));

BudgetPeriod _e2First() =>
    period(d(2026, 11, 5), e2Values(), changedAt: at(d(2026, 11, 4), 0));

SpreadWorking _spread(StatementPeriod p) => p.working as SpreadWorking;

void main() {
  test('TC-014-03 view model for example m', () {
    final s = _of(fixtureMFull);

    expect(s.soFarTo, isNull);
    expect(s.notBudgeted, isNull);
    expect(s.periods, hasLength(2));
    final [p1, p2] = s.periods;

    expect(
      (p1.index, p1.of, p1.start, p1.end, p1.days),
      (1, 2, d(2026, 11, 1), d(2026, 11, 12), 12),
    );
    expect(p1.inProgress, isFalse);
    expect(p1.reasons.single, isA<StartedReason>());
    expect((p1.reasons.single as StartedReason).partway, isFalse);
    expect(p1.values, isA<FullMonthValues>());
    expect((p1.values as FullMonthValues).salary, p(4000000));
    expect(p1.values.fixedCostsTotal, p(1510000));
    final w1 = _spread(p1);
    expect(
      (
        w1.base,
        w1.fixed,
        w1.stillToPay,
        w1.spendable,
        w1.alreadyBudgeted,
        w1.amountToSpread,
        w1.spreadDays,
        w1.daily,
        w1.extraPaiseDays,
      ),
      (
        p(4000000),
        p(1510000),
        false,
        p(2490000),
        p(0),
        p(2490000),
        30,
        p(83000),
        0,
      ),
    );
    expect(
      (
        p1.totals.budget,
        p1.totals.spent,
        p1.totals.refunds,
        p1.totals.netSpent,
        p1.totals.saved,
        p1.totals.overspent,
        p1.totals.covered,
        p1.totals.hasRefunds,
      ),
      (
        p(996000),
        p(900000),
        p(0),
        p(900000),
        p(140000),
        p(24000),
        p(20000),
        false,
      ),
    );

    expect(
      (p2.index, p2.of, p2.start, p2.end, p2.days),
      (2, 2, d(2026, 11, 13), d(2026, 11, 30), 18),
    );
    final reason = p2.reasons.single as ChangedReason;
    final delta = reason.delta as ValueDelta;
    expect(
      (delta.field, delta.name, delta.before, delta.after),
      (PeriodField.salary, null, p(4000000), p(3500000)),
    );
    final w2 = _spread(p2);
    expect(
      (
        w2.base,
        w2.spendable,
        w2.alreadyBudgeted,
        w2.amountToSpread,
        w2.spreadDays,
        w2.daily,
        w2.extraPaiseDays,
      ),
      (p(3500000), p(1990000), p(996000), p(994000), 18, p(55223), 4),
    );
    expect(
      (
        p2.totals.budget,
        p2.totals.spent,
        p2.totals.refunds,
        p2.totals.netSpent,
        p2.totals.saved,
        p2.totals.overspent,
        p2.totals.covered,
        p2.totals.hasRefunds,
      ),
      (
        p(994000),
        p(1000000),
        p(50000),
        p(950000),
        p(74078),
        p(30078),
        p(0),
        true,
      ),
    );

    final t = s.totals;
    expect(
      (
        t.moneyForMonth,
        t.spent,
        t.refunds,
        t.netSpent,
        t.saved,
        t.covered,
        t.overspent,
        t.pot,
        t.shortfall,
        t.left,
        t.hasRefunds,
      ),
      (
        p(1990000),
        p(1900000),
        p(50000),
        p(1850000),
        p(214078),
        p(20000),
        p(54078),
        p(194078),
        p(0),
        p(140000),
        true,
      ),
    );
  });

  test('TC-014-05 example m totals add up to the paisa', () {
    final s = _of(fixtureMFull);
    final [p1, p2] = s.periods;
    Paise sum(Paise Function(StatementPeriodTotals) of) =>
        of(p1.totals) + of(p2.totals);
    final t = s.totals;
    expect(sum((x) => x.budget), t.moneyForMonth);
    expect(sum((x) => x.netSpent), t.netSpent);
    expect(sum((x) => x.saved), t.saved);
    expect(sum((x) => x.overspent), t.overspent);
    expect(sum((x) => x.covered), t.covered);
    expect(sum((x) => x.budget), p(1990000));
    expect(sum((x) => x.netSpent), p(1850000));
    expect(sum((x) => x.saved), p(214078));
    expect(sum((x) => x.overspent), p(54078));

    // The check line, in paise, per period and for the month.
    for (final totals in [p1.totals, p2.totals]) {
      expect(
        totals.budget - totals.netSpent,
        totals.saved - totals.overspent - totals.covered,
      );
    }
    expect(p1.totals.budget - p1.totals.netSpent, p(96000));
    expect(p2.totals.budget - p2.totals.netSpent, p(44000));
    expect(t.moneyForMonth - t.netSpent, p(140000));
    expect(t.moneyForMonth - t.netSpent, t.saved - t.overspent - t.covered);
    expect(t.pot, t.saved - t.covered);
    expect(t.left, p(140000));
  });

  test('TC-014-08 current period counts saved on ended days and overspent '
      'up to today', () {
    final s = _of(fixtureM20);

    expect(s.soFarTo, d(2026, 11, 20));
    final [p1, p2] = s.periods;
    expect(p1.inProgress, isFalse);
    expect(p2.inProgress, isTrue);
    expect(p2.totals.saved, p(71558));
    expect(p2.totals.overspent, p(29778));
    expect(p2.totals.netSpent, p(400000));
    expect(p2.totals.spent, p(400000));
    expect(p2.totals.budget, p(994000));
    final t = s.totals;
    expect(
      (t.saved, t.overspent, t.covered, t.pot, t.left),
      (p(211558), p(53778), p(20000), p(191558), p(690000)),
    );
    // The check line holds for the period that ended, not for this one.
    expect(
      p1.totals.budget - p1.totals.netSpent,
      p1.totals.saved - p1.totals.overspent - p1.totals.covered,
    );
    expect(p1.totals.budget - p1.totals.netSpent, p(96000));
    expect(
      p2.totals.budget - p2.totals.netSpent,
      isNot(p2.totals.saved - p2.totals.overspent - p2.totals.covered),
    );
  });

  test('TC-014-09 change lines for one and two periods', () {
    final two = _of(fixtureMFull).changes;
    expect(two, hasLength(2));
    final [first, second] = two;
    expect(first.kind, StatementChangeKind.started);
    expect(first.date, d(2026, 11, 1));
    expect(first.deltas, isEmpty);
    expect(first.replacedSameDay, isFalse);
    expect(first.showTime, isFalse);
    expect(first.dailyAfter, p(83000));
    expect(first.daysLeft, 30);
    expect((first.values as FullMonthValues).salary, p(4000000));
    expect(first.values.fixedCostsTotal, p(1510000));

    expect(second.kind, StatementChangeKind.later);
    expect(second.date, d(2026, 11, 13));
    expect(second.changedAt, at(d(2026, 11, 13), 9));
    final delta = second.deltas.single as ValueDelta;
    expect((delta.before, delta.after), (p(4000000), p(3500000)));
    expect(second.dailyAfter, p(55223));
    expect(second.daysLeft, 18);

    // A single period has only the first line.
    final one = _of(fixtureA);
    expect(one.changes, hasLength(1));
    expect(one.periods, hasLength(1));
    expect(one.changes.single.date, d(2026, 11, 5));
    expect(one.changes.single.dailyAfter, p(83000));
    expect(one.changes.single.daysLeft, 30);
    expect(one.periods.single.of, 1);
  });

  test('TC-014-10 same day records give two periods and two lines', () {
    final s = _of(e2s);

    expect(s.changes, hasLength(3));
    expect(s.periods, hasLength(2));
    final [_, early, late] = s.changes;
    expect(early.date, d(2026, 11, 20));
    expect(early.replacedSameDay, isTrue);
    expect(early.showTime, isTrue);
    expect(early.dailyAfter, isNull);
    final earlyDelta = early.deltas.single as ValueDelta;
    expect(
      (earlyDelta.field, earlyDelta.name, earlyDelta.before, earlyDelta.after),
      (PeriodField.fixedCost, 'Rent', p(1000000), p(1300000)),
    );
    expect(late.replacedSameDay, isFalse);
    expect(late.showTime, isTrue);
    expect(late.dailyAfter, p(76334));
    expect(late.daysLeft, 15);
    final lateDelta = late.deltas.single as ValueDelta;
    expect((lateDelta.before, lateDelta.after), (p(1300000), p(1100000)));
    expect(early.changedAt < late.changedAt, isTrue);
    // The 5 Nov record is alone that day: no time.
    expect(s.changes.first.showTime, isFalse);

    final [p1, p2] = s.periods;
    expect((p1.start, p1.end, p1.days), (d(2026, 11, 5), d(2026, 11, 19), 15));
    expect((p2.start, p2.end, p2.days), (d(2026, 11, 20), d(2026, 12, 4), 15));
    // The reason is the net change from the previous card.
    final reason = (p2.reasons.single as ChangedReason).delta as ValueDelta;
    expect(
      (reason.name, reason.before, reason.after),
      ('Rent', p(1000000), p(1100000)),
    );
    final working = _spread(p2);
    expect(working.spendable, p(2390000));
    expect(working.alreadyBudgeted, p(1245000));
    expect(working.amountToSpread, p(1145000));
    expect(working.spreadDays, 15);
    expect(working.daily, p(76334));
    expect(working.extraPaiseDays, 5);
    expect(fixedCostsOf(p2.values).map((c) => (c.name, c.amount)), [
      ('Rent', p(1100000)),
      ('EMI', p(500000)),
      ('Subscriptions', p(10000)),
    ]);
    expect(p2.values.fixedCostsTotal, p(1610000));
  });

  test('TC-014-11 three periods add up to the spendable', () {
    final s = _of(e2c);

    expect(s.periods, hasLength(3));
    expect(s.changes, hasLength(3));
    final [p1, p2, p3] = s.periods;
    expect([p1.of, p2.of, p3.of], [3, 3, 3]);
    expect([p1.index, p2.index, p3.index], [1, 2, 3]);
    expect([p1.days, p2.days, p3.days], [15, 8, 7]);

    final w2 = _spread(p2);
    expect(
      (w2.base, w2.fixed, w2.spendable, w2.alreadyBudgeted, w2.amountToSpread),
      (p(4000000), p(1810000), p(2190000), p(1245000), p(945000)),
    );
    expect((w2.spreadDays, w2.daily, w2.extraPaiseDays), (15, p(63000), 0));
    final w3 = _spread(p3);
    expect(
      (w3.base, w3.fixed, w3.spendable, w3.alreadyBudgeted, w3.amountToSpread),
      (p(4000000), p(1710000), p(2290000), p(1749000), p(541000)),
    );
    expect((w3.spreadDays, w3.daily, w3.extraPaiseDays), (7, p(77286), 5));

    final d2 = (p2.reasons.single as ChangedReason).delta as ValueDelta;
    expect((d2.name, d2.before, d2.after), ('Rent', p(1000000), p(1300000)));
    final d3 = (p3.reasons.single as ChangedReason).delta as ValueDelta;
    expect((d3.name, d3.before, d3.after), ('EMI', p(500000), p(400000)));

    expect(
      [for (final x in s.periods) fixedCostsOf(x.values).first.amount],
      [p(1000000), p(1300000), p(1300000)],
    );
    expect(fixedCostsOf(p3.values).map((c) => c.name), contains('EMI'));
    expect(s.totals.moneyForMonth, p(2290000));
    expect(p1.totals.budget + p2.totals.budget + p3.totals.budget, p(2290000));
    expect(p1.totals.budget, p(1245000));
    expect(p2.totals.budget, p(504000));
    expect(p3.totals.budget, p(541000));
    // Today is after the month: no card is in progress.
    expect(s.soFarTo, isNull);
    expect(s.periods.any((x) => x.inProgress), isFalse);
  });

  test('TC-014-47 reasons name every kind of change', () {
    ChangedReason only(MonthStatement s) =>
        s.periods.last.reasons.single as ChangedReason;
    final day20 = d(2026, 11, 20);

    final salary = _e2([_e2First(), period(day20, e2Values(salary: 3500000))]);
    final salaryDelta = only(salary).delta as ValueDelta;
    expect(salaryDelta.field, PeriodField.salary);

    // A target that is set, then changed.
    final target = _e2([
      _e2First(),
      period(day20, e2Values(target: 3000000), changedAt: at(day20, 9)),
      period(d(2026, 11, 25), e2Values(target: 3200000)),
    ]);
    final set =
        (target.periods[1].reasons.single as ChangedReason).delta as ValueDelta;
    expect(
      (set.field, set.before, set.after),
      (PeriodField.target, null, p(3000000)),
    );
    final changed = only(target).delta as ValueDelta;
    expect(
      (changed.field, changed.before, changed.after),
      (PeriodField.target, p(3000000), p(3200000)),
    );

    final rent = _e2([_e2First(), period(day20, e2Values(rent: 1300000))]);
    final rentDelta = only(rent).delta as ValueDelta;
    expect((rentDelta.field, rentDelta.name), (PeriodField.fixedCost, 'Rent'));

    final gym = _e2([
      _e2First(),
      period(
        day20,
        FullMonthValues(
          salary: p(4000000),
          fixedCosts: [
            ...e2Costs(),
            const FixedCost(name: 'Gym', amount: Paise(50000)),
          ],
        ),
      ),
    ]);
    final added = only(gym).delta as CostAdded;
    expect((added.name, added.amount), ('Gym', p(50000)));

    final emi = _e2([
      _e2First(),
      period(
        day20,
        FullMonthValues(
          salary: p(4000000),
          fixedCosts: [e2Costs()[0], e2Costs()[2]],
        ),
      ),
    ]);
    final removed = only(emi).delta as CostRemoved;
    expect((removed.name, removed.amount), ('EMI', p(500000)));

    final rename = _e2([
      _e2First(),
      period(
        day20,
        FullMonthValues(
          salary: p(4000000),
          fixedCosts: [
            const FixedCost(name: 'House rent', amount: Paise(1000000)),
            e2Costs()[1],
            e2Costs()[2],
          ],
        ),
      ),
    ]);
    final renamed = only(rename).delta as CostRenamed;
    expect((renamed.from, renamed.to), ('Rent', 'House rent'));

    // Two items swapped for different amounts stay a removal and an addition.
    final swap = _e2([
      _e2First(),
      period(
        day20,
        FullMonthValues(
          salary: p(4000000),
          fixedCosts: [
            e2Costs()[0],
            const FixedCost(name: 'Gym', amount: Paise(70000)),
            e2Costs()[2],
          ],
        ),
      ),
    ]);
    expect(swap.periods.last.reasons.map((r) => (r as ChangedReason).delta), [
      isA<CostAdded>(),
      isA<CostRemoved>(),
    ]);

    // Two changes in one save: both reasons, in screen order.
    final both = _e2([
      _e2First(),
      period(day20, e2Values(salary: 3500000, rent: 1300000)),
    ]);
    expect(
      both.periods.last.reasons.map(
        (r) => ((r as ChangedReason).delta as ValueDelta).field,
      ),
      [PeriodField.salary, PeriodField.fixedCost],
    );

    // Money left of a mid-month first month, then edited.
    final moneyLeft = buildStatement(
      computeMonth(
        MonthInput(
          month: nov2026,
          firstBudgetedDay: d(2026, 11, 10),
          periods: [
            period(
              d(2026, 11, 10),
              const MidMonthStartValues(moneyLeft: Paise(2490000)),
              changedAt: at(d(2026, 11, 9), 0),
            ),
            period(
              day20,
              const MidMonthStartValues(
                moneyLeft: Paise(2500000),
                fixedCostsStillToPay: [
                  FixedCost(name: 'Gym', amount: Paise.zero),
                ],
              ),
            ),
          ],
          today: d(2026, 12, 5),
        ),
      ),
    );
    expect(
      moneyLeft.periods.last.reasons.map((r) => (r as ChangedReason).delta),
      [
        isA<ValueDelta>().having(
          (x) => x.field,
          'field',
          PeriodField.moneyLeft,
        ),
        isA<CostAdded>(),
      ],
    );

    // The first card of a normal month and of a mid-month first month.
    expect(
      (salary.periods.first.reasons.single as StartedReason).partway,
      isFalse,
    );
    expect(
      (moneyLeft.periods.first.reasons.single as StartedReason).partway,
      isTrue,
    );
    expect(moneyLeft.changes.first.kind, StatementChangeKind.startedPartway);
    expect(moneyLeft.changes.last.kind, StatementChangeKind.later);
    expect(fixedCostsOf(moneyLeft.periods.last.values).single.name, 'Gym');
    expect(fixedCostsOf(moneyLeft.periods.first.values), isEmpty);
  });

  test('TC-014-57 a reverted same day change reads as changed and changed '
      'back', () {
    final day20 = d(2026, 11, 20);
    final s = _e2([
      _e2First(),
      period(day20, e2Values(rent: 1300000), changedAt: at(day20, 10)),
      period(day20, e2Values(), changedAt: at(day20, 18)),
    ]);

    expect(s.periods, hasLength(2));
    expect(s.periods.last.reasons.single, isA<ChangedBackReason>());
    final [_, early, late] = s.changes;
    expect(early.replacedSameDay, isTrue);
    expect(late.dailyAfter, p(83000));
    final back = late.deltas.single as ValueDelta;
    expect((back.before, back.after), (p(1300000), p(1000000)));
    expect(late.daysLeft, 15);
    final working = _spread(s.periods.last);
    expect(working.alreadyBudgeted, p(1245000));
    expect(working.daily, p(83000));
  });

  test('TC-014-31 a change on day one replaces the first period', () {
    final day1 = d(2026, 11, 1);
    final s = _november([
      period(day1, e2Values(), changedAt: at(day1, 9)),
      period(day1, e2Values(salary: 3500000), changedAt: at(day1, 15)),
    ], today: d(2026, 11, 2));

    expect(s.changes, hasLength(2));
    expect(s.periods, hasLength(1));
    final [replaced, current] = s.changes;
    expect(replaced.kind, StatementChangeKind.started);
    expect(replaced.replacedSameDay, isTrue);
    expect(replaced.dailyAfter, isNull);
    expect([replaced.showTime, current.showTime], [true, true]);
    expect(current.kind, StatementChangeKind.later);
    expect(current.dailyAfter, p(66334));
    expect(current.daysLeft, 30);

    final card = s.periods.single;
    expect((card.start, card.end, card.days), (day1, d(2026, 11, 30), 30));
    expect(card.inProgress, isTrue);
    expect(card.reasons.single, isA<StartedReason>());
    final working = _spread(card);
    expect(working.alreadyBudgeted, p(0));
    expect(working.amountToSpread, p(1990000));
    expect((working.daily, working.extraPaiseDays), (p(66334), 10));
  });

  test('TC-014-58 period with zero past days', () {
    final day13 = d(2026, 11, 13);
    final s = _e2([
      _e2First(),
      period(day13, e2Values(salary: 3500000), changedAt: at(day13, 10)),
    ], today: day13);

    final [p1, p2] = s.periods;
    expect(
      (p1.start, p1.end, p1.days, p1.inProgress),
      (d(2026, 11, 5), d(2026, 11, 12), 8, false),
    );
    expect(p1.totals.budget, p(664000));
    expect(
      (p2.index, p2.of, p2.start, p2.end, p2.days),
      (2, 2, day13, d(2026, 12, 4), 22),
    );
    expect(p2.inProgress, isTrue);
    // The period starts today: no past day, so nothing to be saved or over.
    expect(
      (
        p2.totals.budget,
        p2.totals.spent,
        p2.totals.saved,
        p2.totals.overspent,
        p2.totals.covered,
      ),
      (p(1326000), p(0), p(0), p(0), p(0)),
    );
    final working = _spread(p2);
    expect(
      (
        working.spendable,
        working.alreadyBudgeted,
        working.amountToSpread,
        working.spreadDays,
        working.daily,
        working.extraPaiseDays,
      ),
      // 13,26,000 / 22 = 60,272 r 16: the first 16 days get 60,273.
      (p(1990000), p(664000), p(1326000), 22, p(60273), 16),
    );
    expect(p2.reasons.single, isA<ChangedReason>());
    final change = s.changes.last;
    expect(
      (change.date, change.daysLeft, change.dailyAfter),
      (day13, 22, p(60273)),
    );
  });

  test('TC-014-59 working line without fixed costs', () {
    final s = _e2([
      period(
        d(2026, 11, 5),
        const FullMonthValues(salary: Paise(4000000)),
        changedAt: at(d(2026, 11, 4), 0),
      ),
    ], today: d(2026, 11, 9));
    final card = s.periods.single;
    expect(card.values.fixedCostsTotal, p(0));
    final working = _spread(card);
    expect(
      (
        working.base,
        working.fixed,
        working.spendable,
        working.amountToSpread,
        working.daily,
        working.extraPaiseDays,
      ),
      (p(4000000), p(0), p(4000000), p(4000000), p(133334), 10),
    );
    expect(s.totals.moneyForMonth, p(4000000));
  });

  test('TC-014-32 a one day period reads over 1 day', () {
    final s = _november([
      period(d(2026, 11, 1), e2Values(), changedAt: at(d(2026, 10, 31), 0)),
      period(d(2026, 11, 30), e2Values(salary: 5000000)),
    ], today: d(2026, 12, 1));

    final [p1, p2] = s.periods;
    expect((p1.days, p1.totals.budget), (29, p(2407000)));
    expect((p2.start, p2.end, p2.days), (d(2026, 11, 30), d(2026, 11, 30), 1));
    final working = _spread(p2);
    expect(
      (
        working.spendable,
        working.alreadyBudgeted,
        working.amountToSpread,
        working.spreadDays,
        working.daily,
        working.extraPaiseDays,
      ),
      (p(3490000), p(2407000), p(1083000), 1, p(1083000), 0),
    );
    expect(s.changes.last.daysLeft, 1);
  });

  test('TC-014-33 a renamed fixed cost starts a period with the same '
      'budget', () {
    final day20 = d(2026, 11, 20);
    final s = _e2([
      _e2First(),
      period(
        day20,
        FullMonthValues(
          salary: p(4000000),
          fixedCosts: [
            const FixedCost(name: 'House rent', amount: Paise(1000000)),
            e2Costs()[1],
            e2Costs()[2],
          ],
        ),
      ),
    ], today: d(2026, 11, 25));

    final rename = s.changes.last.deltas.single as CostRenamed;
    expect((rename.from, rename.to), ('Rent', 'House rent'));
    final working = _spread(s.periods.last);
    expect(
      (working.alreadyBudgeted, working.amountToSpread, working.daily),
      (p(1245000), p(1245000), p(83000)),
    );
    expect(working.spreadDays, 15);
    expect(fixedCostsOf(s.periods.last.values).first.name, 'House rent');
  });

  test('TC-014-13 shortfall statement shows the short line and totals', () {
    final s = _of(fixtureS);

    final working = s.periods.single.working as ShortfallWorking;
    expect(
      (
        working.base,
        working.fixed,
        working.spendable,
        working.alreadyBudgeted,
        working.amountToSpread,
        working.shortfall,
        working.underRupee,
        working.spreadDays,
      ),
      (
        p(2000000),
        p(2100000),
        p(-100000),
        p(0),
        p(-100000),
        p(100000),
        false,
        30,
      ),
    );
    final t = s.totals;
    expect(
      (t.moneyForMonth, t.spent, t.saved, t.overspent, t.pot, t.shortfall),
      (p(0), p(20000), p(0), p(20000), p(0), p(100000)),
    );
    expect(t.left, p(-120000));
    expect(s.changes.single.dailyAfter, p(0));
  });

  test('TC-014-14 a change that causes a shortfall is shown in its own '
      'period', () {
    final s = _of(c4);

    final first = _spread(s.periods.first);
    expect(first.daily, p(83000));
    final working = s.periods.last.working as ShortfallWorking;
    expect(
      (
        working.base,
        working.spendable,
        working.alreadyBudgeted,
        working.amountToSpread,
        working.shortfall,
      ),
      (p(2500000), p(990000), p(1245000), p(-255000), p(255000)),
    );
    final reason =
        (s.periods.last.reasons.single as ChangedReason).delta as ValueDelta;
    expect(reason.field, PeriodField.target);
    expect(s.totals.shortfall, p(255000));
  });

  test('TC-014-15 equal salary and fixed costs read as zero left', () {
    final s = buildStatement(
      e2Month(
        today: d(2026, 11, 8),
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
      ),
    );

    final working = s.periods.single.working;
    expect(working, isA<ZeroWorking>());
    expect((working.spendable, working.amountToSpread), (p(0), p(0)));
    expect(s.totals.shortfall, p(0));
  });

  test('TC-014-34 a change that removes a shortfall hides the short row', () {
    final s = _e2([
      period(
        d(2026, 11, 5),
        s1Values(),
        changedAt: at(d(2026, 11, 4), 0),
        continued: true,
      ),
      period(
        d(2026, 11, 20),
        const FullMonthValues(
          salary: Paise(3000000),
          fixedCosts: [
            FixedCost(name: 'Rent', amount: Paise(1500000)),
            FixedCost(name: 'EMI', amount: Paise(600000)),
          ],
        ),
      ),
    ], today: d(2026, 11, 25));

    expect(s.periods.first.working, isA<ShortfallWorking>());
    final working = _spread(s.periods.last);
    expect(
      (working.spendable, working.alreadyBudgeted, working.amountToSpread),
      (p(900000), p(0), p(900000)),
    );
    expect((working.spreadDays, working.daily), (15, p(60000)));
    expect(s.totals.shortfall, p(0));
  });

  test('TC-014-38 a shortfall under one rupee reads less than one rupee', () {
    final s = buildStatement(
      e2Month(
        today: d(2026, 11, 8),
        periods: [
          period(
            d(2026, 11, 5),
            const FullMonthValues(
              salary: Paise(1500000),
              fixedCosts: [FixedCost(name: 'Rent', amount: Paise(1500050))],
            ),
            continued: true,
          ),
        ],
      ),
    );

    final working = s.periods.single.working as ShortfallWorking;
    expect(working.shortfall, p(50));
    expect(working.underRupee, isTrue);
    expect(s.totals.shortfall, p(50));
  });

  test('TC-014-16 mid month first month statement', () {
    final s = _of(fixtureF);

    expect(s.notBudgeted, (start: d(2026, 11, 5), end: d(2026, 11, 9)));
    expect(s.soFarTo, d(2026, 11, 12));
    final card = s.periods.single;
    expect(
      (card.start, card.end, card.days),
      (d(2026, 11, 10), d(2026, 12, 4), 25),
    );
    expect((card.reasons.single as StartedReason).partway, isTrue);
    expect(card.values, isA<MidMonthStartValues>());
    final working = _spread(card);
    expect(
      (
        working.base,
        working.fixed,
        working.stillToPay,
        working.spendable,
        working.alreadyBudgeted,
        working.spreadDays,
        working.daily,
        working.extraPaiseDays,
      ),
      (p(2490000), p(0), true, p(2490000), p(0), 25, p(99600), 0),
    );
    expect(s.changes.single.kind, StatementChangeKind.startedPartway);
    expect(s.changes.single.daysLeft, 25);
    expect(s.changes.single.dailyAfter, p(99600));
  });

  test('TC-014-43 a late setup reads like a mid month start', () {
    final s = buildStatement(
      computeMonth(
        MonthInput(
          month: BudgetMonth.startIn(5, 2026, 12),
          firstBudgetedDay: d(2026, 12, 12),
          periods: [
            period(
              d(2026, 12, 12),
              const MidMonthStartValues(moneyLeft: Paise(2400000)),
              changedAt: at(d(2026, 12, 11), 0),
            ),
          ],
          today: d(2026, 12, 14),
        ),
      ),
    );

    expect(s.notBudgeted, (start: d(2026, 12, 5), end: d(2026, 12, 11)));
    final card = s.periods.single;
    expect(
      (card.start, card.end, card.days),
      (d(2026, 12, 12), d(2027, 1, 4), 24),
    );
    expect(_spread(card).daily, p(100000));
    expect(_spread(card).spreadDays, 24);
  });

  test('TC-014-35 eleven periods are all listed', () {
    final s = _e2([
      _e2First(),
      for (var i = 1; i <= 10; i++)
        period(
          d(2026, 11, 5 + i),
          e2Values(salary: 4000000 + i * 10000),
          changedAt: at(d(2026, 11, 5 + i), 9),
        ),
    ]);

    expect(s.periods, hasLength(11));
    expect(s.changes, hasLength(11));
    expect(
      [for (final x in s.periods) x.index],
      [for (var i = 1; i <= 11; i++) i],
    );
    expect(s.periods.every((x) => x.of == 11), isTrue);
    expect(
      Paise.sum(s.periods.map((x) => x.totals.budget)),
      s.totals.moneyForMonth,
    );
    expect(s.totals.moneyForMonth, p(2590000));
  });

  test('TC-014-56 working line with a target', () {
    final s = _e2([
      period(
        d(2026, 11, 5),
        e2Values(target: 2000000),
        changedAt: at(d(2026, 11, 4), 0),
      ),
    ], today: d(2026, 11, 9));

    final card = s.periods.single;
    final working = _spread(card);
    expect(
      (
        working.base,
        working.fixed,
        working.spendable,
        working.amountToSpread,
        working.daily,
        working.extraPaiseDays,
      ),
      (p(2000000), p(1510000), p(490000), p(490000), p(16334), 10),
    );
    expect((card.values as FullMonthValues).target, p(2000000));
    expect((card.values as FullMonthValues).salary, p(4000000));
  });

  test('TC-014-53 covered per period follows the covered day', () {
    final s = _of(fixtureMFull);

    // The cover of 6 Nov (made on 7 Nov) belongs to period 1.
    expect(s.periods.first.totals.covered, p(20000));
    expect(s.periods.last.totals.covered, p(0));
    expect(s.totals.covered, p(20000));
  });

  test('TC-014-01 statement finds the card that starts on a day', () {
    final s = _of(fixtureM20);

    expect(s.periodStartingOn(d(2026, 11, 13))?.index, 2);
    expect(s.periodStartingOn(d(2026, 11, 1))?.index, 1);
    expect(s.periodStartingOn(d(2026, 11, 14)), isNull);
  });

  test('TC-014-41 a first day without spends shows neutral zeros', () {
    final s = _of(e2Day1);

    final t = s.totals;
    expect(
      (t.moneyForMonth, t.spent, t.saved, t.covered, t.overspent, t.pot),
      (p(2490000), p(0), p(0), p(0), p(0), p(0)),
    );
    expect(t.left, p(2490000));
    expect(t.hasRefunds, isFalse);
    expect(s.soFarTo, d(2026, 11, 5));
    expect(s.periods.single.inProgress, isTrue);
  });
}
